import 'package:vector_math/vector_math.dart';

// 气象变量枚举
enum MeteorologyVariable {
  temperature,    // 温度
  pressure,       // 气压
  qvapor,        // 水汽
  uWind,         // 东西风
  vWind,         // 南北风
  wWind,         // 垂直风
  precipitation,  // 降水
  cloud,         // 云量
  humidity,      // 湿度
}

// 气象网格数据
class MeteorologyGrid {
  final int nx, ny, nz;
  final Map<MeteorologyVariable, List<List<List<double>>>> _data;
  
  MeteorologyGrid({
    required this.nx,
    required this.ny,
    required this.nz,
  }) : _data = {};
  
  // 获取指定变量的值
  double getValue(MeteorologyVariable variable, int i, int j, int k) {
    if (!_data.containsKey(variable)) {
      _initializeVariable(variable);
    }
    return _data[variable]![k][j][i];
  }
  
  // 设置指定变量的值
  void setValue(MeteorologyVariable variable, int i, int j, int k, double value) {
    if (!_data.containsKey(variable)) {
      _initializeVariable(variable);
    }
    _data[variable]![k][j][i] = value;
  }
  
  // 初始化变量数据
  void _initializeVariable(MeteorologyVariable variable) {
    _data[variable] = List.generate(
      nz,
      (k) => List.generate(
        ny,
        (j) => List.filled(nx, 0.0),
      ),
    );
  }
  
  // 获取整个变量的数据
  List<List<List<double>>>? getVariableData(MeteorologyVariable variable) {
    return _data[variable];
  }
}

// 气象系统状态
class MeteorologyState {
  final MeteorologyGrid grid;
  final DateTime timestamp;
  final bool isSimulating;
  final double simulationSpeed;
  
  const MeteorologyState({
    required this.grid,
    required this.timestamp,
    this.isSimulating = false,
    this.simulationSpeed = 1.0,
  });
  
  MeteorologyState copyWith({
    MeteorologyGrid? grid,
    DateTime? timestamp,
    bool? isSimulating,
    double? simulationSpeed,
  }) {
    return MeteorologyState(
      grid: grid ?? this.grid,
      timestamp: timestamp ?? this.timestamp,
      isSimulating: isSimulating ?? this.isSimulating,
      simulationSpeed: simulationSpeed ?? this.simulationSpeed,
    );
  }
}

// 锋面系统
class FrontSystem {
  final FrontType type;
  final List<Vector2> points;
  final double intensity;
  final DateTime timestamp;
  
  const FrontSystem({
    required this.type,
    required this.points,
    required this.intensity,
    required this.timestamp,
  });
}

enum FrontType {
  cold,   // 冷锋
  warm,   // 暖锋
  stationary, // 静止锋
}

// 气旋系统
class CycloneSystem {
  final Vector2 center;
  final double radius;
  final double pressure;
  final double maxWindSpeed;
  final List<Vector2> track;
  final DateTime timestamp;
  
  const CycloneSystem({
    required this.center,
    required this.radius,
    required this.pressure,
    required this.maxWindSpeed,
    required this.track,
    required this.timestamp,
  });
}