import 'dart:math';
import '../core/app_config.dart';
import '../models/meteorology_state.dart';
import '../utils/math_utils.dart';

/// 降水形成求解器
/// 基于 Kessler 微物理方案实现水汽→云水→雨水的转化过程
class PrecipitationSolver {
  final MeteorologyGrid _grid;
  final double _dt;
  
  // Kessler方案参数
  final double _autoconversionThreshold; // 自动转化阈值
  final double _accretionRate;           // 碰并率
  final double _collectionRate;          // 收集率
  final double _evaporationRate;         // 蒸发率
  
  PrecipitationSolver(this._grid)
      : _dt = AppConfig.timeStep,
        _autoconversionThreshold = 0.001,  // 1 g/kg
        _accretionRate = 0.001,
        _collectionRate = 0.0001,
        _evaporationRate = 0.0001;
  
  /// 求解降水过程 - 完整的 Kessler 微物理方案
  /// [qvapor] - 水汽混合比 (kg/kg)
  /// [qcloud] - 云水混合比 (kg/kg)
  /// [qrain]  - 雨水混合比 (kg/kg)
  /// [temperature] - 温度场 (K)
  /// [pressure] - 气压场 (Pa)
  /// [wWind] - 垂直速度 (m/s)
  void solvePrecipitation(
    List<List<List<double>>> qvapor,
    List<List<List<double>>> qcloud,
    List<List<List<double>>> qrain,
    List<List<List<double>>> temperature,
    List<List<List<double>>> pressure,
    List<List<List<double>>> wWind,
  ) {
    final nx = _grid.nx;
    final ny = _grid.ny;
    final nz = _grid.nz;
    
    // 创建临时数组
    final newQvapor = List.generate(nz, (k) => 
        List.generate(ny, (j) => List.filled(nx, 0.0)));
    final newQcloud = List.generate(nz, (k) => 
        List.generate(ny, (j) => List.filled(nx, 0.0)));
    final newQrain = List.generate(nz, (k) => 
        List.generate(ny, (j) => List.filled(nx, 0.0)));
    
    // 降水率数组
    final precipitationRate = List.generate(ny, (j) => List.filled(nx, 0.0));
    
    // 质量守恒检查
    double totalWaterBefore = 0.0;
    double totalWaterAfter = 0.0;
    
    // 计算初始总水量
    for (int k = 0; k < nz; k++) {
      for (int j = 0; j < ny; j++) {
        for (int i = 0; i < nx; i++) {
          totalWaterBefore += qvapor[k][j][i] + qcloud[k][j][i] + qrain[k][j][i];
        }
      }
    }
    
    // 微物理过程计算
    for (int k = 0; k < nz; k++) {
      for (int j = 0; j < ny; j++) {
        for (int i = 0; i < nx; i++) {
          // 1. 基本变量
          final temp = temperature[k][j][i];
          final press = pressure[k][j][i];
          final w = wWind[k][j][i];
          final height = k * _dz;
          
          final qv = qvapor[k][j][i];
          final qc = qcloud[k][j][i];
          final qr = qrain[k][j][i];
          
          // 2. 热力学变量
          final qvs = _calculateSaturationMixingRatio(temp, press);
          final relativeHumidity = qvs > 0 ? qv / qvs : 0.0;
          final tempCelsius = temp - 273.15;
          
          // 3. 微物理过程倾向
          final tendencies = _calculateKesslerTendencies(
            qv, qc, qr, temp, press, w, height,
          );
          
          // 4. 时间步进更新（半隐式格式）
          const implicitFactor = 0.5;
          
          newQvapor[k][j][i] = qv + _dt * (
            (1 - implicitFactor) * tendencies['qvapor'] + 
            implicitFactor * _calculateUpdatedVaporTendency(
              newQvapor, newQcloud, newQrain, i, j, k, temp, press
            )
          );
          
          newQcloud[k][j][i] = qc + _dt * (
            (1 - implicitFactor) * tendencies['qcloud'] + 
            implicitFactor * _calculateUpdatedCloudTendency(
              newQvapor, newQcloud, newQrain, i, j, k, temp, press
            )
          );
          
          newQrain[k][j][i] = qr + _dt * (
            (1 - implicitFactor) * tendencies['qrain'] + 
            implicitFactor * _calculateUpdatedRainTendency(
              newQvapor, newQcloud, newQrain, i, j, k, temp, press
            )
          );
          
          // 5. 物理约束
          newQvapor[k][j][i] = max(0.0, newQvapor[k][j][i]);
          newQcloud[k][j][i] = max(0.0, newQcloud[k][j][i]);
          newQrain[k][j][i] = max(0.0, newQrain[k][j][i]);
          
          // 6. 冰相过程（温度低于0°C）
          if (tempCelsius < 0.0) {
            _applyIcePhaseProcesses(newQcloud, newQrain, tempCelsius, i, j, k);
          }
          
          // 7. 计算地面降水率
          if (k == 0) {
            final fallSpeed = _calculateRainFallSpeed(newQrain[k][j][i]);
            final surfacePrecipitation = newQrain[k][j][i] * fallSpeed;
            precipitationRate[j][i] = surfacePrecipitation * 3600; // 转换为 mm/h
          }
        }
      }
    }
    
    // 雨水下沉过程
    _applyRainfallProcess(newQrain, wWind);
    
    // 质量守恒检查
    for (int k = 0; k < nz; k++) {
      for (int j = 0; j < ny; j++) {
        for (int i = 0; i < nx; i++) {
          totalWaterAfter += newQvapor[k][j][i] + newQcloud[k][j][i] + newQrain[k][j][i];
        }
      }
    }
    
    // 质量守恒修正
    final massError = (totalWaterAfter - totalWaterBefore) / totalWaterBefore;
    if (massError.abs() > 0.001) {
      _applyMassConservationCorrection(newQvapor, newQcloud, newQrain, massError);
    }
    
    // 更新网格数据
    _copyGridData(newQvapor, qvapor);
    _copyGridData(newQcloud, qcloud);
    _copyGridData(newQrain, qrain);
    
    // 更新降水率到网格
    _updatePrecipitationRate(precipitationRate);
  }
  
  /// 计算 Kessler 微物理过程倾向
  Map<String, double> _calculateKesslerTendencies(
    double qv, double qc, double qr,
    double temp, double press, double w, double height,
  ) {
    const autoconversionThreshold = 0.0005; // 0.5 g/kg
    const accretionRate = 0.002; // s⁻¹
    const evaporationRate = 0.0001; // s⁻¹
    const collectionRate = 0.001; // s⁻¹
    
    // 1. 凝结/蒸发过程
    double condensation = 0.0;
    final qvs = _calculateSaturationMixingRatio(temp, press);
    final supersaturation = qv - qvs;
    
    if (supersaturation > 0 && qc < 0.01) {
      // 凝结：水汽→云水
      condensation = min(supersaturation / _dt, 0.01);
    } else if (supersaturation < 0 && qc > 0) {
      // 云水蒸发
      condensation = max(supersaturation / _dt, -qc);
    }
    
    // 2. 自动转化：云水→雨水
    double autoconversion = 0.0;
    if (qc > autoconversionThreshold) {
      autoconversion = accretionRate * (qc - autoconversionThreshold) * (qc / autoconversionThreshold);
    }
    
    // 3. 碰并收集：云水+雨水→雨水
    double collection = 0.0;
    if (qc > 0 && qr > 0) {
      collection = collectionRate * qc * qr;
    }
    
    // 4. 雨水蒸发
    double rainEvaporation = 0.0;
    if (qr > 0 && supersaturation < 0) {
      final evaporativeEfficiency = _calculateEvaporativeEfficiency(qr, temp, press);
      rainEvaporation = evaporativeEfficiency * (-supersaturation) * qr;
    }
    
    // 5. 雨水碰撞破碎
    double breakup = 0.0;
    if (qr > 0.002) { // 2 g/kg
      breakup = 0.0001 * (qr - 0.002);
    }
    
    // 6. 计算倾向
    final qvaporTendency = -condensation - rainEvaporation;
    final qcloudTendency = condensation - autoconversion - collection;
    final qrainTendency = autoconversion + collection + rainEvaporation - breakup;
    
    return {
      'qvapor': qvaporTendency,
      'qcloud': qcloudTendency,
      'qrain': qrainTendency,
      'condensation': condensation,
      'autoconversion': autoconversion,
      'collection': collection,
      'rain_evaporation': rainEvaporation,
      'breakup': breakup,
    };
  }
  
  /// 计算蒸发效率
  double _calculateEvaporativeEfficiency(double qr, double temp, double press) {
    // 基于雨水含量和环境的蒸发效率
    const baseEfficiency = 0.0001;
    
    // 温度修正
    final tempFactor = temp > 273.15 ? 1.0 : 0.3;
    
    // 压力修正
    final pressureFactor = press / 101325.0;
    
    // 雨水含量修正
    final rainFactor = min(1.0, qr / 0.001);
    
    return baseEfficiency * tempFactor * pressureFactor * rainFactor;
  }
  
  /// 应用冰相过程
  void _applyIcePhaseProcesses(
    List<List<List<double>>> newQcloud,
    List<List<List<double>>> newQrain,
    double tempCelsius,
    int i, int j, int k,
  ) {
    const freezingThreshold = -5.0; // °C
    
    if (tempCelsius < freezingThreshold) {
      // 云水转化为冰晶
      final cloudToIce = newQcloud[k][j][i] * 0.1;
      newQcloud[k][j][i] -= cloudToIce;
      
      // 雨水转化为雪/冰雹
      if (tempCelsius < -10.0) {
        final rainToIce = newQrain[k][j][i] * 0.05;
        newQrain[k][j][i] -= rainToIce;
      }
    }
  }
  
  /// 雨水下沉过程
  void _applyRainfallProcess(
    List<List<List<double>>> newQrain,
    List<List<List<double>>> wWind,
  ) {
    final nx = _grid.nx;
    final ny = _grid.ny;
    final nz = _grid.nz;
    
    // 从上到下计算雨水下沉
    for (int k = nz - 2; k >= 0; k--) {
      for (int j = 0; j < ny; j++) {
        for (int i = 0; i < nx; i++) {
          final qr = newQrain[k][j][i];
          final fallSpeed = _calculateRainFallSpeed(qr);
          final w = wWind[k][j][i];
          
          // 净下沉速度
          final netFallSpeed = max(0.0, fallSpeed - w);
          
          if (netFallSpeed > 0 && k < nz - 1) {
            // 计算下沉通量
            final fallDistance = netFallSpeed * _dt;
            final fallLevels = (fallDistance / _dz).floor();
            
            if (fallLevels > 0) {
              // 雨水从上层下沉
              double sourceRain = 0.0;
              for (int level = 1; level <= fallLevels && k + level < nz; level++) {
                sourceRain += newQrain[k + level][j][i] / fallLevels;
              }
              
              // 更新当前层
              newQrain[k][j][i] = 0.7 * newQrain[k][j][i] + 0.3 * sourceRain;
            }
          }
          
          // 地面雨水移除
          if (k == 0) {
            newQrain[k][j][i] *= 0.1; // 90% 到达地面
          }
        }
      }
    }
  }
  
  /// 质量守恒修正
  void _applyMassConservationCorrection(
    List<List<List<double>>> newQvapor,
    List<List<List<double>>> newQcloud,
    List<List<List<double>>> newQrain,
    double massError,
  ) {
    final correctionFactor = 1.0 - massError;
    
    for (int k = 0; k < _grid.nz; k++) {
      for (int j = 0; j < _grid.ny; j++) {
        for (int i = 0; i < _grid.nx; i++) {
          newQvapor[k][j][i] *= correctionFactor;
          newQcloud[k][j][i] *= correctionFactor;
          newQrain[k][j][i] *= correctionFactor;
        }
      }
    }
  }
  
  /// 更新后的水汽倾向（半隐式）
  double _calculateUpdatedVaporTendency(
    List<List<List<double>>> newQvapor,
    List<List<List<double>>> newQcloud,
    List<List<List<double>>> newQrain,
    int i, int j, int k,
    double temp, double press,
  ) {
    final qv = newQvapor[k][j][i];
    final qc = newQcloud[k][j][i];
    final qr = newQrain[k][j][i];
    
    final qvs = _calculateSaturationMixingRatio(temp, press);
    final supersaturation = qv - qvs;
    
    // 凝结/蒸发
    if (supersaturation > 0 && qc < 0.01) {
      return min(supersaturation / _dt, 0.01);
    } else if (supersaturation < 0 && qc > 0) {
      return max(supersaturation / _dt, -qc);
    }
    
    return 0.0;
  }
  
  /// 更新后的云水倾向（半隐式）
  double _calculateUpdatedCloudTendency(
    List<List<List<double>>> newQvapor,
    List<List<List<double>>> newQcloud,
    List<List<List<double>>> newQrain,
    int i, int j, int k,
    double temp, double press,
  ) {
    final qc = newQcloud[k][j][i];
    final qr = newQrain[k][j][i];
    
    // 自动转化
    const autoconversionThreshold = 0.0005;
    const accretionRate = 0.002;
    
    double autoconversion = 0.0;
    if (qc > autoconversionThreshold) {
      autoconversion = accretionRate * (qc - autoconversionThreshold);
    }
    
    // 碰并收集
    const collectionRate = 0.001;
    double collection = 0.0;
    if (qc > 0 && qr > 0) {
      collection = collectionRate * qc * qr;
    }
    
    return -autoconversion - collection;
  }
  
  /// 更新后的雨水倾向（半隐式）
  double _calculateUpdatedRainTendency(
    List<List<List<double>>> newQvapor,
    List<List<List<double>>> newQcloud,
    List<List<List<double>>> newQrain,
    int i, int j, int k,
    double temp, double press,
  ) {
    final qc = newQcloud[k][j][i];
    final qr = newQrain[k][j][i];
    
    // 自动转化和碰并
    const autoconversionThreshold = 0.0005;
    const accretionRate = 0.002;
    const collectionRate = 0.001;
    
    double autoconversion = 0.0;
    if (qc > autoconversionThreshold) {
      autoconversion = accretionRate * (qc - autoconversionThreshold);
    }
    
    double collection = 0.0;
    if (qc > 0 && qr > 0) {
      collection = collectionRate * qc * qr;
    }
    
    return autoconversion + collection;
  }
  
  /// 计算微物理过程 - 完整的 Kessler 方案实现
  Map<String, double> _calculateMicrophysicsProcesses(
    double qv, double qc, double qr, double temp, double w, double supersaturation,
  ) {
    // Kessler 微物理参数
    const k1 = 0.001;      // 自动转化系数 1/s
    const k2 = 2.2;        // 碰并系数 m²/g
    const k3 = 0.0001;     // 雨水蒸发系数 1/s
    const qcThreshold = 0.0005; // 云水阈值 g/kg
    const qrThreshold = 0.0001; // 雨水阈值 g/kg
    
    // 1. 凝结/蒸发过程
    final condensation = _calculateCondensationEvaporation(qv, qc, temp, supersaturation);
    
    // 2. 自动转化过程：云水→雨水
    final autoconversion = _calculateAutoconversion(qc, qcThreshold, k1);
    
    // 3. 碰并过程：云水+雨水→雨水
    final accretion = _calculateAccretion(qc, qr, k2);
    
    // 4. 雨水蒸发过程
    final rainEvaporation = _calculateRainEvaporation(qr, temp, supersaturation, k3);
    
    // 5. 上升运动引起的动力凝结
    final dynamicCondensation = _calculateDynamicCondensation(qv, temp, w);
    
    // 6. 冰相过程（温度低于0°C时的简化处理）
    final iceProcesses = _calculateIceProcesses(qc, qr, temp);
    
    // 7. 计算各变量的倾向
    final qvaporTendency = -condensation - rainEvaporation + dynamicCondensation - iceProcesses['sublimation']!;
    final qcloudTendency = condensation - autoconversion - accretion - iceProcesses['deposition']!;
    final qrainTendency = autoconversion + accretion + rainEvaporation + iceProcesses['melting']!;
    
    // 8. 质量守恒检查
    final totalChange = qvaporTendency + qcloudTendency + qrainTendency;
    if (totalChange.abs() > 1e-10) {
      // 归一化保证质量守恒
      final normalization = 1.0 - totalChange / (qv + qc + qr + 1e-10);
      qvaporTendency *= normalization;
      qcloudTendency *= normalization;
      qrainTendency *= normalization;
    }
    
    return {
      'qvapor_tendency': qvaporTendency,
      'qcloud_tendency': qcloudTendency,
      'qrain_tendency': qrainTendency,
      'condensation': condensation,
      'autoconversion': autoconversion,
      'accretion': accretion,
      'rain_evaporation': rainEvaporation,
      'dynamic_condensation': dynamicCondensation,
      'ice_processes': iceProcesses,
    };
  }
  
  /// 计算凝结/蒸发过程
  double _calculateCondensationEvaporation(
    double qv, double qc, double temp, double supersaturation,
  ) {
    const condensationRate = 0.01; // 1/s
    const evaporationRate = 0.005;  // 1/s
    
    if (supersaturation > 0) {
      // 过饱和：凝结
      final maxCondensation = min(supersaturation / _dt, qv * 0.1);
      return min(maxCondensation, condensationRate * supersaturation);
    } else if (supersaturation < 0 && qc > 0) {
      // 次饱和：蒸发
      final maxEvaporation = min(-supersaturation / _dt, qc);
      final evapRate = evaporationRate * (-supersaturation);
      
      // 考虑温度对蒸发的影响
      final tempFactor = temp > 273.15 ? 1.0 : 0.3;
      return min(maxEvaporation, evapRate * tempFactor);
    }
    
    return 0.0;
  }
  
  /// 计算自动转化过程
  double _calculateAutoconversion(double qc, double threshold, double k1) {
    if (qc > threshold) {
      // Kessler 自动转化公式
      final excessCloud = qc - threshold;
      return k1 * excessCloud * excessCloud; // 二次关系
    }
    return 0.0;
  }
  
  /// 计算碰并过程
  double _calculateAccretion(double qc, double qr, double k2) {
    if (qc > qrThreshold && qr > 0) {
      // 线性碰并率
      return k2 * qc * qr;
    }
    return 0.0;
  }
  
  /// 计算雨水蒸发
  double _calculateRainEvaporation(
    double qr, double temp, double supersaturation, double k3,
  ) {
    if (qr > 0 && supersaturation < 0) {
      // 雨水蒸发率依赖于相对湿度和温度
      final humidityDeficit = -supersaturation;
      final tempFactor = (temp - 273.15) / 20.0; // 温度因子
      
      // 考虑雨水下落速度的影响
      final fallSpeed = _calculateRainFallSpeed(qr);
      final ventilationFactor = 1.0 + 0.1 * fallSpeed; // 通风因子
      
      return k3 * humidityDeficit * qr * tempFactor * ventilationFactor;
    }
    return 0.0;
  }
  
  /// 计算动力凝结
  double _calculateDynamicCondensation(double qv, double temp, double w) {
    if (w > 0) {
      // 绝热冷却率
      const g = 9.81; // m/s²
      const cp = 1004.0; // J/(kg·K)
      final coolingRate = g * w / cp; // K/s
      
      // 饱和水汽压变化
      final saturationChange = _calculateSaturationChange(temp, coolingRate);
      
      // 动力凝结率
      return saturationChange * qv / temp;
    }
    return 0.0;
  }
  
  /// 计算饱和水汽压变化
  double _calculateSaturationChange(double temp, double coolingRate) {
    // Clausius-Clapeyron 方程
    const L = 2.5e6; // J/kg
    const Rv = 461.5; // J/(kg·K)
    
    return (L / (Rv * temp * temp)) * coolingRate;
  }
  
  /// 计算冰相过程（简化）
  Map<String, double> _calculateIceProcesses(double qc, double qr, double temp) {
    final processes = <String, double>{
      'sublimation': 0.0,
      'deposition': 0.0,
      'melting': 0.0,
    };
    
    if (temp < 273.15) {
      // 冰相过程
      const iceFraction = 0.3; // 冰相比例
      
      // 凝华/升华
      if (qc > 0) {
        processes['deposition'] = qc * iceFraction * 0.001; // 简化率
      }
      
      // 雨水冻结
      if (qr > 0) {
        processes['melting'] = -qr * iceFraction * 0.002; // 负值表示冻结
      }
    } else {
      // 融化过程
      if (qr > 0) {
        const meltingRate = 0.001; // 1/s
        processes['melting'] = qr * meltingRate * 0.1; // 部分融化
      }
    }
    
    return processes;
  }
  
  /// 改进的雨水下落速度计算
  double _calculateRainFallSpeed(double qr) {
    if (qr <= 0) return 0.0;
    
    // 基于雨水含量的经验关系
    const v0 = 4.0;  // 基础速度 m/s
    const a = 2000.0; // 系数
    
    final fallSpeed = v0 + a * qr;
    
    // 考虑高度影响（简化）
    const maxFallSpeed = 10.0; // m/s
    return min(fallSpeed, maxFallSpeed);
  }
  
  /// 计算饱和水汽混合比
  double _calculateSaturationMixingRatio(double temperature, double pressure) {
    final tempCelsius = temperature - 273.15;
    double es;
    
    if (tempCelsius >= 0) {
      es = 6.1078 * exp(17.27 * tempCelsius / (tempCelsius + 237.3));
    } else {
      es = 6.1078 * exp(21.875 * tempCelsius / (tempCelsius + 265.5));
    }
    
    return 0.622 * es * 100 / (pressure - es * 100);
  }
  
  /// 计算雨水下落速度
  double _calculateRainFallSpeed(double qr) {
    // 简化的雨滴下落速度公式
    if (qr <= 0) return 0.0;
    
    // 基于雨水含量的平均下落速度
    return min(9.0, 4.0 + 2000.0 * qr); // m/s
  }
  
  /// 应用雨水下沉过程
  void _applyRainfall(
    List<List<List<double>>> qrain,
    List<List<List<double>>> wWind,
  ) {
    final nx = _grid.nx;
    final ny = _grid.ny;
    final nz = _grid.nz;
    
    // 创建临时数组
    final newQrain = List.generate(nz, (k) => 
        List.generate(ny, (j) => List.filled(nx, 0.0)));
    
    // 从上到下计算雨水下沉
    for (int k = nz - 1; k >= 0; k--) {
      for (int j = 0; j < ny; j++) {
        for (int i = 0; i < nx; i++) {
          final qr = qrain[k][j][i];
          final fallSpeed = _calculateRainFallSpeed(qr);
          final w = wWind[k][j][i];
          
          // 净下沉速度
          final netFallSpeed = fallSpeed - w;
          
          if (netFallSpeed > 0 && k < nz - 1) {
            // 雨水从上层下沉到当前层
            final fallFraction = min(1.0, netFallSpeed * _dt / 200.0); // 200m层高
            newQrain[k][j][i] = qr * (1 - fallFraction) + qrain[k+1][j][i] * fallFraction;
          } else {
            newQrain[k][j][i] = qr;
          }
          
          // 地面雨水移除
          if (k == 0) {
            newQrain[k][j][i] *= 0.1; // 90%的雨水到达地面
          }
        }
      }
    }
    
    _copyGridData(newQrain, qrain);
  }
  
  /// 更新降水率到网格
  void _updatePrecipitationRate(List<List<double>> precipitationRate) {
    for (int j = 0; j < _grid.ny; j++) {
      for (int i = 0; i < _grid.nx; i++) {
        _grid.setValue(MeteorologyVariable.precipitation, i, j, 0, precipitationRate[j][i]);
      }
    }
  }
  
  /// 检查数值稳定性
  bool checkStability(List<List<List<double>>> qvapor,
                      List<List<List<double>>> qcloud,
                      List<List<List<double>>> qrain) {
    // 检查水物质含量的合理性
    for (int k = 0; k < _grid.nz; k++) {
      for (int j = 0; j < _grid.ny; j++) {
        for (int i = 0; i < _grid.nx; i++) {
          final totalWater = qvapor[k][j][i] + qcloud[k][j][i] + qrain[k][j][i];
          if (totalWater < 0 || totalWater > 0.05) { // 最大50g/kg
            return false;
          }
        }
      }
    }
    return true;
  }
  
  /// 复制网格数据
  void _copyGridData(List<List<List<double>>> source,
                     List<List<List<double>>> target) {
    for (int k = 0; k < _grid.nz; k++) {
      for (int j = 0; j < _grid.ny; j++) {
        for (int i = 0; i < _grid.nx; i++) {
          target[k][j][i] = source[k][j][i];
        }
      }
    }
  }
}