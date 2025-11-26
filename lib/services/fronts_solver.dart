import 'dart:math';
import 'package:vector_math/vector_math.dart';
import '../core/app_config.dart';
import '../models/meteorology_state.dart';
import '../utils/math_utils.dart';

/// 锋面动力学求解器
/// 实现锋生函数计算和锋面移动算法
class FrontsSolver {
  final MeteorologyGrid _grid;
  final double _dx, _dy, _dt;
  
  // 锋面识别参数
  final double _temperatureGradientThreshold; // 温度梯度阈值
  final double _humidityGradientThreshold;    // 湿度梯度阈值
  final double _windShearThreshold;           // 风切变阈值
  
  // 锋面系统列表
  List<FrontSystem> _frontSystems = [];
  
  FrontsSolver(this._grid)
      : _dx = 1000.0, // 1km 网格间距
        _dy = 1000.0,
        _dt = AppConfig.timeStep,
        _temperatureGradientThreshold = 5.0,  // 5°C/100km
        _humidityGradientThreshold = 20.0,    // 20%/100km
        _windShearThreshold = 5.0;            // 5m/s/100km
  
  /// 求解锋面动力学
  /// [temperature] - 温度场
  /// [humidity] - 湿度场
  /// [uWind], [vWind] - 风场分量
  /// [pressure] - 气压场
  void solveFrontDynamics(
    List<List<List<double>>> temperature,
    List<List<List<double>>> humidity,
    List<List<List<double>>> uWind,
    List<List<List<double>>> vWind,
    List<List<List<double>>> pressure,
  ) {
    // TODO: 集成 Gemini CLI 返回的锋面动力学算法
    
    // 1. 计算锋生函数场
    final frontogenesisField = _calculateFrontogenesisField(
      temperature, humidity, uWind, vWind,
    );
    
    // 2. 识别锋面位置
    final frontPositions = _identifyFrontPositions(frontogenesisField);
    
    // 3. 更新锋面系统
    _updateFrontSystems(frontPositions, uWind, vWind, pressure);
    
    // 4. 计算锋面移动
    _calculateFrontMovement(uWind, vWind);
    
    // 5. 应用锋面效应
    _applyFrontEffects(temperature, humidity, pressure);
  }
  
  /// 计算锋生函数场
  List<List<double>> _calculateFrontogenesisField(
    List<List<List<double>>> temperature,
    List<List<List<double>>> humidity,
    List<List<List<double>>> uWind,
    List<List<List<double>>> vWind,
  ) {
    final nx = _grid.nx;
    final ny = _grid.ny;
    final k = 0; // 地面层
    
    final frontogenesisField = List.generate(ny, (j) => List.filled(nx, 0.0));
    
    for (int j = 1; j < ny - 1; j++) {
      for (int i = 1; i < nx - 1; i++) {
        // 1. 计算温度梯度
        final dTdx = (temperature[k][j][i+1] - temperature[k][j][i-1]) / (2 * _dx);
        final dTdy = (temperature[k][j+1][i] - temperature[k][j-1][i]) / (2 * _dy);
        final tempGradient = sqrt(dTdx * dTdx + dTdy * dTdy);
        
        // 2. 计算湿度梯度
        final dHdx = (humidity[k][j][i+1] - humidity[k][j][i-1]) / (2 * _dx);
        final dHdy = (humidity[k][j+1][i] - humidity[k][j-1][i]) / (2 * _dy);
        final humidityGradient = sqrt(dHdx * dHdx + dHdy * dHdy);
        
        // 3. 计算风切变
        final dUdx = (uWind[k][j][i+1] - uWind[k][j][i-1]) / (2 * _dx);
        final dUdy = (uWind[k][j+1][i] - uWind[k][j-1][i]) / (2 * _dy);
        final dVdx = (vWind[k][j][i+1] - vWind[k][j][i-1]) / (2 * _dx);
        final dVdy = (vWind[k][j+1][i] - vWind[k][j][i-1]) / (2 * _dy);
        
        final deformation = sqrt(pow(dUdx - dVdy, 2) + pow(dUdy + dVdx, 2));
        
        // 4. 计算锋生函数（简化版本）
        final frontogenesis = tempGradient * deformation / 100000.0 + // 温度锋生
                             humidityGradient * deformation / 100000.0; // 湿度锋生
        
        frontogenesisField[j][i] = frontogenesis;
      }
    }
    
    return frontogenesisField;
  }
  
  /// 识别锋面位置 - 改进的锋面追踪算法
  List<Vector2> _identifyFrontPositions(List<List<double>> frontogenesisField) {
    final nx = _grid.nx;
    final ny = _grid.ny;
    final frontPositions = <Vector2>[];
    
    // 自适应阈值（基于场统计）
    double threshold = _calculateAdaptiveThreshold(frontogenesisField);
    
    // 锋面核心点识别
    for (int j = 2; j < ny - 2; j++) {
      for (int i = 2; i < nx - 2; i++) {
        final value = frontogenesisField[j][i];
        
        if (value > threshold) {
          // 检查是否为局部最大值（3x3窗口）
          final isLocalMax = _isLocalMaximum(frontogenesisField, i, j, 1);
          
          if (isLocalMax) {
            // 锋面强度验证
            final intensity = _calculateFrontIntensity(frontogenesisField, i, j);
            
            if (intensity > threshold * 2.0) {
              frontPositions.add(Vector2(i.toDouble(), j.toDouble()));
            }
          }
        }
      }
    }
    
    // 锋面连接和过滤
    return _filterAndConnectFronts(frontPositions, frontogenesisField);
  }
  
  /// 计算自适应阈值
  double _calculateAdaptiveThreshold(List<List<double>> field) {
    double sum = 0.0;
    double sumSquares = 0.0;
    int count = 0;
    
    for (int j = 0; j < field.length; j++) {
      for (int i = 0; i < field[0].length; i++) {
        final value = field[j][i];
        sum += value;
        sumSquares += value * value;
        count++;
      }
    }
    
    final mean = sum / count;
    final stdDev = sqrt((sumSquares / count) - (mean * mean));
    
    // 使用均值 + 1.5 * 标准差作为阈值
    return mean + 1.5 * stdDev;
  }
  
  /// 检查是否为局部最大值
  bool _isLocalMaximum(List<List<double>> field, int i, int j, int radius) {
    final centerValue = field[j][i];
    
    for (int dy = -radius; dy <= radius; dy++) {
      for (int dx = -radius; dx <= radius; dx++) {
        if (dx == 0 && dy == 0) continue;
        
        final ni = i + dx;
        final nj = j + dy;
        
        if (ni >= 0 && ni < field[0].length && nj >= 0 && nj < field.length) {
          if (field[nj][ni] >= centerValue) {
            return false;
          }
        }
      }
    }
    
    return true;
  }
  
  /// 计算锋面强度
  double _calculateFrontIntensity(List<List<double>> field, int i, int j) {
    // 使用 5x5 窗口计算锋面强度
    double intensity = 0.0;
    int count = 0;
    
    for (int dy = -2; dy <= 2; dy++) {
      for (int dx = -2; dx <= 2; dx++) {
        final ni = i + dx;
        final nj = j + dy;
        
        if (ni >= 0 && ni < field[0].length && nj >= 0 && nj < field.length) {
          final distance = sqrt(dx * dx + dy * dy);
          final weight = exp(-distance * distance / 2.0);
          intensity += field[nj][ni] * weight;
          count++;
        }
      }
    }
    
    return count > 0 ? intensity / count : 0.0;
  }
  
  /// 过滤和连接锋面
  List<Vector2> _filterAndConnectFronts(
    List<Vector2> frontPositions,
    List<List<double>> frontogenesisField,
  ) {
    if (frontPositions.isEmpty) return frontPositions;
    
    // 基于距离的锋面聚类
    final clusters = <List<Vector2>>[];
    final used = <bool>{};
    
    for (int i = 0; i < frontPositions.length; i++) {
      if (used.contains(i)) continue;
      
      final cluster = <Vector2>[frontPositions[i]];
      used.add(i);
      
      // 寻找邻近点
      for (int j = i + 1; j < frontPositions.length; j++) {
        if (used.contains(j)) continue;
        
        for (final point in cluster) {
          final distance = MathUtils.distance(
            point.x, point.y,
            frontPositions[j].x, frontPositions[j].y,
          );
          
          if (distance < 5.0) { // 5个网格距离
            cluster.add(frontPositions[j]);
            used.add(j);
            break;
          }
        }
      }
      
      if (cluster.length >= 3) {
        clusters.add(cluster);
      }
    }
    
    // 对每个聚类进行平滑
    final smoothedFronts = <Vector2>[];
    for (final cluster in clusters) {
      for (final point in cluster) {
        smoothedFronts.add(_smoothFrontPoint(point, cluster, frontogenesisField));
      }
    }
    
    return smoothedFronts;
  }
  
  /// 平滑锋面点
  Vector2 _smoothFrontPoint(
    Vector2 point,
    List<Vector2> cluster,
    List<List<double>> field,
  ) {
    double sumX = 0.0;
    double sumY = 0.0;
    double totalWeight = 0.0;
    
    for (final otherPoint in cluster) {
      final distance = MathUtils.distance(
        point.x, point.y,
        otherPoint.x, otherPoint.y,
      );
      
      if (distance < 3.0) {
        final weight = exp(-distance * distance / 2.0);
        sumX += otherPoint.x * weight;
        sumY += otherPoint.y * weight;
        totalWeight += weight;
      }
    }
    
    if (totalWeight > 0) {
      return Vector2(sumX / totalWeight, sumY / totalWeight);
    }
    
    return point;
  }
  
  /// 更新锋面系统
  void _updateFrontSystems(
    List<Vector2> frontPositions,
    List<List<List<double>>> uWind,
    List<List<List<double>>> vWind,
    List<List<List<double>>> pressure,
  ) {
    final currentTime = DateTime.now();
    final newFrontSystems = <FrontSystem>[];
    
    // 将邻近的锋面位置连接成锋面系统
    final frontGroups = _groupFrontPositions(frontPositions);
    
    for (final group in frontGroups) {
      if (group.length >= 3) { // 至少需要3个点才形成锋面
        final frontType = _determineFrontType(group, pressure);
        final intensity = _calculateFrontIntensity(group, uWind, vWind);
        
        final frontSystem = FrontSystem(
          type: frontType,
          points: group,
          intensity: intensity,
          timestamp: currentTime,
        );
        
        newFrontSystems.add(frontSystem);
      }
    }
    
    _frontSystems = newFrontSystems;
  }
  
  /// 将锋面位置分组
  List<List<Vector2>> _groupFrontPositions(List<Vector2> positions) {
    final groups = <List<Vector2>>[];
    final used = <bool>{};
    
    for (int i = 0; i < positions.length; i++) {
      if (used.contains(i)) continue;
      
      final group = <Vector2>[positions[i]];
      used.add(i);
      
      // 寻找邻近的点
      for (int j = 0; j < positions.length; j++) {
        if (used.contains(j)) continue;
        
        final distance = MathUtils.distance(
          group.last.x, group.last.y,
          positions[j].x, positions[j].y,
        );
        
        if (distance < 5.0) { // 5个网格距离内
          group.add(positions[j]);
          used.add(j);
        }
      }
      
      groups.add(group);
    }
    
    return groups;
  }
  
  /// 确定锋面类型
  FrontType _determineFrontType(
    List<Vector2> points,
    List<List<List<double>>> pressure,
  ) {
    if (points.isEmpty) return FrontType.stationary;
    
    // 计算锋面两侧的平均气压
    double leftPressure = 0, rightPressure = 0;
    int leftCount = 0, rightCount = 0;
    
    for (final point in points) {
      final i = point.x.toInt();
      final j = point.y.toInt();
      
      if (i > 0) {
        leftPressure += pressure[0][j][i-1];
        leftCount++;
      }
      if (i < _grid.nx - 1) {
        rightPressure += pressure[0][j][i+1];
        rightCount++;
      }
    }
    
    leftPressure /= leftCount;
    rightPressure /= rightCount;
    
    // 根据气压差判断锋面类型
    final pressureDiff = rightPressure - leftPressure;
    
    if (pressureDiff > 100) { // 1 hPa
      return FrontType.cold;
    } else if (pressureDiff < -100) {
      return FrontType.warm;
    } else {
      return FrontType.stationary;
    }
  }
  
  /// 计算锋面强度
  double _calculateFrontIntensity(
    List<Vector2> points,
    List<List<List<double>>> uWind,
    List<List<List<double>>> vWind,
  ) {
    if (points.length < 2) return 0.0;
    
    double totalShear = 0;
    int count = 0;
    
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      
      final i1 = p1.x.toInt();
      final j1 = p1.y.toInt();
      final i2 = p2.x.toInt();
      final j2 = p2.y.toInt();
      
      if (i1 >= 0 && i1 < _grid.nx && j1 >= 0 && j1 < _grid.ny &&
          i2 >= 0 && i2 < _grid.nx && j2 >= 0 && j2 < _grid.ny) {
        
        final u1 = uWind[0][j1][i1];
        final v1 = vWind[0][j1][i1];
        final u2 = uWind[0][j2][i2];
        final v2 = vWind[0][j2][i2];
        
        final shear = sqrt(pow(u2 - u1, 2) + pow(v2 - v1, 2));
        totalShear += shear;
        count++;
      }
    }
    
    return count > 0 ? totalShear / count : 0.0;
  }
  
  /// 计算锋面移动
  void _calculateFrontMovement(
    List<List<List<double>>> uWind,
    List<List<List<double>>> vWind,
  ) {
    for (final front in _frontSystems) {
      for (int i = 0; i < front.points.length; i++) {
        final point = front.points[i];
        final gridX = point.x.toInt();
        final gridY = point.y.toInt();
        
        if (gridX >= 0 && gridX < _grid.nx && 
            gridY >= 0 && gridY < _grid.ny) {
          
          // 获取锋面位置的风速
          final u = uWind[0][gridY][gridX];
          final v = vWind[0][gridY][gridX];
          
          // 锋面移动速度（通常小于风速）
          final movementFactor = 0.7; // 锋面移动系数
          final dx = u * _dt * movementFactor / _dx;
          final dy = v * _dt * movementFactor / _dy;
          
          // 更新锋面位置
          front.points[i] = Vector2(
            (point.x + dx).clamp(0.0, _grid.nx - 1.0),
            (point.y + dy).clamp(0.0, _grid.ny - 1.0),
          );
        }
      }
    }
  }
  
  /// 应用锋面效应
  void _applyFrontEffects(
    List<List<List<double>>> temperature,
    List<List<List<double>>> humidity,
    List<List<List<double>>> pressure,
  ) {
    final k = 0; // 地面层
    
    for (final front in _frontSystems) {
      for (final point in front.points) {
        final i = point.x.toInt();
        final j = point.y.toInt();
        
        if (i >= 0 && i < _grid.nx && j >= 0 && j < _grid.ny) {
          // 根据锋面类型调整气象要素
          switch (front.type) {
            case FrontType.cold:
              // 冷锋：降温、增压、湿度增加
              temperature[k][j][i] -= front.intensity * 0.1;
              pressure[k][j][i] += front.intensity * 10;
              humidity[k][j][i] += front.intensity * 0.05;
              break;
              
            case FrontType.warm:
              // 暖锋：增温、降压、湿度增加
              temperature[k][j][i] += front.intensity * 0.1;
              pressure[k][j][i] -= front.intensity * 10;
              humidity[k][j][i] += front.intensity * 0.05;
              break;
              
            case FrontType.stationary:
              // 静止锋：轻微变化
              humidity[k][j][i] += front.intensity * 0.02;
              break;
          }
        }
      }
    }
  }
  
  /// 获取当前锋面系统
  List<FrontSystem> getFrontSystems() {
    return _frontSystems;
  }
  
  /// 检查数值稳定性
  bool checkStability() {
    // 检查锋面数量和强度是否合理
    if (_frontSystems.length > 10) return false; // 锋面过多
    
    for (final front in _frontSystems) {
      if (front.intensity > 20.0) return false; // 锋面过强
      if (front.points.length > 100) return false; // 锋面过长
    }
    
    return true;
  }
}