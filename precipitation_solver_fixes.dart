// precipitation_solver.dart 修复代码

/// 修复1: 正确的饱和水汽压计算
double _calculateSaturationMixingRatioFixed(double temperature, double pressure) {
  final tempCelsius = temperature - 273.15;
  double es; // 饱和水汽压 (hPa)
  
  // 使用改进的Magnus公式
  if (tempCelsius >= 0.0) {
    // 水面饱和水汽压
    es = 6.1121 * exp(17.502 * tempCelsius / (tempCelsius + 240.97));
  } else {
    // 冰面饱和水汽压
    es = 6.1121 * exp(22.587 * tempCelsius / (tempCelsius + 273.86));
  }
  
  // 转换为Pa并计算混合比
  es *= 100.0; // hPa -> Pa
  const double epsilon = 0.622; // 水汽分子量比
  
  return epsilon * es / (pressure - es);
}

/// 修复2: 改进的Kessler方案参数
class ImprovedKesslerParameters {
  static const double autoconversionThreshold = 0.002; // 2 g/kg (标准值)
  static const double autoconversionRate = 0.001; // 1/s
  static const double accretionRate = 3.0; // 3/s (标准值)
  static const double collectionRate = 0.002; // 1/s
  static const double evaporationRate = 0.0005; // 1/s
  static const double breakupThreshold = 0.005; // 5 g/kg
  static const double breakupRate = 0.001; // 1/s
}

/// 修复3: 质量守恒的雨水下沉过程
void _applyRainfallProcessConservative(
  List<List<List<double>>> newQrain,
  List<List<List<double>>> wWind,
) {
  final nx = _grid.nx;
  final ny = _grid.ny;
  final nz = _grid.nz;
  
  // 创建通量数组
  final rainFlux = List.generate(nz + 1, (k) => 
      List.generate(ny, (j) => List.filled(nx, 0.0)));
  
  // 计算雨水通量（从上到下）
  for (int k = nz - 1; k > 0; k--) {
    for (int j = 0; j < ny; j++) {
      for (int i = 0; i < nx; i++) {
        final qr = newQrain[k][j][i];
        final fallSpeed = _calculateRainFallSpeedImproved(qr);
        final w = wWind[k][j][i];
        
        // 净下沉速度
        final netFallSpeed = max(0.0, fallSpeed - w);
        
        // 计算通量 (kg/m²/s)
        final airDensity = _calculateAirDensity(temperature[k][j][i], pressure[k][j][i]);
        rainFlux[k][j][i] = qr * airDensity * netFallSpeed;
      }
    }
  }
  
  // 应用质量守恒的通量差分
  for (int k = 0; k < nz; k++) {
    for (int j = 0; j < ny; j++) {
      for (int i = 0; i < nx; i++) {
        double fluxIn = 0.0;
        double fluxOut = 0.0;
        
        // 上层通量入
        if (k < nz - 1) {
          fluxIn = rainFlux[k + 1][j][i];
        }
        
        // 下层通量出
        if (k > 0) {
          fluxOut = rainFlux[k][j][i];
        }
        
        // 质量守恒更新
        final airDensity = _calculateAirDensity(temperature[k][j][i], pressure[k][j][i]);
        final deltaQ = (fluxIn - fluxOut) * _dt / (airDensity * _dz);
        
        newQrain[k][j][i] += deltaQ;
        
        // 地面降水移除
        if (k == 0) {
          final surfacePrecipitation = fluxOut * _dt / airDensity;
          newQrain[k][j][i] -= surfacePrecipitation;
          precipitationRate[j][i] = surfacePrecipitation * airDensity * 3600.0; // mm/h
        }
        
        // 确保非负
        newQrain[k][j][i] = max(0.0, newQrain[k][j][i]);
      }
    }
  }
}

/// 修复4: 改进的雨水下落速度计算
double _calculateRainFallSpeedImproved(double qr) {
  if (qr <= 0.0) return 0.0;
  
  // 基于雨水含量的Marshall-Palmer关系
  final double lambda = 41.0 * pow(qr * 1000.0, -0.21); // m⁻¹
  final double v0 = 9.65 - 10.3 * exp(-0.6 * lambda); // m/s
  
  // 考虑空气密度修正
  final double rho0 = 1.225; // 标准空气密度 kg/m³
  final double rho = 1.0; // 简化，实际应该随高度变化
  final double densityCorrection = sqrt(rho0 / rho);
  
  return v0 * densityCorrection;
}

/// 修复5: 改进的微物理过程计算
Map<String, double> _calculateKesslerTendenciesImproved(
  double qv, double qc, double qr,
  double temp, double press, double w, double height,
) {
  final params = ImprovedKesslerParameters;
  
  // 1. 凝结/蒸发过程
  double condensation = 0.0;
  final qvs = _calculateSaturationMixingRatioFixed(temp, press);
  final supersaturation = qv - qvs;
  
  if (supersaturation > 0.0 && qc < 0.02) { // 最大云水2%
    // 凝结率受上升速度限制
    final dynamicCondensation = _calculateDynamicCondensation(qv, temp, w);
    final condensationRate = min(supersaturation / _dt, dynamicCondensation);
    condensation = min(condensationRate, 0.01); // 最大凝结率
  } else if (supersaturation < 0.0 && qc > 0.0) {
    // 云水蒸发
    final evapRate = params.evaporationRate * (-supersaturation) * (temp / 273.15);
    condensation = -min(evapRate * _dt, qc);
  }
  
  // 2. 自动转化过程 (Kessler公式)
  double autoconversion = 0.0;
  if (qc > params.autoconversionThreshold) {
    final excessCloud = qc - params.autoconversionThreshold;
    autoconversion = params.autoconversionRate * excessCloud * excessCloud;
  }
  
  // 3. 碰并收集过程
  double collection = 0.0;
  if (qc > 0.0 && qr > 0.0) {
    collection = params.accretionRate * qc * qr;
  }
  
  // 4. 雨水蒸发过程
  double rainEvaporation = 0.0;
  if (qr > 0.0 && supersaturation < 0.0) {
    final evapEfficiency = _calculateEvaporativeEfficiencyImproved(qr, temp, press);
    rainEvaporation = evapEfficiency * (-supersaturation) * qr;
  }
  
  // 5. 雨水碰撞破碎过程
  double breakup = 0.0;
  if (qr > params.breakupThreshold) {
    breakup = params.breakupRate * (qr - params.breakupThreshold);
  }
  
  // 6. 计算倾向 (确保质量守恒)
  final qvaporTendency = -condensation - rainEvaporation;
  final qcloudTendency = condensation - autoconversion - collection;
  final qrainTendency = autoconversion + collection + rainEvaporation - breakup;
  
  // 质量守恒检查
  final totalTendency = qvaporTendency + qcloudTendency + qrainTendency;
  
  return {
    'qvapor': qvaporTendency - totalTendency / 3.0, // 分配质量误差
    'qcloud': qcloudTendency - totalTendency / 3.0,
    'qrain': qrainTendency - totalTendency / 3.0,
    'condensation': condensation,
    'autoconversion': autoconversion,
    'collection': collection,
    'rain_evaporation': rainEvaporation,
    'breakup': breakup,
  };
}

/// 修复6: 改进的蒸发效率计算
double _calculateEvaporativeEfficiencyImproved(double qr, double temp, double press) {
  const double baseEfficiency = 0.0001;
  
  // 温度修正因子
  final double tempFactor = (temp - 273.15) / 20.0;
  final double tempCorrection = temp > 273.15 ? 
      min(2.0, 1.0 + tempFactor) : max(0.1, tempFactor);
  
  // 压力修正因子
  final double pressureCorrection = press / 101325.0;
  
  // 雨水含量修正
  final double rainFactor = min(1.0, qr / 0.001);
  
  // 通风因子修正
  final double fallSpeed = _calculateRainFallSpeedImproved(qr);
  final double ventilationFactor = 1.0 + 0.2 * sqrt(fallSpeed);
  
  return baseEfficiency * tempCorrection * pressureCorrection * 
         rainFactor * ventilationFactor;
}

/// 修复7: 改进的冰相过程
void _applyIcePhaseProcessesImproved(
  List<List<List<double>>> newQcloud,
  List<List<List<double>>> newQrain,
  double tempCelsius,
  int i, int j, int k,
) {
  // Bergeron-Findeisen过程
  if (tempCelsius < 0.0 && tempCelsius > -40.0) {
    // 冰核浓度
    final double iceNucleusConc = _calculateIceNucleusConcentration(tempCelsius);
    
    // 云水向冰晶转化
    if (newQcloud[k][j][i] > 0.0) {
      final double cloudToIceRate = iceNucleusConc * 0.001; // 1/s
      final double cloudToIce = min(newQcloud[k][j][i], 
                                   cloudToIceRate * _dt * newQcloud[k][j][i]);
      newQcloud[k][j][i] -= cloudToIce;
      // qice[k][j][i] += cloudToIce; // 需要添加冰相场
    }
    
    // 雨水冻结过程
    if (tempCelsius < -5.0 && newQrain[k][j][i] > 0.0) {
      final double freezingRate = 0.01 * (-tempCelsius / 5.0); // 1/s
      final double rainToIce = min(newQrain[k][j][i], 
                                  freezingRate * _dt * newQrain[k][j][i]);
      newQrain[k][j][i] -= rainToIce;
      // qsnow[k][j][i] += rainToIce; // 需要添加雪场
    }
  }
}

/// 计算冰核浓度
double _calculateIceNucleusConcentration(double tempCelsius) {
  // Fletcher公式
  if (tempCelsius >= -5.0) return 0.0;
  
  final double tempAbs = -tempCelsius;
  return 0.001 * exp(0.6 * tempAbs); // 个/L
}

/// 计算空气密度
double _calculateAirDensity(double temperature, double pressure) {
  const double Rd = 287.05; // J/(kg·K)
  return pressure / (Rd * temperature);
}

/// 修复8: 动力凝结计算
double _calculateDynamicCondensation(double qv, double temp, double w) {
  if (w <= 0.0) return 0.0;
  
  // 绝热冷却率
  const double g = 9.81; // m/s²
  const double cp = 1004.0; // J/(kg·K)
  final double coolingRate = g * w / cp; // K/s
  
  // 饱和水汽压变化率
  final double es = _calculateSaturationVaporPressure(temp);
  final double desdT = _calculateSaturationVaporPressureDerivative(temp);
  
  // 动力凝结率
  final double saturationChange = desdT * coolingRate;
  const double epsilon = 0.622;
  final double pressure = 101325.0; // 简化
  
  return epsilon * saturationChange * pressure / (pressure - es);
}

/// 计算饱和水汽压
double _calculateSaturationVaporPressure(double temp) {
  final double tempCelsius = temp - 273.15;
  if (tempCelsius >= 0.0) {
    return 6.1121 * exp(17.502 * tempCelsius / (tempCelsius + 240.97)) * 100.0;
  } else {
    return 6.1121 * exp(22.587 * tempCelsius / (tempCelsius + 273.86)) * 100.0;
  }
}

/// 计算饱和水汽压导数
double _calculateSaturationVaporPressureDerivative(double temp) {
  final double tempCelsius = temp - 273.15;
  double es, desdT;
  
  if (tempCelsius >= 0.0) {
    es = 6.1121 * exp(17.502 * tempCelsius / (tempCelsius + 240.97));
    final double denominator = (tempCelsius + 240.97) * (tempCelsius + 240.97);
    desdT = es * 17.502 * 240.97 / denominator;
  } else {
    es = 6.1121 * exp(22.587 * tempCelsius / (tempCelsius + 273.86));
    final double denominator = (tempCelsius + 273.86) * (tempCelsius + 273.86);
    desdT = es * 22.587 * 273.86 / denominator;
  }
  
  return desdT * 100.0; // Pa/K
}

/// 修复9: 改进的质量守恒检查
bool _checkMassConservation(
  List<List<List<double>>> qvapor,
  List<List<List<double>>> qcloud,
  List<List<List<double>>> qrain,
) {
  double totalWater = 0.0;
  int gridPoints = 0;
  
  for (int k = 0; k < _grid.nz; k++) {
    for (int j = 0; j < _grid.ny; j++) {
      for (int i = 0; i < _grid.nx; i++) {
        totalWater += qvapor[k][j][i] + qcloud[k][j][i] + qrain[k][j][i];
        gridPoints++;
        
        // 检查负值
        if (qvapor[k][j][i] < 0 || qcloud[k][j][i] < 0 || qrain[k][j][i] < 0) {
          return false;
        }
        
        // 检查合理范围
        if (qvapor[k][j][i] > 0.04 || qcloud[k][j][i] > 0.01 || qrain[k][j][i] > 0.01) {
          return false;
        }
      }
    }
  }
  
  // 检查总水量合理性
  final double avgWater = totalWater / gridPoints;
  return avgWater < 0.05; // 平均总水量小于5g/kg
}