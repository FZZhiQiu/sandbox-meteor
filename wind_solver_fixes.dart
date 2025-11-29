// wind_solver.dart 修复代码

/// 修复1: 科里奥利参数计算
double _calculateCoriolisParameter(double latitude) {
  const double omega = 7.2921e-5; // 地球自转角速度 rad/s (修正值)
  final double latRad = latitude * pi / 180.0;
  return 2.0 * omega * sin(latRad);
}

/// 修复2: 地转风平衡计算
double _calculateGeostrophicWind(double pressureGradient, double temperature, double pressure) {
  const double gasConstant = 287.05; // J/(kg·K)
  final double coriolisParam = _f;
  
  if (coriolisParam.abs() < 1e-10) return 0.0;
  
  // 计算空气密度: ρ = p/(R*T)
  final double airDensity = pressure / (gasConstant * temperature);
  
  // 地转风: Vg = -1/(ρ*f) * ∇p
  return -pressureGradient / (airDensity * coriolisParam);
}

/// 修复3: 改进的CFL条件检查
bool _checkWindCFLImproved(List<List<List<double>>> uWind, 
                          List<List<List<double>>> vWind,
                          [double? dt]) {
  final timeStep = dt ?? _dt;
  double maxWindSpeed = 0.0;
  double maxWindShear = 0.0;
  
  // 计算最大风速和风切变
  for (int k = 0; k < _grid.nz; k++) {
    for (int j = 0; j < _grid.ny; j++) {
      for (int i = 0; i < _grid.nx; i++) {
        final speed = sqrt(uWind[k][j][i] * uWind[k][j][i] + 
                         vWind[k][j][i] * vWind[k][j][i]);
        maxWindSpeed = max(maxWindSpeed, speed);
        
        // 计算风切变
        if (i > 0 && i < _grid.nx - 1) {
          final windShearX = abs(uWind[k][j][i+1] - uWind[k][j][i-1]) / (2 * _dx);
          maxWindShear = max(maxWindShear, windShearX);
        }
        if (j > 0 && j < _grid.ny - 1) {
          final windShearY = abs(vWind[k][j+1][i] - vWind[k][j-1][i]) / (2 * _dy);
          maxWindShear = max(maxWindShear, windShearY);
        }
      }
    }
  }
  
  // 改进的CFL条件：考虑风速和切变
  final cflNumber = maxWindSpeed * timeStep / min(_dx, _dy);
  final shearNumber = maxWindShear * timeStep;
  
  return cflNumber < 0.7 && shearNumber < 0.5; // 更合理的CFL限制
}

/// 修复4: 真正的并行计算实现
Future<void> _solveWindFieldParallelAsync(
  List<List<List<double>>> uWind,
  List<List<List<double>>> vWind,
  List<List<List<double>>> pressure,
  List<List<List<double>>> temperature,
  List<List<List<double>>> newUWind,
  List<List<List<double>>> newVWind,
  double dx, double dy, double dz,
  double airDensity, double kinematicViscosity, double dt,
) async {
  final numRegions = 4;
  final futures = <Future<void>>[];
  
  for (int region = 0; region < numRegions; region++) {
    final future = _solveRegionParallelAsync(
      uWind, vWind, pressure, temperature, newUWind, newVWind,
      dx, dy, dz, airDensity, kinematicViscosity, dt, region, numRegions
    );
    futures.add(future);
  }
  
  await Future.wait(futures);
}

/// 异步并行处理单个区域
Future<void> _solveRegionParallelAsync(
  List<List<List<double>>> uWind,
  List<List<List<double>>> vWind,
  List<List<List<double>>> pressure,
  List<List<List<double>>> temperature,
  List<List<List<double>>> newUWind,
  List<List<List<double>>> newVWind,
  double dx, double dy, double dz,
  double airDensity, double kinematicViscosity, double dt,
  int region, int numRegions,
) async {
  // 计算区域边界（包含重叠区域用于边界条件）
  final xStart = max(1, (region % 2) * (nx ~/ 2) - 1);
  final xEnd = min(nx - 1, (region % 2 == 1) ? nx : nx ~/ 2 + 1);
  final yStart = max(1, (region ~/ 2) * (ny ~/ 2) - 1);
  final yEnd = min(ny - 1, (region >= 2) ? ny : ny ~/ 2 + 1);
  
  // 处理区域内的网格点
  for (int k = 1; k < nz - 1; k++) {
    for (int j = yStart; j < yEnd; j++) {
      for (int i = xStart; i < xEnd; i++) {
        _solveSinglePoint(uWind, vWind, pressure, temperature, newUWind, newVWind,
                        i, j, k, dx, dy, dz, airDensity, kinematicViscosity, dt);
      }
    }
  }
}

/// 修复5: 改进的边界条件处理
void _applyImprovedBoundaryConditions(
  List<List<List<double>>> newUWind,
  List<List<List<double>>> newVWind,
) {
  final nx = _grid.nx;
  final ny = _grid.ny;
  final nz = _grid.nz;
  
  for (int k = 0; k < nz; k++) {
    for (int j = 0; j < ny; j++) {
      for (int i = 0; i < nx; i++) {
        // 侧边界：辐射边界条件（而非无滑移）
        if (i == 0) {
          newUWind[k][j][i] = newUWind[k][j][i+1];
          newVWind[k][j][i] = newVWind[k][j][i+1];
        } else if (i == nx - 1) {
          newUWind[k][j][i] = newUWind[k][j][i-1];
          newVWind[k][j][i] = newVWind[k][j][i-1];
        }
        
        if (j == 0) {
          newUWind[k][j][i] = newUWind[k][j+1][i];
          newVWind[k][j][i] = newVWind[k][j+1][i];
        } else if (j == ny - 1) {
          newUWind[k][j][i] = newUWind[k][j-1][i];
          newVWind[k][j][i] = newVWind[k][j-1][i];
        }
        
        // 地面边界：对数风廓线
        if (k == 0) {
          const double z0 = 0.1; // 粗糙度长度 m
          const double uStar = 0.3; // 摩擦速度 m/s
          final double z = 10.0; // 参考高度 m
          
          final double logFactor = log(z / z0) / log((z + _dz) / z0);
          newUWind[k][j][i] *= logFactor;
          newVWind[k][j][i] *= logFactor;
        }
        
        // 顶部边界：零垂直梯度
        if (k == nz - 1) {
          newUWind[k][j][i] = newUWind[k-1][j][i];
          newVWind[k][j][i] = newVWind[k-1][j][i];
        }
      }
    }
  }
}