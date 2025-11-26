import 'dart:math';
import '../core/app_config.dart';
import '../models/meteorology_state.dart';
import '../utils/math_utils.dart';

/// 水汽扩散与对流服务
/// 实现水汽输送方程 ∂q/∂t + u·∇q = K∇²q 和对流触发机制
class DiffusionService {
  final MeteorologyGrid _grid;
  final double _dx, _dy, _dz, _dt;
  final double _diffusivity; // 扩散系数
  
  DiffusionService(this._grid)
      : _dx = 1000.0, // 1km 网格间距
        _dy = 1000.0,
        _dz = 200.0,  // 200m 垂直间距
        _dt = AppConfig.timeStep,
        _diffusivity = 10.0; // 湍流扩散系数 m²/s
  
  /// 求解水汽扩散方程 - 完整的对流扩散实现
  /// [qvapor] - 水汽混合比
  /// [uWind], [vWind], [wWind] - 风场分量
  /// [temperature] - 温度场（用于对流判断）
  /// [pressure] - 气压场
  void solveDiffusion(
    List<List<List<double>>> qvapor,
    List<List<List<double>>> uWind,
    List<List<List<double>>> vWind,
    List<List<List<double>>> wWind,
    List<List<List<double>>> temperature,
    List<List<List<double>>> pressure,
  ) {
    final nx = _grid.nx;
    final ny = _grid.ny;
    final nz = _grid.nz;
    
    // 自适应扩散系数
    const baseDiffusivity = 10.0; // m²/s
    const maxDiffusivity = 100.0; // m²/s
    
    // 创建临时数组
    final newQvapor = List.generate(nz, (k) => 
        List.generate(ny, (j) => List.filled(nx, 0.0)));
    
    // CFL 稳定性检查
    if (!_checkDiffusionCFL(uWind, vWind, wWind)) {
      print('Warning: Diffusion CFL condition violated');
    }
    
    // 对每个网格点进行计算
    for (int k = 1; k < nz - 1; k++) {
      for (int j = 1; j < ny - 1; j++) {
        for (int i = 1; i < nx - 1; i++) {
          // 1. 获取基本变量
          final q = qvapor[k][j][i];
          final u = uWind[k][j][i];
          final v = vWind[k][j][i];
          final w = wWind[k][j][i];
          final temp = temperature[k][j][i];
          final press = pressure[k][j][i];
          
          // 2. 计算局地扩散系数（基于风切变）
          final localDiffusivity = _calculateLocalDiffusivity(
            uWind, vWind, wWind, i, j, k, baseDiffusivity, maxDiffusivity,
          );
          
          // 3. 计算平流项（使用 TVD 格式）
          final advection = _calculateMoistureAdvection(
            qvapor, u, v, w, i, j, k,
          );
          
          // 4. 计算扩散项
          final diffusion = _calculateMoistureDiffusion(
            qvapor, localDiffusivity, i, j, k,
          );
          
          // 5. 对流触发机制
          final convection = _calculateConvectionSource(
            q, temp, press, w, i, j, k,
          );
          
          // 6. 蒸发/凝结源项
          final phaseChange = _calculatePhaseChange(
            q, temp, press, i, j, k,
          );
          
          // 7. 时间步进更新
          newQvapor[k][j][i] = q + _dt * (advection + diffusion + convection + phaseChange);
          
          // 8. 物理约束
          newQvapor[k][j][i] = _applyMoistureConstraints(
            newQvapor[k][j][i], temp, press,
          );
        }
      }
    }
    
    // 应用边界条件
    _applyMoistureBoundaryConditions(newQvapor);
    
    // 更新水汽场
    _copyGridData(newQvapor, qvapor);
  }
  
  /// 计算局地扩散系数
  double _calculateLocalDiffusivity(
    List<List<List<double>>> uWind,
    List<List<List<double>>> vWind,
    List<List<List<double>>> wWind,
    int i, int j, int k,
    double baseDiffusivity,
    double maxDiffusivity,
  ) {
    // 计算风切变
    final dudx = (uWind[k][j][i+1] - uWind[k][j][i-1]) / (2 * _dx);
    final dudy = (uWind[k][j+1][i] - uWind[k][j-1][i]) / (2 * _dy);
    final dudz = (uWind[k+1][j][i] - uWind[k-1][j][i]) / (2 * _dz);
    
    final dvdx = (vWind[k][j][i+1] - vWind[k][j][i-1]) / (2 * _dx);
    final dvdy = (vWind[k][j+1][i] - vWind[k][j-1][i]) / (2 * _dy);
    final dvdz = (vWind[k+1][j][i] - vWind[k-1][j][i]) / (2 * _dz);
    
    final dwdx = (wWind[k][j][i+1] - wWind[k][j][i-1]) / (2 * _dx);
    final dwdy = (wWind[k][j+1][i] - wWind[k][j-1][i]) / (2 * _dy);
    final dwdz = (wWind[k+1][j][i] - wWind[k-1][j][i]) / (2 * _dz);
    
    // 变形张量
    final shear = sqrt(2 * (dudx*dudx + dvdy*dvdy + dwdz*dwdz) +
                     (dudy + dvdx)*(dudy + dvdx) +
                     (dudz + dwdx)*(dudz + dwdx) +
                     (dvdz + dwdy)*(dvdz + dwdy));
    
    // Smagorinsky 混合长度模型
    const mixingLength = 100.0; // m
    final turbulentDiffusivity = mixingLength * mixingLength * shear;
    
    return min(maxDiffusivity, baseDiffusivity + turbulentDiffusivity);
  }
  
  /// 计算水汽平流（TVD 格式）
  double _calculateMoistureAdvection(
    List<List<List<double>>> qvapor,
    double u, double v, double w,
    int i, int j, int k,
  ) {
    final q = qvapor[k][j][i];
    
    // 使用通量限制器的 TVD 格式
    final fluxX = _calculateFlux(qvapor, u, i, j, k, 'x');
    final fluxY = _calculateFlux(qvapor, v, i, j, k, 'y');
    final fluxZ = _calculateFlux(qvapor, w, i, j, k, 'z');
    
    return -(fluxX + fluxY + fluxZ);
  }
  
  /// 计算通量（带通量限制器）
  double _calculateFlux(
    List<List<List<double>>> qvapor,
    double velocity,
    int i, int j, int k,
    String direction,
  ) {
    double qUp, qDown, qCurrent;
    double dx;
    
    switch (direction) {
      case 'x':
        qCurrent = qvapor[k][j][i];
        qUp = velocity > 0 ? qvapor[k][j][i-1] : qvapor[k][j][i+1];
        qDown = velocity > 0 ? qvapor[k][j][i+1] : qvapor[k][j][i-1];
        dx = _dx;
        break;
      case 'y':
        qCurrent = qvapor[k][j][i];
        qUp = velocity > 0 ? qvapor[k][j-1][i] : qvapor[k][j+1][i];
        qDown = velocity > 0 ? qvapor[k][j+1][i] : qvapor[k][j-1][i];
        dx = _dy;
        break;
      case 'z':
        qCurrent = qvapor[k][j][i];
        qUp = velocity > 0 ? qvapor[k-1][j][i] : qvapor[k+1][j][i];
        qDown = velocity > 0 ? qvapor[k+1][j][i] : qvapor[k-1][j][i];
        dx = _dz;
        break;
      default:
        return 0.0;
    }
    
    // Van Leer 通量限制器
    final r = (qCurrent - qUp).abs() > 1e-10 ? 
              (qDown - qCurrent) / (qCurrent - qUp) : 0.0;
    
    final phi = r > 0 ? (r + abs(r)) / (1 + abs(r)) : 0.0;
    
    final gradient = (qDown - qUp) / (2 * dx);
    final limitedGradient = phi * gradient;
    
    return velocity * limitedGradient;
  }
  
  /// 计算水汽扩散
  double _calculateMoistureDiffusion(
    List<List<List<double>>> qvapor,
    double diffusivity,
    int i, int j, int k,
  ) {
    final q = qvapor[k][j][i];
    
    // 二阶中心差分
    final d2qdx2 = (qvapor[k][j][i+1] - 2*q + qvapor[k][j][i-1]) / (_dx * _dx);
    final d2qdy2 = (qvapor[k][j+1][i] - 2*q + qvapor[k][j-1][i]) / (_dy * _dy);
    final d2qdz2 = (qvapor[k+1][j][i] - 2*q + qvapor[k-1][j][i]) / (_dz * _dz);
    
    return diffusivity * (d2qdx2 + d2qdy2 + d2qdz2);
  }
  
  /// 计算对流源项
  double _calculateConvectionSource(
    double q, double temp, double press, double w,
    int i, int j, int k,
  ) {
    // 对流触发条件
    final relativeHumidity = _calculateRelativeHumidity(q, temp, press);
    final tempCelsius = temp - 273.15;
    
    // 条件1：高湿度和不稳定温度
    if (relativeHumidity > 0.85 && tempCelsius > 15.0) {
      // 浮力速度
      final buoyancy = 9.81 * (tempCelsius / temp);
      final convectiveVelocity = sqrt(max(0.0, 2.0 * 1000.0 * buoyancy));
      
      // 垂直水汽输送
      if (w < convectiveVelocity && k < _grid.nz - 1) {
        final moistureGradient = (qvapor[k+1][j][i] - q) / _dz;
        return -convectiveVelocity * moistureGradient * 0.1; // 对流效率因子
      }
    }
    
    return 0.0;
  }
  
  /// 计算相变源项
  double _calculatePhaseChange(
    double q, double temp, double press,
    int i, int j, int k,
  ) {
    final saturationMixingRatio = _calculateSaturationMixingRatio(temp, press);
    final relativeHumidity = q / saturationMixingRatio;
    
    // 凝结/蒸发率
    const phaseChangeRate = 0.001; // 1/s
    
    if (relativeHumidity > 1.0) {
      // 过饱和：凝结
      return -phaseChangeRate * (relativeHumidity - 1.0) * q;
    } else if (relativeHumidity < 0.8 && k == 0) {
      // 地面次饱和：蒸发
      return phaseChangeRate * (0.8 - relativeHumidity) * saturationMixingRatio * 0.1;
    }
    
    return 0.0;
  }
  
  /// 计算相对湿度
  double _calculateRelativeHumidity(double q, double temp, double press) {
    final saturationMixingRatio = _calculateSaturationMixingRatio(temp, press);
    return saturationMixingRatio > 0 ? q / saturationMixingRatio : 0.0;
  }
  
  /// 应用水汽约束
  double _applyMoistureConstraints(double q, double temp, double press) {
    // 非负约束
    q = max(0.0, q);
    
    // 饱和约束（允许轻微过饱和）
    final saturationMixingRatio = _calculateSaturationMixingRatio(temp, press);
    q = min(q, saturationMixingRatio * 1.05);
    
    return q;
  }
  
  /// 检查扩散 CFL 条件
  bool _checkDiffusionCFL(
    List<List<List<double>>> uWind,
    List<List<List<double>>> vWind,
    List<List<List<double>>> wWind,
  ) {
    double maxWindSpeed = 0.0;
    
    for (int k = 0; k < _grid.nz; k++) {
      for (int j = 0; j < _grid.ny; j++) {
        for (int i = 0; i < _grid.nx; i++) {
          final speed = sqrt(
            uWind[k][j][i] * uWind[k][j][i] +
            vWind[k][j][i] * vWind[k][j][i] +
            wWind[k][j][i] * wWind[k][j][i],
          );
          maxWindSpeed = max(maxWindSpeed, speed);
        }
      }
    }
    
    // 平流 CFL
    final cflAdv = maxWindSpeed * _dt / min(_dx, min(_dy, _dz));
    
    // 扩散 CFL
    final cflDiff = _diffusivity * _dt / (min(_dx, min(_dy, _dz)) * min(_dx, min(_dy, _dz)));
    
    return cflAdv < 0.5 && cflDiff < 0.25;
  }
  
  /// 应用水汽边界条件
  void _applyMoistureBoundaryConditions(List<List<List<double>>> newQvapor) {
    final nx = _grid.nx;
    final ny = _grid.ny;
    final nz = _grid.nz;
    
    for (int k = 0; k < nz; k++) {
      for (int j = 0; j < ny; j++) {
        for (int i = 0; i < nx; i++) {
          // 侧边界：零梯度
          if (i == 0) newQvapor[k][j][i] = newQvapor[k][j][i+1];
          if (i == nx - 1) newQvapor[k][j][i] = newQvapor[k][j][i-1];
          if (j == 0) newQvapor[k][j][i] = newQvapor[k][j+1][i];
          if (j == ny - 1) newQvapor[k][j][i] = newQvapor[k][j-1][i];
          
          // 顶部边界：零梯度
          if (k == nz - 1) newQvapor[k][j][i] = newQvapor[k-1][j][i];
        }
      }
    }
  }
  
  /// 计算自适应扩散系数
  double _calculateAdaptiveDiffusivity(
    List<List<List<double>>> uWind,
    List<List<List<double>>> vWind,
    List<List<List<double>>> temperature,
    List<List<List<double>>> qvapor,
  ) {
    double richardsonNumberSum = 0.0;
    int count = 0;
    
    for (int k = 1; k < _grid.nz - 1; k++) {
      for (int j = 1; j < _grid.ny - 1; j++) {
        for (int i = 1; i < _grid.nx - 1; i++) {
          // 计算风切变
          final duDz = (uWind[k+1][j][i] - uWind[k-1][j][i]) / (2 * _dz);
          final dvDz = (vWind[k+1][j][i] - vWind[k-1][j][i]) / (2 * _dz);
          final shearSquared = duDz * duDz + dvDz * dvDz;
          
          // 计算温度梯度
          final dThetaDz = _calculatePotentialTemperatureGradient(
            temperature, k, j, i
          );
          
          // Richardson 数
          final g = 9.81;
          final theta = MathUtils.potentialTemperature(
            temperature[k][j][i], 101325.0
          );
          
          double richardsonNumber;
          if (shearSquared > 1e-10) {
            richardsonNumber = (g / theta) * dThetaDz / shearSquared;
          } else {
            richardsonNumber = 10.0; // 稳定
          }
          
          richardsonNumberSum += richardsonNumber;
          count++;
        }
      }
    }
    
    final avgRichardsonNumber = richardsonNumberSum / count;
    
    // 根据 Richardson 数调整扩散系数
    if (avgRichardsonNumber < 0.25) {
      // 不稳定：增强扩散
      return _diffusivity * 3.0;
    } else if (avgRichardsonNumber > 1.0) {
      // 稳定：减弱扩散
      return _diffusivity * 0.3;
    } else {
      // 中性：标准扩散
      return _diffusivity;
    }
  }
  
  /// 计算位温梯度
  double _calculatePotentialTemperatureGradient(
    List<List<List<double>>> temperature,
    int k, int j, int i,
  ) {
    final thetaK = MathUtils.potentialTemperature(temperature[k][j][i], 101325.0);
    final thetaKMinus1 = MathUtils.potentialTemperature(temperature[k-1][j][i], 101325.0);
    final thetaKPlus1 = MathUtils.potentialTemperature(temperature[k+1][j][i], 101325.0);
    
    return (thetaKPlus1 - thetaKMinus1) / (2 * _dz);
  }
  
  /// 计算水汽平流（TVD 格式）
  double _calculateVaporAdvection(
    List<List<List<double>>> qvapor,
    double u, double v, double w,
    int i, int j, int k,
  ) {
    final q = qvapor[k][j][i];
    
    // 使用通量限制器的 TVD 格式
    final fluxX = _calculateTVDFlux(qvapor, u, i, j, k, 'x');
    final fluxY = _calculateTVDFlux(qvapor, v, i, j, k, 'y');
    final fluxZ = _calculateTVDFlux(qvapor, w, i, j, k, 'z');
    
    return -(fluxX + fluxY + fluxZ);
  }
  
  /// 计算 TVD 通量
  double _calculateTVDFlux(
    List<List<List<double>>> qvapor,
    double velocity,
    int i, int j, int k,
    String direction,
  ) {
    double qUp, qDown, qUpUp, qDownDown;
    double dx;
    
    switch (direction) {
      case 'x':
        qUp = qvapor[k][j][i-1];
        qDown = qvapor[k][j][i];
        qUpUp = qvapor[k][j][i-2];
        qDownDown = qvapor[k][j][i+1];
        dx = _dx;
        break;
      case 'y':
        qUp = qvapor[k][j-1][i];
        qDown = qvapor[k][j][i];
        qUpUp = qvapor[k][j-2][i];
        qDownDown = qvapor[k][j+1][i];
        dx = _dy;
        break;
      case 'z':
        qUp = qvapor[k-1][j][i];
        qDown = qvapor[k][j][i];
        qUpUp = qvapor[k-2][j][i];
        qDownDown = qvapor[k+1][j][i];
        dx = _dz;
        break;
      default:
        return 0.0;
    }
    
    // Minmod 通量限制器
    final r1 = (qDown - qUp) / (qUp - qUpUp + 1e-10);
    final r2 = (qDownDown - qDown) / (qDown - qUp + 1e-10);
    
    final phi = _minmodLimiter(r1, r2);
    
    final limitedGradient = phi * (qDown - qUp) / dx;
    
    return velocity * limitedGradient;
  }
  
  /// Minmod 通量限制器
  double _minmodLimiter(double r1, double r2) {
    if (r1 <= 0 || r2 <= 0) return 0.0;
    return min(r1, r2);
  }
  
  /// 计算水汽扩散
  double _calculateVaporDiffusion(
    List<List<List<double>>> qvapor,
    double diffusivity,
    int i, int j, int k,
  ) {
    // 各向异性扩散系数
    final kx = diffusivity;
    final ky = diffusivity;
    final kz = diffusivity * 0.1; // 垂直扩散较弱
    
    final center = qvapor[k][j][i];
    
    // 二阶中心差分
    final d2qdx2 = (qvapor[k][j][i+1] - 2 * center + qvapor[k][j][i-1]) / (_dx * _dx);
    final d2qdy2 = (qvapor[k][j+1][i] - 2 * center + qvapor[k][j-1][i]) / (_dy * _dy);
    final d2qdz2 = (qvapor[k+1][j][i] - 2 * center + qvapor[k-1][j][i]) / (_dz * _dz);
    
    return kx * d2qdx2 + ky * d2qdy2 + kz * d2qdz2;
  }
  
  /// 计算对流输送
  double _calculateConvectionTransport(
    List<List<List<double>>> qvapor,
    List<List<List<double>>> temperature,
    List<List<List<double>>> pressure,
    List<List<List<double>>> wWind,
    int i, int j, int k,
  ) {
    final q = qvapor[k][j][i];
    final temp = temperature[k][j][i];
    final press = pressure[k][j][i];
    final w = wWind[k][j][i];
    
    // 计算对流有效位能
    final cape = _calculateCAPE(temperature, pressure, i, j);
    
    // 对流触发条件
    if (cape > 100 && w > 0.5 && temp > 273.15) {
      // 对流速度
      final convectionVelocity = sqrt(2 * cape);
      
      // 水汽垂直输送
      if (k < _grid.nz - 1) {
        final dqdz = (qvapor[k+1][j][i] - q) / _dz;
        return -convectionVelocity * dqdz * 0.1; // 对流效率因子
      }
    }
    
    return 0.0;
  }
  
  /// 计算对流有效位能（简化）
  double _calculateCAPE(
    List<List<List<double>>> temperature,
    List<List<List<double>>> pressure,
    int i, int j,
  ) {
    // 简化的 CAPE 计算
    final surfaceTemp = temperature[0][j][i];
    final surfacePressure = pressure[0][j][i];
    
    // 假设抬升到 500 hPa
    final targetPressure = 50000.0;
    
    // 计算平均温度差
    double tempDifference = 0.0;
    for (int k = 0; k < _grid.nz && pressure[k][j][i] > targetPressure; k++) {
      final buoyancy = (temperature[k][j][i] - surfaceTemp) / surfaceTemp;
      tempDifference += buoyancy * _dz;
    }
    
    return max(0.0, 9.81 * tempDifference);
  }
  
  /// 计算水汽源汇项
  double _calculateVaporSourceSink(
    double q, double temp, double press,
    int i, int j, int k,
  ) {
    // 地面蒸发
    if (k == 0 && temp > 273.15) {
      final evaporationRate = 1e-6; // kg/(m²·s)
      final airDensity = press / (287.05 * temp);
      return evaporationRate / (airDensity * _dz);
    }
    
    // 高层凝结
    if (k > 5 && temp < 273.15) {
      final saturationRatio = q / _calculateSaturationMixingRatio(temp, press);
      if (saturationRatio > 0.95) {
        return -1e-5 * (saturationRatio - 0.95); // 凝结率
      }
    }
    
    return 0.0;
  }
  
  /// 应用水汽约束
  double _applyVaporConstraints(double q, double temp, double press) {
    // 非负约束
    q = max(0.0, q);
    
    // 饱和约束
    final saturationRatio = _calculateSaturationMixingRatio(temp, press);
    q = min(q, saturationRatio);
    
    // 最大值约束（避免数值不稳定）
    q = min(q, 0.05); // 最大 50 g/kg
    
    return q;
  }
  
  /// 应用水汽边界条件
  void _applyVaporBoundaryConditions(List<List<List<double>>> newQvapor) {
    final nx = _grid.nx;
    final ny = _grid.ny;
    final nz = _grid.nz;
    
    for (int k = 0; k < nz; k++) {
      for (int j = 0; j < ny; j++) {
        for (int i = 0; i < nx; i++) {
          // 侧边界：零梯度
          if (i == 0) newQvapor[k][j][i] = newQvapor[k][j][i+1];
          if (i == nx - 1) newQvapor[k][j][i] = newQvapor[k][j][i-1];
          if (j == 0) newQvapor[k][j][i] = newQvapor[k][j+1][i];
          if (j == ny - 1) newQvapor[k][j][i] = newQvapor[k][j-1][i];
          
          // 顶部边界：零梯度
          if (k == nz - 1) newQvapor[k][j][i] = newQvapor[k-1][j][i];
        }
      }
    }
  }
  
  /// 检查扩散 CFL 条件
  bool _checkDiffusionCFL(double diffusivity) {
    final cflNumber = diffusivity * _dt / (min(_dx, min(_dy, _dz)) * min(_dx, min(_dy, _dz)));
    return cflNumber < 0.25;
  }
  
  /// 检查对流触发条件
  double _checkConvectionTrigger(
    List<List<List<double>>> qvapor,
    List<List<List<double>>> temperature,
    List<List<List<double>>> pressure,
    int i, int j, int k,
  ) {
    // TODO: 集成 Gemini CLI 返回的对流触发机制
    
    final currentTemp = temperature[k][j][i];
    final currentPressure = pressure[k][j][i];
    final currentQvapor = qvapor[k][j][i];
    
    // 计算相对湿度
    final relativeHumidity = MathUtils.relativeHumidity(
      currentQvapor * currentPressure, currentTemp,
    );
    
    // 对流触发条件
    if (relativeHumidity > 0.95 && currentTemp > 273.15) {
      // 计算对流速度
      final buoyancy = 9.81 * (currentTemp - 273.15) / currentTemp;
      final verticalVelocity = sqrt(2 * 1000.0 * buoyancy); // 假设对流高度1000m
      
      // 对流引起的水汽垂直输送
      if (k < _grid.nz - 1) {
        final dqdz = (qvapor[k+1][j][i] - qvapor[k][j][i]) / _dz;
        return -verticalVelocity * dqdz;
      }
    }
    
    return 0.0;
  }
  
  /// 计算饱和水汽混合比
  double _calculateSaturationMixingRatio(double temperature, double pressure) {
    // 使用 Magnus 公式计算饱和水汽压
    final tempCelsius = temperature - 273.15;
    double es;
    
    if (tempCelsius >= 0) {
      es = 6.1078 * exp(17.27 * tempCelsius / (tempCelsius + 237.3));
    } else {
      es = 6.1078 * exp(21.875 * tempCelsius / (tempCelsius + 265.5));
    }
    
    // 转换为饱和水汽混合比
    return 0.622 * es * 100 / (pressure - es * 100);
  }
  
  /// 检查数值稳定性
  bool checkStability(List<List<List<double>>> uWind,
                      List<List<List<double>>> vWind,
                      List<List<List<double>>> wWind) {
    double maxWindSpeed = 0.0;
    
    for (int k = 0; k < _grid.nz; k++) {
      for (int j = 0; j < _grid.ny; j++) {
        for (int i = 0; i < _grid.nx; i++) {
          final speed = sqrt(
            uWind[k][j][i] * uWind[k][j][i] +
            vWind[k][j][i] * vWind[k][j][i] +
            wWind[k][j][i] * wWind[k][j][i],
          );
          maxWindSpeed = max(maxWindSpeed, speed);
        }
      }
    }
    
    // CFL条件
    final cflAdv = maxWindSpeed * _dt / min(_dx, min(_dy, _dz));
    
    // 扩散稳定性条件
    final cflDiff = _diffusivity * _dt / (min(_dx, min(_dy, _dz)) * min(_dx, min(_dy, _dz)));
    
    return cflAdv < 0.5 && cflDiff < 0.25;
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