import 'dart:math';
import '../core/app_config.dart';
import '../models/meteorology_state.dart';
import '../utils/math_utils.dart';

/// 边界层湍流求解器
/// 基于 M-O 相似理论和 K 理论的湍流参数化
class BoundaryLayerSolver {
  final MeteorologyGrid _grid;
  final double _dx, _dy, _dz, _dt;
  
  // 边界层参数
  final double _vonKarman;        // von Karman 常数
  final double _z0;               // 粗糙度长度
  final double _surfaceRoughness; // 地表粗糙度
  final double _minMixingLength;  // 最小混合长度
  
  BoundaryLayerSolver(this._grid)
      : _dx = 1000.0, // 1km 网格间距
        _dy = 1000.0,
        _dz = 200.0,  // 200m 垂直间距
        _dt = AppConfig.timeStep,
        _vonKarman = 0.4,           // von Karman 常数
        _z0 = 0.1,                  // 粗糙度长度 10cm
        _surfaceRoughness = 0.01,    // 地表粗糙度
        _minMixingLength = 1.0;      // 最小混合长度 1m
  
  /// 求解边界层湍流过程
  /// [uWind], [vWind], [wWind] - 风场分量
  /// [temperature] - 温度场
  /// [humidity] - 湿度场
  /// [pressure] - 气压场
  void solveBoundaryLayer(
    List<List<List<double>>> uWind,
    List<List<List<double>>> vWind,
    List<List<List<double>>> wWind,
    List<List<List<double>>> temperature,
    List<List<List<double>>> humidity,
    List<List<List<double>>> pressure,
  ) {
    final nx = _grid.nx;
    final ny = _grid.ny;
    final nz = _grid.nz;
    
    // 计算边界层高度
    final boundaryLayerHeight = List.generate(ny, (j) => List.filled(nx, 0.0));
    _calculateBoundaryLayerHeight(
      temperature, uWind, vWind, boundaryLayerHeight,
    );
    
    // 计算湍流交换系数
    final eddyViscosity = List.generate(nz, (k) => 
        List.generate(ny, (j) => List.filled(nx, 0.0)));
    final eddyDiffusivity = List.generate(nz, (k) => 
        List.generate(ny, (j) => List.filled(nx, 0.0)));
    
    _calculateTurbulentCoefficients(
      temperature, uWind, vWind, boundaryLayerHeight,
      eddyViscosity, eddyDiffusivity,
    );
    
    // 应用湍流混合
    _applyTurbulentMixing(
      uWind, vWind, wWind, temperature, humidity,
      eddyViscosity, eddyDiffusivity,
    );
    
    // 计算地表通量
    _calculateSurfaceFluxes(
      uWind, vWind, temperature, humidity, pressure,
    );
  }
  
  /// 计算边界层高度
  void _calculateBoundaryLayerHeight(
    List<List<List<double>>> temperature,
    List<List<List<double>>> uWind,
    List<List<List<double>>> vWind,
    List<List<double>> boundaryLayerHeight,
  ) {
    final nx = _grid.nx;
    final ny = _grid.ny;
    
    for (int j = 0; j < ny; j++) {
      for (int i = 0; i < nx; i++) {
        // TODO: 集成 Gemini CLI 返回的边界层高度计算算法
        
        double blHeight = 1000.0; // 默认边界层高度
        final surfaceTemp = temperature[0][j][i];
        
        // 方法1：基于位温梯度
        for (int k = 1; k < _grid.nz; k++) {
          final currentTemp = temperature[k][j][i];
          final belowTemp = temperature[k-1][j][i];
          final height = k * _dz;
          
          final potentialTempCurrent = MathUtils.potentialTemperature(currentTemp, 101325.0);
          final potentialTempBelow = MathUtils.potentialTemperature(belowTemp, 101325.0);
          final dThetaDz = (potentialTempCurrent - potentialTempBelow) / _dz;
          
          // 当位温梯度超过阈值时认为是边界层顶
          if (dThetaDz > 0.01) { // 0.01 K/m
            blHeight = height;
            break;
          }
        }
        
        // 方法2：基于风切变
        double maxShear = 0;
        int shearLevel = 0;
        
        for (int k = 1; k < _grid.nz - 1; k++) {
          final u = uWind[k][j][i];
          final v = vWind[k][j][i];
          final uBelow = uWind[k-1][j][i];
          final vBelow = vWind[k-1][j][i];
          
          final windShear = sqrt(pow(u - uBelow, 2) + pow(v - vBelow, 2)) / _dz;
          
          if (windShear > maxShear) {
            maxShear = windShear;
            shearLevel = k;
          }
        }
        
        // 综合两种方法的结果
        final shearHeight = shearLevel * _dz;
        blHeight = (blHeight + shearHeight) / 2;
        
        // 限制边界层高度范围
        boundaryLayerHeight[j][i] = blHeight.clamp(200.0, 3000.0);
      }
    }
  }
  
  /// 计算湍流交换系数 - 完整的 M-O 相似理论实现
  void _calculateTurbulentCoefficients(
    List<List<List<double>>> temperature,
    List<List<List<double>>> uWind,
    List<List<List<double>>> vWind,
    List<List<double>> boundaryLayerHeight,
    List<List<List<double>>> eddyViscosity,
    List<List<List<double>>> eddyDiffusivity,
  ) {
    final nx = _grid.nx;
    final ny = _grid.ny;
    final nz = _grid.nz;
    
    // 物理常数
    const g = 9.81; // m/s²
    const vonKarman = 0.4;
    const beta = 1.0 / 300.0; // 热膨胀系数 1/K
    
    for (int j = 0; j < ny; j++) {
      for (int i = 0; i < nx; i++) {
        final blHeight = boundaryLayerHeight[j][i];
        final surfaceTemp = temperature[0][j][i];
        final surfaceU = uWind[0][j][i];
        final surfaceV = vWind[0][j][i];
        
        // 计算摩擦速度
        final frictionVelocity = _calculateFrictionVelocity(surfaceU, surfaceV);
        
        // 计算地表热通量（简化）
        final surfaceHeatFlux = _calculateSurfaceHeatFlux(temperature, i, j);
        
        // Monin-Obukhov 长度
        final moninObukhovLength = _calculateMoninObukhovLength(
          frictionVelocity, surfaceHeatFlux, surfaceTemp,
        );
        
        for (int k = 0; k < nz; k++) {
          final height = max(_z0, k * _dz);
          
          // 1. 混合长度（Blackadar 方案）
          final mixingLength = _calculateBlackadarMixingLength(height, blHeight);
          
          // 2. 稳定性参数
          final zeta = height / moninObukhovLength;
          
          // 3. 稳定性函数（Businger-Dyer 关系）
          final stabilityFunctionMomentum = _calculateStabilityFunctionMomentum(zeta);
          final stabilityFunctionHeat = _calculateStabilityFunctionHeat(zeta);
          
          // 4. 湍流粘性系数
          final km = frictionVelocity * vonKarman * mixingLength * stabilityFunctionMomentum;
          eddyViscosity[k][j][i] = max(0.1, km); // 最小值约束
          
          // 5. 湍流扩散系数
          final kh = frictionVelocity * vonKarman * mixingLength * stabilityFunctionHeat;
          eddyDiffusivity[k][j][i] = max(0.1, kh);
          
          // 6. Prandtl 数修正
          final prandtlNumber = _calculatePrandtlNumber(zeta);
          eddyDiffusivity[k][j][i] = eddyViscosity[k][j][i] / prandtlNumber;
        }
      }
    }
  }
  
  /// 计算地表热通量
  double _calculateSurfaceHeatFlux(
    List<List<List<double>>> temperature,
    int i, int j,
  ) {
    // 简化的地表热通量计算
    final surfaceTemp = temperature[0][j][i];
    final airTemp = temperature[1][j][i]; // 第一层大气温度
    
    // 温度梯度
    final tempGradient = (airTemp - surfaceTemp) / _dz;
    
    // 热传导系数（简化）
    const thermalConductivity = 10.0; // W/(m²·K)
    
    return thermalConductivity * tempGradient;
  }
  
  /// 计算 Monin-Obukhov 长度
  double _calculateMoninObukhovLength(
    double frictionVelocity,
    double surfaceHeatFlux,
    double surfaceTemp,
  ) {
    const g = 9.81; // m/s²
    const rho = 1.2; // kg/m³
    const cp = 1004.0; // J/(kg·K)
    const vonKarman = 0.4;
    
    if (surfaceHeatFlux.abs() < 1e-6) {
      return 1e6; // 中性条件
    }
    
    final L = -(rho * cp * surfaceTemp * frictionVelocity * frictionVelocity * frictionVelocity) /
             (vonKarman * g * surfaceHeatFlux);
    
    return L.clamp(-1000.0, 1000.0); // 限制范围
  }
  
  /// Blackadar 混合长度方案
  double _calculateBlackadarMixingLength(double height, double blHeight) {
    const vonKarman = 0.4;
    const lambdaMax = 100.0; // 最大混合长度 m
    
    // 近地层混合长度
    final nearSurfaceLength = vonKarman * height / (1 + vonKarman * height / lambdaMax);
    
    // 边界层顶限制
    final boundaryLayerFactor = sin(pi * height / (2 * blHeight));
    
    return min(nearSurfaceLength, lambdaMax * boundaryLayerFactor);
  }
  
  /// 动量稳定性函数（Businger-Dyer）
  double _calculateStabilityFunctionMomentum(double zeta) {
    if (zeta > 0) {
      // 稳定条件
      return 1.0 / (1.0 + 5.0 * zeta);
    } else {
      // 不稳定条件
      final x = pow(1.0 - 16.0 * zeta, 0.25);
      return 1.0 / (1.0 - 16.0 * zeta).abs() * pow(x, 2);
    }
  }
  
  /// 热量稳定性函数（Businger-Dyer）
  double _calculateStabilityFunctionHeat(double zeta) {
    if (zeta > 0) {
      // 稳定条件
      return 1.0 / (1.0 + 5.0 * zeta);
    } else {
      // 不稳定条件
      final x = pow(1.0 - 16.0 * zeta, 0.25);
      return 1.0 / (1.0 - 16.0 * zeta).abs() * pow(x, 2);
    }
  }
  
  /// 计算 Prandtl 数
  double _calculatePrandtlNumber(double zeta) {
    // 基于 Richardson 数的 Prandtl 数
    if (zeta > 0) {
      // 稳定：Prandtl 数增大
      return 0.74 + 0.5 * zeta;
    } else {
      // 不稳定：Prandtl 数减小
      return 0.74 - 0.2 * zeta.abs();
    }
  }
  
  /// 计算摩擦速度
  double _calculateFrictionVelocity(double u, double v) {
    final windSpeed = sqrt(u * u + v * v);
    
    if (windSpeed < 0.1) return 0.1; // 最小摩擦速度
    
    // 对数风廓线关系
    final uStar = _vonKarman * windSpeed / log(10.0 / _z0); // 假设参考高度10m
    
    return uStar.clamp(0.01, 2.0); // 合理范围
  }
  
  /// 计算混合长度
  double _calculateMixingLength(double height, double boundaryLayerHeight) {
    // 在边界层内使用 Prandtl 混合长度理论
    if (height < boundaryLayerHeight) {
      final l = _vonKarman * height;
      return min(l, boundaryLayerHeight * 0.1); // 限制最大混合长度
    } else {
      // 在边界层外使用常数混合长度
      return _minMixingLength;
    }
  }
  
  /// 计算稳定性函数
  double _calculateStabilityFunction(
    List<List<List<double>>> temperature,
    double height,
    double boundaryLayerHeight,
    int i, int j,
  ) {
    // TODO: 集成 Gemini CLI 返回的 M-O 相似理论稳定性函数
    
    final surfaceTemp = temperature[0][j][i];
    final tempAtHeight = temperature[(height / _dz).toInt()][j][i];
    final potentialTempGradient = (tempAtHeight - surfaceTemp) / height;
    
    // Monin-Obukhov 长度（简化计算）
    final L = -1000.0; // 假设中性条件
    
    // 稳定性参数
    final zeta = height / L;
    
    // 稳定性函数（Businger-Dyer 关系）
    double phi;
    if (zeta > 0) {
      // 稳定条件
      phi = 1 + 5 * zeta;
    } else {
      // 不稳定条件
      final x = pow(1 - 16 * zeta, 0.25);
      phi = 2 * log((1 + x) / 2) + log((1 + x * x) / 2) - 2 * atan(x) + pi / 2;
    }
    
    return 1.0 / phi; // 返回稳定性修正因子
  }
  
  /// 应用湍流混合
  void _applyTurbulentMixing(
    List<List<List<double>>> uWind,
    List<List<List<double>>> vWind,
    List<List<List<double>>> wWind,
    List<List<List<double>>> temperature,
    List<List<List<double>>> humidity,
    List<List<List<double>>> eddyViscosity,
    List<List<List<double>>> eddyDiffusivity,
  ) {
    final nx = _grid.nx;
    final ny = _grid.ny;
    final nz = _grid.nz;
    
    // 创建临时数组
    final newUWind = List.generate(nz, (k) => 
        List.generate(ny, (j) => List.filled(nx, 0.0)));
    final newVWind = List.generate(nz, (k) => 
        List.generate(ny, (j) => List.filled(nx, 0.0)));
    final newTemperature = List.generate(nz, (k) => 
        List.generate(ny, (j) => List.filled(nx, 0.0)));
    final newHumidity = List.generate(nz, (k) => 
        List.generate(ny, (j) => List.filled(nx, 0.0)));
    
    for (int k = 1; k < nz - 1; k++) {
      for (int j = 1; j < ny - 1; j++) {
        for (int i = 1; i < nx - 1; i++) {
          // 计算湍流通量散度
          
          // 水平方向湍流混合
          final d2udx2 = (uWind[k][j][i+1] - 2*uWind[k][j][i] + uWind[k][j][i-1]) / (_dx * _dx);
          final d2udy2 = (uWind[k][j+1][i] - 2*uWind[k][j][i] + uWind[k][j-1][i]) / (_dy * _dy);
          final d2vdx2 = (vWind[k][j][i+1] - 2*vWind[k][j][i] + vWind[k][j][i-1]) / (_dx * _dx);
          final d2vdy2 = (vWind[k][j+1][i] - 2*vWind[k][j][i] + vWind[k][j-1][i]) / (_dy * _dy);
          
          final d2tdx2 = (temperature[k][j][i+1] - 2*temperature[k][j][i] + temperature[k][j][i-1]) / (_dx * _dx);
          final d2tdy2 = (temperature[k][j+1][i] - 2*temperature[k][j][i] + temperature[k][j-1][i]) / (_dy * _dy);
          final d2qdx2 = (humidity[k][j][i+1] - 2*humidity[k][j][i] + humidity[k][j][i-1]) / (_dx * _dx);
          final d2qdy2 = (humidity[k][j+1][i] - 2*humidity[k][j][i] + humidity[k][j-1][i]) / (_dy * _dy);
          
          // 垂直方向湍流混合
          final km = eddyViscosity[k][j][i];
          final kmAbove = eddyViscosity[k+1][j][i];
          final kmBelow = eddyViscosity[k-1][j][i];
          
          final kh = eddyDiffusivity[k][j][i];
          final khAbove = eddyDiffusivity[k+1][j][i];
          final khBelow = eddyDiffusivity[k-1][j][i];
          
          final d2udz2 = (kmAbove * (uWind[k+1][j][i] - uWind[k][j][i]) -
                        kmBelow * (uWind[k][j][i] - uWind[k-1][j][i])) / (_dz * _dz);
          final d2vdz2 = (kmAbove * (vWind[k+1][j][i] - vWind[k][j][i]) -
                        kmBelow * (vWind[k][j][i] - vWind[k-1][j][i])) / (_dz * _dz);
          final d2tdz2 = (khAbove * (temperature[k+1][j][i] - temperature[k][j][i]) -
                        khBelow * (temperature[k][j][i] - temperature[k-1][j][i])) / (_dz * _dz);
          final d2qdz2 = (khAbove * (humidity[k+1][j][i] - humidity[k][j][i]) -
                        khBelow * (humidity[k][j][i] - humidity[k-1][j][i])) / (_dz * _dz);
          
          // 时间步进更新
          newUWind[k][j][i] = uWind[k][j][i] + _dt * km * (d2udx2 + d2udy2 + d2udz2);
          newVWind[k][j][i] = vWind[k][j][i] + _dt * km * (d2vdx2 + d2vdy2 + d2vdz2);
          newTemperature[k][j][i] = temperature[k][j][i] + _dt * kh * (d2tdx2 + d2tdy2 + d2tdz2);
          newHumidity[k][j][i] = humidity[k][j][i] + _dt * kh * (d2qdx2 + d2qdy2 + d2qdz2);
        }
      }
    }
    
    // 更新场
    _copyGridData(newUWind, uWind);
    _copyGridData(newVWind, vWind);
    _copyGridData(newTemperature, temperature);
    _copyGridData(newHumidity, humidity);
  }
  
  /// 计算地表通量
  void _calculateSurfaceFluxes(
    List<List<List<double>>> uWind,
    List<List<List<double>>> vWind,
    List<List<List<double>>> temperature,
    List<List<List<double>>> humidity,
    List<List<List<double>>> pressure,
  ) {
    final nx = _grid.nx;
    final ny = _grid.ny;
    
    for (int j = 0; j < ny; j++) {
      for (int i = 0; i < nx; i++) {
        // 地表风速
        final u10 = uWind[0][j][i];
        final v10 = vWind[0][j][i];
        final windSpeed10 = sqrt(u10 * u10 + v10 * v10);
        
        // 地表温度和湿度
        final surfaceTemp = temperature[0][j][i];
        final surfaceHumidity = humidity[0][j][i];
        
        // 计算整体输送系数
        final dragCoefficient = _calculateDragCoefficient(windSpeed10);
        final heatTransferCoefficient = dragCoefficient * 1.1; // 稍大于动量输送
        final moistureTransferCoefficient = dragCoefficient * 1.1;
        
        // 计算空气密度
        final surfacePressure = pressure[0][j][i];
        final airDensity = surfacePressure / (287.05 * surfaceTemp);
        
        // 动量通量（摩擦速度）
        final momentumFlux = airDensity * dragCoefficient * windSpeed10 * windSpeed10;
        
        // 感热通量（简化计算）
        final heatFlux = airDensity * 1004.0 * heatTransferCoefficient * windSpeed10 * 2.0; // 假设2K温差
        
        // 潜热通量（简化计算）
        final latentHeatFlux = airDensity * 2.5e6 * moistureTransferCoefficient * windSpeed10 * 0.001; // 假设1g/kg湿度差
        
        // 将地表通量应用到最低层
        if (windSpeed10 > 0.1) {
          final uStar = sqrt(momentumFlux / airDensity);
          final windDirection = atan2(v10, u10);
          
          // 应用地表摩擦效应
          uWind[0][j][i] *= (1 - dragCoefficient);
          vWind[0][j][i] *= (1 - dragCoefficient);
          
          // 应用热力效应
          temperature[0][j][i] += heatFlux * _dt / (airDensity * 1004.0 * _dz);
          humidity[0][j][i] += latentHeatFlux * _dt / (airDensity * 2.5e6 * _dz);
        }
      }
    }
  }
  
  /// 计算拖曳系数
  double _calculateDragCoefficient(double windSpeed) {
    // 基于风速的拖曳系数计算
    if (windSpeed < 5.0) {
      return 0.0012;
    } else if (windSpeed < 15.0) {
      return 0.0012 + (windSpeed - 5.0) * 0.00008;
    } else {
      return 0.002;
    }
  }
  
  /// 检查数值稳定性
  bool checkStability(List<List<List<double>>> eddyViscosity,
                      List<List<List<double>>> eddyDiffusivity) {
    // 检查湍流系数合理性
    for (int k = 0; k < _grid.nz; k++) {
      for (int j = 0; j < _grid.ny; j++) {
        for (int i = 0; i < _grid.nx; i++) {
          final km = eddyViscosity[k][j][i];
          final kh = eddyDiffusivity[k][j][i];
          
          if (km < 0 || km > 1000 || kh < 0 || kh > 1000) {
            return false;
          }
          
          // CFL条件检查
          final cfl = km * _dt / (_dz * _dz);
          if (cfl > 0.5) {
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