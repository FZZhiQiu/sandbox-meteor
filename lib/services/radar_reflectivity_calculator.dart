import 'dart:math';
import '../core/app_config.dart';
import '../models/meteorology_state.dart';

/// 雷达反射率计算器
/// 基于气象微物理量计算雷达反射率因子Z和等效反射率因子Ze
class RadarReflectivityCalculator {
  final MeteorologyGrid _grid;
  
  RadarReflectivityCalculator(this._grid);
  
  /// 计算雷达反射率因子Z (mm^6/m^3)
  /// 基于雨滴尺寸分布的Marshall-Palmer关系
  double calculateReflectivity(
    List<List<List<double>>> qrain,
    int i, int j, int k,
  ) {
    final qr = qrain[k][j][i]; // 雨水混合比 kg/kg
    
    if (qr <= 0) return -10.0; // 无降水时返回最小值
    
    // 1. 将雨水混合比转换为雨水含量 (g/m³)
    final rho_air = 1.225; // 空气密度 kg/m³
    final qw = qr * rho_air * 1000.0; // g/m³
    
    // 2. Marshall-Palmer关系：Z = 200 * R^1.6
    // 其中R是降水率 (mm/h)，qw与R的关系需要考虑下落速度
    final rainRate = _calculateRainRate(qw);
    
    // 3. 计算反射率因子Z (mm^6/m^3)
    final Z = 200.0 * pow(rainRate, 1.6);
    
    return Z;
  }
  
  /// 计算等效反射率因子Ze (考虑冰相粒子)
  double calculateEquivalentReflectivity(
    List<List<List<double>>> qrain,
    List<List<List<double>>> qcloud,
    List<List<List<double>>> qice,
    double temperature,
    int i, int j, int k,
  ) {
    final qr = qrain[k][j][i];
    final qc = qcloud[k][j][i];
    final qi = qice[k][j][i];
    final tempC = temperature - 273.15;
    
    if (qr <= 0 && qc <= 0 && qi <= 0) {
      return -10.0; // 无水物质
    }
    
    double Ze = 0.0;
    
    // 1. 雨水贡献 (液相)
    if (qr > 0) {
      final Z_rain = calculateReflectivity(qrain, i, j, k);
      Ze += Z_rain;
    }
    
    // 2. 云水贡献 (小水滴，使用Rayleigh散射)
    if (qc > 0) {
      final Z_cloud = _calculateCloudReflectivity(qc, temperature);
      Ze += Z_cloud;
    }
    
    // 3. 冰相贡献 (冰晶、雪等)
    if (qi > 0 && tempC < 0) {
      final Z_ice = _calculateIceReflectivity(qi, temperature);
      Ze += Z_ice;
    }
    
    return Ze;
  }
  
  /// 计算云水反射率 (Rayleigh散射)
  double _calculateCloudReflectivity(double qc, double temperature) {
    // 云滴半径假设为10微米
    const r_cloud = 10e-6; // m
    const rho_water = 1000.0; // kg/m³
    
    // 云滴数浓度估算
    final rho_air = 1.225; // kg/m³
    final N = (qc * rho_air) / ((4.0/3.0) * pi * pow(r_cloud, 3) * rho_water);
    
    // Rayleigh散射反射率
    final K2 = 0.93; // 水的介电常数因子
    final lambda = 0.05; // 5cm波长雷达
    final Z_cloud = (pi^5 * K2 * N * pow(r_cloud, 6)) / lambda^4;
    
    return Z_cloud;
  }
  
  /// 计算冰相反射率
  double _calculateIceReflectivity(double qi, double temperature) {
    final tempC = temperature - 273.15;
    
    // 根据温度选择冰相粒子类型
    double r_ice, rho_ice;
    
    if (tempC > -10) {
      // 过冷水滴或小冰晶
      r_ice = 50e-6; // 50微米
      rho_ice = 917.0; // kg/m³
    } else if (tempC > -20) {
      // 雪花
      r_ice = 200e-6; // 200微米
      rho_ice = 100.0; // kg/m³ (考虑雪花密度)
    } else {
      // 冰晶或霰
      r_ice = 100e-6; // 100微米
      rho_ice = 500.0; // kg/m³
    }
    
    // 冰粒子数浓度
    final rho_air = 1.225;
    final N = (qi * rho_air) / ((4.0/3.0) * pi * pow(r_ice, 3) * rho_ice);
    
    // 冰的介电常数因子 (随温度变化)
    final K2_ice = _calculateIceDielectricFactor(temperature);
    
    // 雷达反射率
    final lambda = 0.05; // 5cm波长
    final Z_ice = (pi^5 * K2_ice * N * pow(r_ice, 6)) / lambda^4;
    
    return Z_ice;
  }
  
  /// 计算冰的介电常数因子
  double _calculateIceDielectricFactor(double temperature) {
    final tempC = temperature - 273.15;
    
    // 简化的温度依赖关系
    if (tempC > -5) {
      return 0.85; // 接近水的介电常数
    } else if (tempC > -15) {
      return 0.75;
    } else {
      return 0.65; // 纯冰的介电常数
    }
  }
  
  /// 计算降水率 (mm/h)
  double _calculateRainRate(double qw) {
    if (qw <= 0) return 0.0;
    
    // 经验关系：R = a * qw^b
    // 其中qw是雨水含量 (g/m³)
    const a = 0.036; // 经验系数
    const b = 1.15;   // 经验指数
    
    final rainRate = a * pow(qw, b);
    
    return rainRate;
  }
  
  /// 计算雷达反射率因子dBZ
  double calculateReflectivitydBZ(double Z) {
    if (Z <= 0) return -10.0;
    
    return 10.0 * log10(Z);
  }
  
  /// 获取完整的雷达反射率场
  List<List<List<double>>> calculateReflectivityField(
    List<List<List<double>>> qrain,
    List<List<List<double>>> qcloud,
    List<List<List<double>>> qice,
    List<List<List<double>>> temperature,
  ) {
    final nx = _grid.nx;
    final ny = _grid.ny;
    final nz = _grid.nz;
    
    final reflectivityField = List.generate(nz, (k) =>
        List.generate(ny, (j) => List.filled(nx, -10.0)));
    
    for (int k = 0; k < nz; k++) {
      for (int j = 0; j < ny; j++) {
        for (int i = 0; i < nx; i++) {
          final Ze = calculateEquivalentReflectivity(
            qrain, qcloud, qice, temperature[k][j][i], i, j, k,
          );
          reflectivityField[k][j][i] = Ze;
        }
      }
    }
    
    return reflectivityField;
  }
  
  /// 计算多普勒速度估计
  double calculateDopplerVelocity(
    List<List<List<double>>> uWind,
    List<List<List<double>>> vWind,
    List<List<List<double>>> wWind,
    double radarAzimuth, // 雷达方位角 (弧度)
    double radarElevation, // 雷达仰角 (弧度)
    int i, int j, int k,
  ) {
    final u = uWind[k][j][i];
    final v = vWind[k][j][i];
    final w = wWind[k][j][i];
    
    // 计算径向速度分量
    final radialVelocity = u * cos(radarAzimuth) + 
                         v * sin(radarAzimuth) +
                         w * sin(radarElevation);
    
    return radialVelocity;
  }
  
  /// 计算雷达谱宽 (速度标准差)
  double calculateSpectralWidth(
    List<List<List<double>>> uWind,
    List<List<List<double>>> vWind,
    List<List<List<double>>> wWind,
    int i, int j, int k,
    int windowSize = 3,
  ) {
    final nx = _grid.nx;
    final ny = _grid.ny;
    final nz = _grid.nz;
    
    List<double> velocities = [];
    
    // 收集窗口内的速度样本
    for (int dk = -windowSize; dk <= windowSize; dk++) {
      for (int dj = -windowSize; dj <= windowSize; dj++) {
        for (int di = -windowSize; di <= windowSize; di++) {
          final ki = k + dk;
          final kj = j + dj;
          final ii = i + di;
          
          if (ki >= 0 && ki < nz && kj >= 0 && kj < ny && ii >= 0 && ii < nx) {
            final u = uWind[ki][kj][ii];
            final v = vWind[ki][kj][ii];
            final w = wWind[ki][kj][ii];
            final speed = sqrt(u*u + v*v + w*w);
            velocities.add(speed);
          }
        }
      }
    }
    
    if (velocities.isEmpty) return 0.0;
    
    // 计算标准差
    final mean = velocities.reduce((a, b) => a + b) / velocities.length;
    final variance = velocities.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / velocities.length;
    
    return sqrt(variance);
  }
  
  /// 获取雷达产品类型
  Map<String, dynamic> generateRadarProducts(
    List<List<List<double>>> qrain,
    List<List<List<double>>> qcloud,
    List<List<List<double>>> qice,
    List<List<List<double>>> temperature,
    List<List<List<double>>> uWind,
    List<List<List<double>>> vWind,
    List<List<List<double>>> wWind,
  ) {
    // 1. 基本反射率场
    final reflectivityField = calculateReflectivityField(
      qrain, qcloud, qice, temperature,
    );
    
    // 2. dBZ场
    final dBZField = List.generate(_grid.nz, (k) =>
        List.generate(_grid.ny, (j) => List.filled(_grid.nx, -10.0)));
    
    for (int k = 0; k < _grid.nz; k++) {
      for (int j = 0; j < _grid.ny; j++) {
        for (int i = 0; i < _grid.nx; i++) {
          dBZField[k][j][i] = calculateReflectivitydBZ(reflectivityField[k][j][i]);
        }
      }
    }
    
    // 3. 速度场
    final velocityField = List.generate(_grid.nz, (k) =>
        List.generate(_grid.ny, (j) => List.filled(_grid.nx, 0.0)));
    
    for (int k = 0; k < _grid.nz; k++) {
      for (int j = 0; j < _grid.ny; j++) {
        for (int i = 0; i < _grid.nx; i++) {
          velocityField[k][j][i] = calculateDopplerVelocity(
            uWind, vWind, wWind, 0.0, 0.0, i, j, k,
          );
        }
      }
    }
    
    // 4. 谱宽场
    final spectralWidthField = List.generate(_grid.nz, (k) =>
        List.generate(_grid.ny, (j) => List.filled(_grid.nx, 0.0)));
    
    for (int k = 0; k < _grid.nz; k++) {
      for (int j = 0; j < _grid.ny; j++) {
        for (int i = 0; i < _grid.nx; i++) {
          spectralWidthField[k][j][i] = calculateSpectralWidth(
            uWind, vWind, wWind, i, j, k,
          );
        }
      }
    }
    
    return {
      'reflectivity': reflectivityField,
      'dBZ': dBZField,
      'velocity': velocityField,
      'spectral_width': spectralWidthField,
      'max_reflectivity': _findMaxValue(reflectivityField),
      'max_dBZ': _findMaxValue(dBZField),
      'mean_velocity': _calculateMean(velocityField),
    };
  }
  
  double _findMaxValue(List<List<List<double>>> field) {
    double maxValue = -double.infinity;
    
    for (int k = 0; k < _grid.nz; k++) {
      for (int j = 0; j < _grid.ny; j++) {
        for (int i = 0; i < _grid.nx; i++) {
          final value = field[k][j][i];
          if (value > maxValue) {
            maxValue = value;
          }
        }
      }
    }
    
    return maxValue.isFinite ? maxValue : 0.0;
  }
  
  double _calculateMean(List<List<List<double>>> field) {
    double sum = 0.0;
    int count = 0;
    
    for (int k = 0; k < _grid.nz; k++) {
      for (int j = 0; j < _grid.ny; j++) {
        for (int i = 0; i < _grid.nx; i++) {
          sum += field[k][j][i].abs();
          count++;
        }
      }
    }
    
    return count > 0 ? sum / count : 0.0;
  }
}