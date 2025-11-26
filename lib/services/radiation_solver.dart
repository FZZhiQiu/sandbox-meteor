import 'dart:math';
import '../core/app_config.dart';
import '../models/meteorology_state.dart';
import '../utils/math_utils.dart';

/// 辐射传输求解器
/// 实现短波和长波辐射的参数化方案
class RadiationSolver {
  final MeteorologyGrid _grid;
  final double _dx, _dy, _dz, _dt;
  
  // 辐射常数
  final double _solarConstant;      // 太阳常数
  final double _stefanBoltzmann;    // 斯特藩-玻尔兹曼常数
  final double _emissivity;         // 地面发射率
  final double _albedo;             // 地面反照率
  
  RadiationSolver(this._grid)
      : _dx = 1000.0, // 1km 网格间距
        _dy = 1000.0,
        _dz = 200.0,  // 200m 垂直间距
        _dt = AppConfig.timeStep,
        _solarConstant = 1367.0,      // W/m²
        _stefanBoltzmann = 5.67e-8,   // W/(m²·K⁴)
        _emissivity = 0.95,           // 地面发射率
        _albedo = 0.3;                // 地面反照率
  
  /// 求解辐射传输过程
  /// [temperature] - 温度场
  /// [humidity] - 湿度场
  /// [cloud] - 云量场
  /// [pressure] - 气压场
  /// [hour] - 当前小时（用于计算太阳高度角）
  void solveRadiation(
    List<List<List<double>>> temperature,
    List<List<List<double>>> humidity,
    List<List<List<double>>> cloud,
    List<List<List<double>>> pressure,
    int hour,
  ) {
    final nx = _grid.nx;
    final ny = _grid.ny;
    final nz = _grid.nz;
    
    // 创建温度倾向数组
    final temperatureTendency = List.generate(nz, (k) => 
        List.generate(ny, (j) => List.filled(nx, 0.0)));
    
    for (int j = 0; j < ny; j++) {
      for (int i = 0; i < nx; i++) {
        // TODO: 集成 Gemini CLI 返回的辐射传输算法
        
        // 1. 计算太阳高度角
        final solarZenithAngle = _calculateSolarZenithAngle(hour, i, j);
        
        // 2. 计算短波辐射
        final shortWaveHeating = _calculateShortWaveRadiation(
          temperature, humidity, cloud, pressure,
          i, j, solarZenithAngle,
        );
        
        // 3. 计算长波辐射
        final longWaveHeating = _calculateLongWaveRadiation(
          temperature, humidity, cloud, pressure, i, j,
        );
        
        // 4. 垂直积分辐射加热率
        for (int k = 0; k < nz; k++) {
          temperatureTendency[k][j][i] = 
              shortWaveHeating[k] + longWaveHeating[k];
        }
      }
    }
    
    // 更新温度场
    _updateTemperatureField(temperature, temperatureTendency);
  }
  
  /// 计算太阳天顶角
  double _calculateSolarZenithAngle(int hour, int i, int j) {
    // TODO: 集成 Gemini CLI 返回的精确太阳位置计算
    
    // 简化的太阳天顶角计算
    final latitude = _mapGridToLatitude(j);
    final longitude = _mapGridToLongitude(i);
    
    // 太阳赤纬（简化计算）
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    final declination = 23.45 * sin(2 * pi * (dayOfYear - 81) / 365);
    
    // 时角
    final hourAngle = 15.0 * (hour - 12.0);
    
    // 太阳天顶角
    final zenithAngle = acos(
      sin(latitude * pi / 180) * sin(declination * pi / 180) +
      cos(latitude * pi / 180) * cos(declination * pi / 180) * cos(hourAngle * pi / 180)
    );
    
    return zenithAngle;
  }
  
  /// 计算短波辐射 - 完整的辐射传输实现
  List<double> _calculateShortWaveRadiation(
    List<List<List<double>>> temperature,
    List<List<List<double>>> humidity,
    List<List<List<double>>> cloud,
    List<List<List<double>>> pressure,
    int i, int j,
    double solarZenithAngle,
  ) {
    final nz = _grid.nz;
    final heatingRates = List.filled(nz, 0.0);
    
    // 1. 计算太阳辐射参数
    final topOfAtmosphereRadiation = _solarConstant * cos(solarZenithAngle);
    
    if (topOfAtmosphereRadiation <= 0) return heatingRates; // 夜间
    
    // 2. 大气层光学参数
    final layerOpticalDepths = List.filled(nz, 0.0);
    final layerAbsorptivities = List.filled(nz, 0.0);
    
    // 3. 计算各层光学厚度和吸收率
    for (int k = 0; k < nz; k++) {
      final temp = temperature[k][j][i];
      final humidity = humidity[k][j][i];
      final cloudCover = cloud[k][j][i];
      final press = pressure[k][j][i];
      
      // 瑞利散射光学厚度
      final rayleighDepth = _calculateRayleighOpticalDepth(press);
      
      // 水汽吸收光学厚度
      final waterVaporDepth = _calculateWaterVaporOpticalDepth(humidity, press);
      
      // 云光学厚度
      final cloudDepth = _calculateCloudOpticalDepth(cloudCover);
      
      // 气溶胶光学厚度（简化）
      final aerosolDepth = _calculateAerosolOpticalDepth(k);
      
      // 总光学厚度
      layerOpticalDepths[k] = rayleighDepth + waterVaporDepth + cloudDepth + aerosolDepth;
      
      // 吸收率（散射部分不直接加热）
      layerAbsorptivities[k] = _calculateLayerAbsorptivity(
        waterVaporDepth, cloudDepth, aerosolDepth,
      );
    }
    
    // 4. 辐射传输计算（从上到下）
    double downwardRadiation = topOfAtmosphereRadiation;
    
    for (int k = nz - 1; k >= 0; k--) {
      final opticalDepth = layerOpticalDepths[k];
      final absorptivity = layerAbsorptivities[k];
      
      // 透过率
      final transmittance = exp(-opticalDepth / cos(solarZenithAngle));
      
      // 吸收的辐射
      final absorbedRadiation = downwardRadiation * (1 - transmittance) * absorptivity;
      
      // 转换为加热率
      final temp = temperature[k][j][i];
      final press = pressure[k][j][i];
      final airDensity = press / (287.05 * temp);
      final specificHeat = 1004.0;
      
      heatingRates[k] = absorbedRadiation / (airDensity * specificHeat * _dz);
      
      // 更新向下辐射
      downwardRadiation *= transmittance;
    }
    
    // 5. 地面反射辐射（简化）
    final surfaceAlbedo = _calculateSurfaceAlbedo(i, j);
    final upwardRadiation = downwardRadiation * surfaceAlbedo;
    
    // 6. 向上辐射传输（从下到上）
    for (int k = 0; k < nz; k++) {
      final opticalDepth = layerOpticalDepths[k];
      final absorptivity = layerAbsorptivities[k];
      
      final transmittance = exp(-opticalDepth);
      final absorbedUpward = upwardRadiation * (1 - transmittance) * absorptivity;
      
      // 添加向上辐射加热
      final temp = temperature[k][j][i];
      final press = pressure[k][j][i];
      final airDensity = press / (287.05 * temp);
      final specificHeat = 1004.0;
      
      heatingRates[k] += absorbedUpward / (airDensity * specificHeat * _dz);
      
      upwardRadiation *= transmittance;
    }
    
    return heatingRates;
  }
  
  /// 计算气溶胶光学厚度
  double _calculateAerosolOpticalDepth(int k) {
    // 简化的气溶胶垂直分布
    const surfaceAerosolDepth = 0.1;
    const scaleHeight = 2000.0; // m
    final height = k * _dz;
    
    return surfaceAerosolDepth * exp(-height / scaleHeight);
  }
  
  /// 计算层吸收率
  double _calculateLayerAbsorptivity(
    double waterVaporDepth,
    double cloudDepth,
    double aerosolDepth,
  ) {
    // 水汽吸收率
    const waterVaporAbsorptivity = 0.8;
    
    // 云吸收率
    const cloudAbsorptivity = 0.3;
    
    // 气溶胶吸收率
    const aerosolAbsorptivity = 0.5;
    
    // 加权平均
    final totalDepth = waterVaporDepth + cloudDepth + aerosolDepth;
    if (totalDepth > 0) {
      return (waterVaporDepth * waterVaporAbsorptivity +
              cloudDepth * cloudAbsorptivity +
              aerosolDepth * aerosolAbsorptivity) / totalDepth;
    }
    
    return 0.0;
  }
  
  /// 计算地表反照率
  double _calculateSurfaceAlbedo(int i, int j) {
    // 简化的地表反照率模型
    // 可以基于土地利用、雪盖等因素
    
    // 基础反照率
    double baseAlbedo = 0.2;
    
    // 纬度修正（高纬度反照率更高）
    final latitude = _mapGridToLatitude(j);
    final latitudeFactor = 1.0 + 0.3 * (latitude.abs() / 90.0);
    
    // 季节修正（简化）
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    final seasonalFactor = 1.0 + 0.1 * cos(2 * pi * (dayOfYear - 172) / 365);
    
    final albedo = baseAlbedo * latitudeFactor * seasonalFactor;
    
    return albedo.clamp(0.1, 0.8);
  }
  
  /// 计算长波辐射
  List<double> _calculateLongWaveRadiation(
    List<List<List<double>>> temperature,
    List<List<List<double>>> humidity,
    List<List<List<double>>> cloud,
    List<List<List<double>>> pressure,
    int i, int j,
  ) {
    final nz = _grid.nz;
    final heatingRates = List.filled(nz, 0.0);
    
    // 1. 地面向上长波辐射
    final surfaceTemp = temperature[0][j][i];
    final surfaceLongWaveUp = _emissivity * _stefanBoltzmann * pow(surfaceTemp, 4);
    
    // 2. 计算各层长波辐射通量
    List<double> upwardFlux = List.filled(nz + 1, 0.0);
    List<double> downwardFlux = List.filled(nz + 1, 0.0);
    
    upwardFlux[0] = surfaceLongWaveUp;
    
    // 向上传播
    for (int k = 0; k < nz; k++) {
      final temp = temperature[k][j][i];
      final humidity = humidity[k][j][i];
      final cloudCover = cloud[k][j][i];
      
      // 大气发射率
      final emissivity = _calculateAtmosphericEmissivity(temp, humidity, cloudCover);
      final layerEmission = emissivity * _stefanBoltzmann * pow(temp, 4);
      
      // 透过率
      final transmittance = 1 - emissivity;
      
      upwardFlux[k + 1] = upwardFlux[k] * transmittance + layerEmission;
    }
    
    // 大气顶向下长波辐射（通常为0）
    downwardFlux[nz] = 0;
    
    // 向下传播
    for (int k = nz - 1; k >= 0; k--) {
      final temp = temperature[k][j][i];
      final humidity = humidity[k][j][i];
      final cloudCover = cloud[k][j][i];
      
      final emissivity = _calculateAtmosphericEmissivity(temp, humidity, cloudCover);
      final layerEmission = emissivity * _stefanBoltzmann * pow(temp, 4);
      final transmittance = 1 - emissivity;
      
      downwardFlux[k] = downwardFlux[k + 1] * transmittance + layerEmission;
    }
    
    // 3. 计算各层净长波辐射和加热率
    for (int k = 0; k < nz; k++) {
      final netFluxDivergence = (upwardFlux[k+1] - upwardFlux[k] + 
                               downwardFlux[k] - downwardFlux[k+1]) / _dz;
      
      final temp = temperature[k][j][i];
      final press = pressure[k][j][i];
      final airDensity = press / (287.05 * temp);
      final specificHeat = 1004.0;
      
      heatingRates[k] = netFluxDivergence / (airDensity * specificHeat);
    }
    
    return heatingRates;
  }
  
  /// 计算瑞利散射光学厚度
  double _calculateRayleighOpticalDepth(double pressure) {
    // 简化的瑞利散射光学厚度
    return 0.008569 * (pressure / 101325.0);
  }
  
  /// 计算水汽吸收光学厚度
  double _calculateWaterVaporOpticalDepth(double humidity, double pressure) {
    // 简化的水汽吸收光学厚度
    final waterVaporAmount = humidity * pressure / (287.05 * 273.15);
    return 0.1 * waterVaporAmount;
  }
  
  /// 计算云光学厚度
  double _calculateCloudOpticalDepth(double cloudCover) {
    // 云光学厚度与云量的关系
    return cloudCover * 10.0; // 典型云光学厚度10
  }
  
  /// 计算大气发射率
  double _calculateAtmosphericEmissivity(double temperature, double humidity, double cloudCover) {
    // 水汽发射率
    final waterVaporEmissivity = 0.7 * humidity;
    
    // 云发射率
    final cloudEmissivity = cloudCover;
    
    // 总发射率
    return min(1.0, waterVaporEmissivity + cloudEmissivity);
  }
  
  /// 将网格坐标转换为纬度
  double _mapGridToLatitude(int j) {
    return AppConfig.mapSouth + 
           (AppConfig.mapNorth - AppConfig.mapSouth) * j / _grid.ny;
  }
  
  /// 将网格坐标转换为经度
  double _mapGridToLongitude(int i) {
    return AppConfig.mapWest + 
           (AppConfig.mapEast - AppConfig.mapWest) * i / _grid.nx;
  }
  
  /// 更新温度场
  void _updateTemperatureField(
    List<List<List<double>>> temperature,
    List<List<List<double>>> temperatureTendency,
  ) {
    for (int k = 0; k < _grid.nz; k++) {
      for (int j = 0; j < _grid.ny; j++) {
        for (int i = 0; i < _grid.nx; i++) {
          temperature[k][j][i] += temperatureTendency[k][j][i] * _dt;
        }
      }
    }
  }
  
  /// 检查数值稳定性
  bool checkStability(List<List<List<double>>> temperature) {
    // 检查温度范围合理性
    for (int k = 0; k < _grid.nz; k++) {
      for (int j = 0; j < _grid.ny; j++) {
        for (int i = 0; i < _grid.nx; i++) {
          final temp = temperature[k][j][i];
          if (temp < 150.0 || temp > 350.0) { // 合理温度范围
            return false;
          }
        }
      }
    }
    return true;
  }
}