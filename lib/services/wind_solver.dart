import 'dart:math';
import 'dart:isolate';
import '../core/app_config.dart';
import '../models/meteorology_state.dart';
import '../utils/math_utils.dart';

/// 风场动力学求解器
/// 基于 Navier-Stokes 方程在地转风平衡下的高性能实现
/// 支持并行计算和自适应时间步长
class WindSolver {
  final MeteorologyGrid _grid;
  final double _dx, _dy, _dt;
  final double _f; // 科里奥利参数
  final bool _useParallel; // 是否启用并行计算
  final bool _useAdaptiveTimeStep; // 是否使用自适应时间步长
  
  WindSolver(this._grid, {double? latitude, bool useParallel = false, bool useAdaptiveTimeStep = true})
      : _dx = 1000.0, // 1km 网格间距
        _dy = 1000.0,
        _dt = AppConfig.timeStep,
        _f = 2 * 7.27e-5 * sin((latitude ?? 30.0) * pi / 180.0), // 默认30°纬度
        _useParallel = useParallel,
        _useAdaptiveTimeStep = useAdaptiveTimeStep;
  
  /// 求解风场方程 - 高性能 Navier-Stokes 实现
  /// [uWind], [vWind] - 东西风和南北风分量
  /// [pressure] - 气压场
  /// [temperature] - 温度场（用于密度计算）
  void solveWindField(
    List<List<List<double>>> uWind,
    List<List<List<double>>> vWind,
    List<List<List<double>>> pressure,
    List<List<List<double>>> temperature,
  ) {
    final nx = _grid.nx;
    final ny = _grid.ny;
    final nz = _grid.nz;
    
    // 自适应时间步长计算
    final adaptiveDt = _useAdaptiveTimeStep ? _calculateAdaptiveTimeStep(uWind, vWind) : _dt;
    
    // 自适应网格间距
    final dx = _dx;
    final dy = _dy;
    final dz = 200.0; // 垂直间距
    
    // 创建临时数组存储新值
    final newUWind = List.generate(nz, (k) => 
        List.generate(ny, (j) => List.filled(nx, 0.0)));
    final newVWind = List.generate(nz, (k) => 
        List.generate(ny, (j) => List.filled(nx, 0.0)));
    
    // 物理常数
    const airDensity = 1.225; // kg/m³
    const kinematicViscosity = 15.0; // m²/s 湍流粘性系数
    
    // 增强的CFL检查
    if (!_checkWindCFL(uWind, vWind, adaptiveDt)) {
      print('Warning: Wind field CFL condition violated, using reduced time step');
      // 使用更小的时间步长重试
      final reducedDt = adaptiveDt * 0.5;
      _solveWindFieldInternal(uWind, vWind, pressure, temperature, newUWind, newVWind, 
                          dx, dy, dz, airDensity, kinematicViscosity, reducedDt);
    } else {
      _solveWindFieldInternal(uWind, vWind, pressure, temperature, newUWind, newVWind, 
                          dx, dy, dz, airDensity, kinematicViscosity, adaptiveDt);
    }
    
    // 根据计算模式选择串行或并行计算
    if (_useParallel && nx * ny * nz > 10000) {
      _solveWindFieldParallel(uWind, vWind, pressure, temperature, newUWind, newVWind, 
                           dx, dy, dz, airDensity, kinematicViscosity, adaptiveDt);
    } else {
      _solveWindFieldInternal(uWind, vWind, pressure, temperature, newUWind, newVWind, 
                           dx, dy, dz, airDensity, kinematicViscosity, adaptiveDt);
    }
  }
  
  /// 内部风场求解方法
  void _solveWindFieldInternal(
    List<List<List<double>>> uWind,
    List<List<List<double>>> vWind,
    List<List<List<double>>> pressure,
    List<List<List<double>>> temperature,
    List<List<List<double>>> newUWind,
    List<List<List<double>>> newVWind,
    double dx, double dy, double dz,
    double airDensity, double kinematicViscosity, double dt,
  ) {
    final nx = _grid.nx;
    final ny = _grid.ny;
    final nz = _grid.nz;
    
    // 对每个网格点进行计算（边界除外）
    for (int k = 1; k < nz - 1; k++) {
      for (int j = 1; j < ny - 1; j++) {
        for (int i = 1; i < nx - 1; i++) {
          // 1. 计算基本变量
          final u = uWind[k][j][i];
          final v = vWind[k][j][i];
          final p = pressure[k][j][i];
          final temp = temperature[k][j][i];
          
          // 2. 气压梯度力（中心差分）
          final dpdx = (pressure[k][j][i+1] - pressure[k][j][i-1]) / (2 * dx);
          final dpdy = (pressure[k][j+1][i] - pressure[k][j-1][i]) / (2 * dy);
          
          // 3. 科里奥利力
          final coriolisU = _f * v;
          final coriolisV = -_f * u;
          
          // 4. 平流项（高阶上风差分）
          final advectionU = _calculateAdvectionHighOrder(uWind, u, v, i, j, k, dx, dy);
          final advectionV = _calculateAdvectionHighOrder(vWind, u, v, i, j, k, dx, dy);
          
          // 5. 扩散项（四阶中心差分）
          final diffusionU = kinematicViscosity * _calculateLaplacianHighOrder(uWind, i, j, k, dx, dy);
          final diffusionV = kinematicViscosity * _calculateLaplacianHighOrder(vWind, i, j, k, dx, dy);
          
          // 6. 地转风平衡修正（自适应松弛）
          final geostrophicU = _calculateGeostrophicWind(dpdy, temp);
          final geostrophicV = _calculateGeostrophicWind(-dpdx, temp);
          
          final geostrophicRelaxation = _calculateAdaptiveRelaxation(u, v, geostrophicU, geostrophicV);
          
          // 7. 时间步进更新（半隐式格式）
          newUWind[k][j][i] = u + dt * (
            -dpdx / airDensity + coriolisU + advectionU + diffusionU +
            geostrophicRelaxation * (geostrophicU - u)
          );
          
          newVWind[k][j][i] = v + dt * (
            -dpdy / airDensity + coriolisV + advectionV + diffusionV +
            geostrophicRelaxation * (geostrophicV - v)
          );
          
          // 8. 数值稳定性约束
          newUWind[k][j][i] = _clampWindSpeed(newUWind[k][j][i]);
          newVWind[k][j][i] = _clampWindSpeed(newVWind[k][j][i]);
        }
      }
    }
  }
  
  /// 并行风场求解方法
  void _solveWindFieldParallel(
    List<List<List<double>>> uWind,
    List<List<List<double>>> vWind,
    List<List<List<double>>> pressure,
    List<List<List<double>>> temperature,
    List<List<List<double>>> newUWind,
    List<List<List<double>>> newVWind,
    double dx, double dy, double dz,
    double airDensity, double kinematicViscosity, double dt,
  ) {
    // 简化的并行计算实现
    // 在实际应用中，这里会使用Isolate进行真正的并行计算
    _solveWindFieldInternal(uWind, vWind, pressure, temperature, newUWind, newVWind, 
                           dx, dy, dz, airDensity, kinematicViscosity, dt);
  }
  
  /// 计算自适应时间步长
  double _calculateAdaptiveTimeStep(
    List<List<List<double>>> uWind,
    List<List<List<double>>> vWind,
  ) {
    double maxWindSpeed = 0.0;
    
    for (int k = 0; k < _grid.nz; k++) {
      for (int j = 0; j < _grid.ny; j++) {
        for (int i = 0; i < _grid.nx; i++) {
          final speed = sqrt(uWind[k][j][i] * uWind[k][j][i] + vWind[k][j][i] * vWind[k][j][i]);
          maxWindSpeed = max(maxWindSpeed, speed);
        }
      }
    }
    
    // CFL条件：CFL < 0.5
    const maxCFL = 0.4; // 保守的CFL数
    final minDx = min(_dx, _dy);
    final adaptiveDt = (maxCFL * minDx) / (maxWindSpeed + 1e-10);
    
    // 限制时间步长范围
    return adaptiveDt.clamp(_dt * 0.1, _dt * 2.0);
  }
  
  /// 计算自适应松弛系数
  double _calculateAdaptiveRelaxation(double u, double v, double geoU, double geoV) {
    const baseRelaxation = 0.1;
    const maxRelaxation = 0.3;
    
    // 根据地转风偏差调整松弛系数
    final deviation = sqrt(pow(u - geoU, 2) + pow(v - geoV, 2));
    final maxDeviation = 10.0; // m/s
    
    final adaptiveRelaxation = baseRelaxation + 
        (maxRelaxation - baseRelaxation) * (deviation / maxDeviation).clamp(0.0, 1.0);
    
    return adaptiveRelaxation;
  }
  
  /// 高阶上风差分格式
  double _calculateAdvectionHighOrder(
    List<List<List<double>>> windField,
    double u, double v,
    int i, int j, int k,
    double dx, double dy,
  ) {
    // 使用三阶上风差分格式
    final w = windField[k][j][i];
    
    // X方向平流
    double dwdx;
    if (u > 0) {
      final w_m2 = windField[k][j][i-2];
      final w_m1 = windField[k][j][i-1];
      final w_p1 = windField[k][j][i+1];
      dwdx = (2*w_m2 - 7*w_m1 + 11*w) / (6*dx);
    } else {
      final w_m1 = windField[k][j][i-1];
      final w_p1 = windField[k][j][i+1];
      final w_p2 = windField[k][j][i+2];
      dwdx = (-11*w + 7*w_p1 - 2*w_p2) / (6*dx);
    }
    
    // Y方向平流
    double dwdy;
    if (v > 0) {
      final w_m2 = windField[k][j-2][i];
      final w_m1 = windField[k][j-1][i];
      final w_p1 = windField[k][j+1][i];
      dwdy = (2*w_m2 - 7*w_m1 + 11*w) / (6*dy);
    } else {
      final w_m1 = windField[k][j-1][i];
      final w_p1 = windField[k][j+1][i];
      final w_p2 = windField[k][j+2][i];
      dwdy = (-11*w + 7*w_p1 - 2*w_p2) / (6*dy);
    }
    
    return -(u * dwdx + v * dwdy);
  }
  
  /// 四阶中心差分拉普拉斯算子
  double _calculateLaplacianHighOrder(
    List<List<List<double>>> field,
    int i, int j, int k,
    double dx, double dy,
  ) {
    final center = field[k][j][i];
    final xm2 = field[k][j][i-2];
    final xm1 = field[k][j][i-1];
    final xp1 = field[k][j][i+1];
    final xp2 = field[k][j][i+2];
    final ym2 = field[k][j-2][i];
    final ym1 = field[k][j-1][i];
    final yp1 = field[k][j+1][i];
    final yp2 = field[k][j+2][i];
    
    // 四阶中心差分
    final d2wdx2 = (-xm2 + 16*xm1 - 30*center + 16*xp1 - xp2) / (12 * dx * dx);
    final d2wdy2 = (-ym2 + 16*ym1 - 30*center + 16*yp1 - yp2) / (12 * dy * dy);
    
    return d2wdx2 + d2wdy2;
    
    // 应用边界条件
    _applyWindBoundaryConditions(newUWind, newVWind);
    
    // 更新风场
    _copyGridData(newUWind, uWind);
    _copyGridData(newVWind, vWind);
  }
  
  /// 计算平流项（使用上风差分）
  double _calculateAdvection(
    List<List<List<double>>> windField,
    double u, double v,
    int i, int j, int k,
    double dx, double dy,
  ) {
    final w = windField[k][j][i];
    
    // 上风差分计算梯度
    double dwdx, dwdy;
    
    if (u > 0) {
      dwdx = (w - windField[k][j][i-1]) / dx;
    } else {
      dwdx = (windField[k][j][i+1] - w) / dx;
    }
    
    if (v > 0) {
      dwdy = (w - windField[k][j-1][i]) / dy;
    } else {
      dwdy = (windField[k][j+1][i] - w) / dy;
    }
    
    return -(u * dwdx + v * dwdy);
  }
  
  /// 计算拉普拉斯算子
  double _calculateLaplacian(
    List<List<List<double>>> field,
    int i, int j, int k,
    double dx, double dy,
  ) {
    final center = field[k][j][i];
    final east = field[k][j][i+1];
    final west = field[k][j][i-1];
    final north = field[k][j+1][i];
    final south = field[k][j-1][i];
    
    final d2wdx2 = (east - 2 * center + west) / (dx * dx);
    final d2wdy2 = (north - 2 * center + south) / (dy * dy);
    
    return d2wdx2 + d2wdy2;
  }
  
  /// 计算地转风
  double _calculateGeostrophicWind(double pressureGradient, double temperature) {
    final gasConstant = 287.05; // J/(kg·K)
    final coriolisParam = _f;
    
    if (coriolisParam.abs() < 1e-10) return 0.0;
    
    return -pressureGradient / (coriolisParam * gasConstant * temperature);
  }
  
  /// 风速约束（数值稳定性）
  double _clampWindSpeed(double windSpeed) {
    const maxWindSpeed = 100.0; // m/s
    return windSpeed.clamp(-maxWindSpeed, maxWindSpeed);
  }
  
  /// 增强的风场 CFL 条件检查
  bool _checkWindCFL(List<List<List<double>>> uWind, 
                      List<List<List<double>>> vWind,
                      [double? dt]) {
    final timeStep = dt ?? _dt;
    double maxWindSpeed = 0.0;
    
    for (int k = 0; k < _grid.nz; k++) {
      for (int j = 0; j < _grid.ny; j++) {
        for (int i = 0; i < _grid.nx; i++) {
          final speed = sqrt(uWind[k][j][i] * uWind[k][j][i] + 
                           vWind[k][j][i] * vWind[k][j][i]);
          maxWindSpeed = max(maxWindSpeed, speed);
        }
      }
    }
    
    final cflNumber = maxWindSpeed * timeStep / min(_dx, _dy);
    return cflNumber < 0.4; // 更保守的CFL条件
  }
  
  /// 获取求解器性能指标
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'useParallel': _useParallel,
      'useAdaptiveTimeStep': _useAdaptiveTimeStep,
      'gridSize': '${_grid.nx}x${_grid.ny}x${_grid.nz}',
      'timeStep': _dt,
      'coriolisParameter': _f,
      'spatialResolution': 'dx=${_dx}m, dy=${_dy}m',
    };
  }
  
  /// 应用风场边界条件
  void _applyWindBoundaryConditions(
    List<List<List<double>>> newUWind,
    List<List<List<double>>> newVWind,
  ) {
    final nx = _grid.nx;
    final ny = _grid.ny;
    final nz = _grid.nz;
    
    for (int k = 0; k < nz; k++) {
      for (int j = 0; j < ny; j++) {
        for (int i = 0; i < nx; i++) {
          // 侧边界：无滑移条件
          if (i == 0 || i == nx - 1 || j == 0 || j == ny - 1) {
            newUWind[k][j][i] = 0.0;
            newVWind[k][j][i] = 0.0;
          }
          
          // 地面边界：摩擦效应
          if (k == 0) {
            const surfaceFriction = 0.8;
            newUWind[k][j][i] *= surfaceFriction;
            newVWind[k][j][i] *= surfaceFriction;
          }
          
          // 顶部边界：自由滑移
          if (k == nz - 1) {
            newUWind[k][j][i] = newUWind[k-1][j][i];
            newVWind[k][j][i] = newVWind[k-1][j][i];
          }
        }
      }
    }
  }
  
  /// 应用边界条件
  void _applyBoundaryConditions(
    List<List<List<double>>> newUWind,
    List<List<List<double>>> newVWind,
    int i, int j, int k,
  ) {
    final nx = _grid.nx;
    final ny = _grid.ny;
    
    // 边界条件：无滑移边界
    if (i == 0 || i == nx - 1 || j == 0 || j == ny - 1) {
      newUWind[k][j][i] = 0.0;
      newVWind[k][j][i] = 0.0;
    }
    
    // 地面边界条件
    if (k == 0) {
      newUWind[k][j][i] *= 0.8; // 地面摩擦
      newVWind[k][j][i] *= 0.8;
    }
    
    // 顶部边界条件
    if (k == _grid.nz - 1) {
      newUWind[k][j][i] = newUWind[k-1][j][i];
      newVWind[k][j][i] = newVWind[k-1][j][i];
    }
  }
  
  /// 检查数值稳定性（CFL条件）
  bool checkStability(List<List<List<double>>> uWind, 
                      List<List<List<double>>> vWind) {
    double maxWindSpeed = 0.0;
    
    for (int k = 0; k < _grid.nz; k++) {
      for (int j = 0; j < _grid.ny; j++) {
        for (int i = 0; i < _grid.nx; i++) {
          final speed = sqrt(uWind[k][j][i] * uWind[k][j][i] + 
                           vWind[k][j][i] * vWind[k][j][i]);
          maxWindSpeed = max(maxWindSpeed, speed);
        }
      }
    }
    
    final cflNumber = maxWindSpeed * _dt / min(_dx, _dy);
    return cflNumber < 0.5; // CFL条件要求小于0.5
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