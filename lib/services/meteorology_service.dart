import 'dart:async';
import 'dart:math';
import 'package:vector_math/vector_math.dart';

import '../core/app_config.dart';
import '../models/meteorology_state.dart';
import 'wind_solver.dart';
import 'diffusion_service.dart';
import 'precipitation_solver.dart';
import 'fronts_solver.dart';
import 'radiation_solver.dart';
import 'boundary_layer_solver.dart';

// 集成的气象求解器系统
// 每个求解器都预留了 Gemini CLI 算法集成接口

class MeteorologyService {
  MeteorologyGrid? _currentGrid;
  Timer? _simulationTimer;
  
  // 各物理过程求解器
  late WindSolver _windSolver;
  late DiffusionService _diffusionService;
  late PrecipitationSolver _precipitationSolver;
  late FrontsSolver _frontsSolver;
  late RadiationSolver _radiationSolver;
  late BoundaryLayerSolver _boundaryLayerSolver;
  
  // 云水场（需要初始化）
  List<List<List<double>>>? _qcloud;
  List<List<List<double>>>? _qrain;
  
  // 初始化气象网格
  MeteorologyGrid initializeGrid() {
    final grid = MeteorologyGrid(
      nx: AppConfig.gridNX,
      ny: AppConfig.gridNY,
      nz: AppConfig.gridNZ,
    );
    
    // 设置初始大气条件
    _initializeAtmosphericConditions(grid);
    
    // 初始化求解器
    _windSolver = WindSolver(grid);
    _diffusionService = DiffusionService(grid);
    _precipitationSolver = PrecipitationSolver(grid);
    _frontsSolver = FrontsSolver(grid);
    _radiationSolver = RadiationSolver(grid);
    _boundaryLayerSolver = BoundaryLayerSolver(grid);
    
    // 初始化云水和雨水场
    _initializeWaterFields(grid);
    
    _currentGrid = grid;
    return grid;
  }
  
  // 初始化水物质场
  void _initializeWaterFields(MeteorologyGrid grid) {
    final nx = grid.nx;
    final ny = grid.ny;
    final nz = grid.nz;
    
    _qcloud = List.generate(nz, (k) => 
        List.generate(ny, (j) => List.filled(nx, 0.0)));
    _qrain = List.generate(nz, (k) => 
        List.generate(ny, (j) => List.filled(nx, 0.0));
    
    // 初始化少量云水
    for (int k = 1; k < nz; k++) {
      for (int j = 0; j < ny; j++) {
        for (int i = 0; i < nx; i++) {
          final height = k * 200.0; // 200m per level
          if (height > 1000 && height < 5000) { // 云层高度范围
            _qcloud![k][j][i] = 0.0001; // 0.1 g/kg
          }
        }
      }
    }
  }
  
  // 初始化大气条件
  void _initializeAtmosphericConditions(MeteorologyGrid grid) {
    for (int k = 0; k < AppConfig.gridNZ; k++) {
      for (int j = 0; j < AppConfig.gridNY; j++) {
        for (int i = 0; i < AppConfig.gridNX; i++) {
          // 初始温度廓线（随高度递减）
          final temperature = AppConfig.standardTemperature - k * 6.5;
          grid.setValue(MeteorologyVariable.temperature, i, j, k, temperature);
          
          // 初始气压廓线（气压公式）
          final pressure = AppConfig.standardPressure * 
              exp(-k * 200.0 * AppConfig.gravity / (AppConfig.gasConstant * AppConfig.standardTemperature));
          grid.setValue(MeteorologyVariable.pressure, i, j, k, pressure);
          
          // 初始水汽（随高度递减）
          final qvapor = 0.01 * (1.0 - k * 0.02);
          grid.setValue(MeteorologyVariable.qvapor, i, j, k, qvapor);
          
          // 初始风场
          grid.setValue(MeteorologyVariable.uWind, i, j, k, 2.0 + (i % 50) * 0.01);
          grid.setValue(MeteorologyVariable.vWind, i, j, k, 1.0 + (j % 50) * 0.005);
          grid.setValue(MeteorologyVariable.wWind, i, j, k, 0.0);
          
          // 初始湿度
          final humidity = min(0.95, qvapor * 100.0);
          grid.setValue(MeteorologyVariable.humidity, i, j, k, humidity);
        }
      }
    }
  }
  
  // 开始模拟
  void startSimulation(Function(MeteorologyState) onUpdate) {
    if (_currentGrid == null) {
      initializeGrid();
    }
    
    _simulationTimer = Timer.periodic(
      Duration(seconds: AppConfig.simulationInterval),
      (timer) => _updateSimulation(onUpdate),
    );
  }
  
  // 停止模拟
  void stopSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
  }
  
  // 更新模拟状态
  void _updateSimulation(Function(MeteorologyState) onUpdate) {
    if (_currentGrid == null) return;
    
    // 获取当前网格数据
    final grid = _currentGrid!;
    final temperature = grid.getVariableData(MeteorologyVariable.temperature)!;
    final pressure = grid.getVariableData(MeteorologyVariable.pressure)!;
    final qvapor = grid.getVariableData(MeteorologyVariable.qvapor)!;
    final uWind = grid.getVariableData(MeteorologyVariable.uWind)!;
    final vWind = grid.getVariableData(MeteorologyVariable.vWind)!;
    final wWind = grid.getVariableData(MeteorologyVariable.wWind)!;
    final humidity = grid.getVariableData(MeteorologyVariable.humidity)!;
    
    // 1. 风场动力学求解
    if (!_windSolver.checkStability(uWind, vWind)) {
      print('Warning: Wind field stability check failed');
    }
    _windSolver.solveWindField(uWind, vWind, pressure, temperature);
    
    // 2. 水汽扩散和对流
    if (!_diffusionService.checkStability(uWind, vWind, wWind)) {
      print('Warning: Diffusion stability check failed');
    }
    _diffusionService.solveDiffusion(qvapor, uWind, vWind, wWind, temperature, pressure);
    
    // 3. 降水过程（Kessler微物理方案）
    if (!_precipitationSolver.checkStability(qvapor, _qcloud!, _qrain!)) {
      print('Warning: Precipitation stability check failed');
    }
    _precipitationSolver.solvePrecipitation(
      qvapor, _qcloud!, _qrain!, temperature, pressure, wWind,
    );
    
    // 4. 锋面动力学
    if (!_frontsSolver.checkStability()) {
      print('Warning: Fronts stability check failed');
    }
    _frontsSolver.solveFrontDynamics(temperature, humidity, uWind, vWind, pressure);
    
    // 5. 辐射传输过程
    final hour = DateTime.now().hour;
    if (!_radiationSolver.checkStability(temperature)) {
      print('Warning: Radiation stability check failed');
    }
    _radiationSolver.solveRadiation(temperature, humidity, _qcloud!, pressure, hour);
    
    // 6. 边界层湍流过程
    if (!_boundaryLayerSolver.checkStability(
          grid.getVariableData(MeteorologyVariable.uWind)!,
          grid.getVariableData(MeteorologyVariable.vWind)!,
          grid.getVariableData(MeteorologyVariable.wWind)!,
        )) {
      print('Warning: Boundary layer stability check failed');
    }
    _boundaryLayerSolver.solveBoundaryLayer(
      uWind, vWind, wWind, temperature, humidity, pressure,
    );
    
    // 7. 更新湿度场
    _updateHumidityField();
    
    final state = MeteorologyState(
      grid: _currentGrid!,
      timestamp: DateTime.now(),
      isSimulating: true,
    );
    
    onUpdate(state);
  }
  
  // 更新湿度场
  void _updateHumidityField() {
    if (_currentGrid == null) return;
    
    final grid = _currentGrid!;
    final temperature = grid.getVariableData(MeteorologyVariable.temperature)!;
    final pressure = grid.getVariableData(MeteorologyVariable.pressure)!;
    final qvapor = grid.getVariableData(MeteorologyVariable.qvapor)!;
    
    for (int k = 0; k < grid.nz; k++) {
      for (int j = 0; j < grid.ny; j++) {
        for (int i = 0; i < grid.nx; i++) {
          final temp = temperature[k][j][i];
          final press = pressure[k][j][i];
          final qv = qvapor[k][j][i];
          
          // 计算相对湿度
          final relativeHumidity = MathUtils.relativeHumidity(qv * press, temp);
          grid.setValue(MeteorologyVariable.humidity, i, j, k, relativeHumidity);
        }
      }
    }
  }
  
  // 获取锋面系统
  List<FrontSystem> getFrontSystems() {
    return _frontsSolver.getFrontSystems();
  }
  
  // 获取数值稳定性状态
  Map<String, bool> getStabilityStatus() {
    if (_currentGrid == null) return {};
    
    final grid = _currentGrid!;
    final uWind = grid.getVariableData(MeteorologyVariable.uWind)!;
    final vWind = grid.getVariableData(MeteorologyVariable.vWind)!;
    final wWind = grid.getVariableData(MeteorologyVariable.wWind)!;
    final temperature = grid.getVariableData(MeteorologyVariable.temperature)!;
    final qvapor = grid.getVariableData(MeteorologyVariable.qvapor)!;
    
    return {
      'wind': _windSolver.checkStability(uWind, vWind),
      'diffusion': _diffusionService.checkStability(uWind, vWind, wWind),
      'precipitation': _precipitationSolver.checkStability(qvapor, _qcloud!, _qrain!),
      'fronts': _frontsSolver.checkStability(),
      'radiation': _radiationSolver.checkStability(temperature),
      'boundary_layer': _boundaryLayerSolver.checkStability(uWind, vWind, wWind),
    };
  }
  
  // 获取当前状态
  MeteorologyState? getCurrentState() {
    if (_currentGrid == null) return null;
    
    return MeteorologyState(
      grid: _currentGrid!,
      timestamp: DateTime.now(),
      isSimulating: _simulationTimer?.isActive ?? false,
    );
  }
}

// 数学辅助函数
double exp(double x) {
  return math.exp(x);
}