import 'dart:math';
import 'dart:isolate';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/app_config.dart';
import '../models/meteorology_state.dart';

/// 性能优化和内存管理系统
/// 提供智能的性能监控、内存管理和资源优化
class PerformanceManager {
  static final PerformanceManager _instance = PerformanceManager._internal();
  factory PerformanceManager() => _instance;
  PerformanceManager._internal();
  
  final Map<String, PerformanceMetric> _metrics = {};
  final StreamController<PerformanceEvent> _eventController = StreamController<PerformanceEvent>.broadcast();
  Timer? _monitoringTimer;
  MemoryInfo? _lastMemoryInfo;
  
  /// 性能事件流
  Stream<PerformanceEvent> get performanceEvents => _eventController.stream;
  
  /// 初始化性能管理器
  Future<void> initialize() async {
    if (!AppConfig.enablePerformanceMonitoring) return;
    
    // 启动性能监控
    _startPerformanceMonitoring();
    
    // 初始化内存管理
    await _initializeMemoryManagement();
    
    print('PerformanceManager initialized');
  }
  
  /// 开始性能监控
  void _startPerformanceMonitoring() {
    _monitoringTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _collectPerformanceMetrics();
    });
  }
  
  /// 收集性能指标
  void _collectPerformanceMetrics() {
    final timestamp = DateTime.now();
    
    // 收集内存信息
    _collectMemoryMetrics(timestamp);
    
    // 收集CPU信息
    _collectCPUMetrics(timestamp);
    
    // 收集渲染性能
    _collectRenderingMetrics(timestamp);
    
    // 检查性能警告
    _checkPerformanceWarnings();
  }
  
  /// 收集内存指标
  void _collectMemoryMetrics(DateTime timestamp) {
    if (kIsMode) return; // Web模式不支持内存监控
    
    try {
      // 模拟内存信息收集
      final totalMemory = 1024 * 1024 * 1024; // 1GB
      final usedMemory = Random().nextInt(512 * 1024 * 1024); // 0-512MB
      final freeMemory = totalMemory - usedMemory;
      
      final memoryInfo = MemoryInfo(
        totalMemory: totalMemory,
        usedMemory: usedMemory,
        freeMemory: freeMemory,
        timestamp: timestamp,
      );
      
      _lastMemoryInfo = memoryInfo;
      
      _metrics['memory'] = PerformanceMetric(
        name: 'memory',
        value: usedMemory.toDouble(),
        unit: 'bytes',
        timestamp: timestamp,
        metadata: {
          'totalMemory': totalMemory,
          'freeMemory': freeMemory,
          'usagePercentage': (usedMemory / totalMemory * 100).toStringAsFixed(1),
        },
      );
      
      // 发送内存事件
      _eventController.add(PerformanceEvent(
        type: PerformanceEventType.memoryUpdate,
        data: memoryInfo.toJson(),
        timestamp: timestamp,
      ));
      
    } catch (e) {
      print('Failed to collect memory metrics: $e');
    }
  }
  
  /// 收集CPU指标
  void _collectCPUMetrics(DateTime timestamp) {
    try {
      // 模拟CPU使用率
      final cpuUsage = Random().nextDouble() * 100;
      
      _metrics['cpu'] = PerformanceMetric(
        name: 'cpu',
        value: cpuUsage,
        unit: 'percent',
        timestamp: timestamp,
      );
      
      // 发送CPU事件
      _eventController.add(PerformanceEvent(
        type: PerformanceEventType.cpuUpdate,
        data: {'usage': cpuUsage},
        timestamp: timestamp,
      ));
      
    } catch (e) {
      print('Failed to collect CPU metrics: $e');
    }
  }
  
  /// 收集渲染性能指标
  void _collectRenderingMetrics(DateTime timestamp) {
    try {
      // 模拟渲染性能
      final frameRate = 60 - Random().nextInt(10); // 50-60 FPS
      final frameTime = 1000 / frameRate; // ms
      
      _metrics['rendering'] = PerformanceMetric(
        name: 'rendering',
        value: frameRate,
        unit: 'fps',
        timestamp: timestamp,
        metadata: {
          'frameTime': frameTime.toStringAsFixed(1),
          'targetFPS': AppConfig.targetFPS,
        },
      );
      
      // 发送渲染事件
      _eventController.add(PerformanceEvent(
        type: PerformanceEventType.renderingUpdate,
        data: {
          'frameRate': frameRate,
          'frameTime': frameTime,
        },
        timestamp: timestamp,
      ));
      
    } catch (e) {
      print('Failed to collect rendering metrics: $e');
    }
  }
  
  /// 检查性能警告
  void _checkPerformanceWarnings() {
    // 检查内存使用率
    final memoryMetric = _metrics['memory'];
    if (memoryMetric != null) {
      final usagePercentage = memoryMetric.metadata?['usagePercentage'];
      if (usagePercentage != null && double.parse(usagePercentage) > 80) {
        _eventController.add(PerformanceEvent(
          type: PerformanceEventType.warning,
          data: {
            'type': 'high_memory_usage',
            'message': '内存使用率过高: $usagePercentage%',
            'severity': 'high',
          },
          timestamp: DateTime.now(),
        ));
      }
    }
    
    // 检查CPU使用率
    final cpuMetric = _metrics['cpu'];
    if (cpuMetric != null && cpuMetric.value > 90) {
      _eventController.add(PerformanceEvent(
        type: PerformanceEventType.warning,
        data: {
          'type': 'high_cpu_usage',
          'message': 'CPU使用率过高: ${cpuMetric.value.toStringAsFixed(1)}%',
          'severity': 'medium',
        },
        timestamp: DateTime.now(),
      ));
    }
    
    // 检查帧率
    final renderingMetric = _metrics['rendering'];
    if (renderingMetric != null && renderingMetric.value < 30) {
      _eventController.add(PerformanceEvent(
        type: PerformanceEventType.warning,
        data: {
          'type': 'low_frame_rate',
          'message': '帧率过低: ${renderingMetric.value.toStringAsFixed(1)} FPS',
          'severity': 'medium',
        },
        timestamp: DateTime.now(),
      ));
    }
  }
  
  /// 初始化内存管理
  Future<void> _initializeMemoryManagement() async {
    // 设置内存压力监听
    _setupMemoryPressureListener();
    
    // 初始化缓存管理
    _initializeCacheManagement();
  }
  
  /// 设置内存压力监听
  void _setupMemoryPressureListener() {
    // 在实际应用中，这里会监听系统内存压力事件
    // 目前使用定时检查模拟
    Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkMemoryPressure();
    });
  }
  
  /// 检查内存压力
  void _checkMemoryPressure() {
    if (_lastMemoryInfo == null) return;
    
    final usagePercentage = _lastMemoryInfo!.usedMemory / _lastMemoryInfo!.totalMemory;
    
    if (usagePercentage > 0.85) {
      // 高内存压力，触发清理
      _performMemoryCleanup();
    } else if (usagePercentage > 0.7) {
      // 中等内存压力，优化缓存
      _optimizeCache();
    }
  }
  
  /// 执行内存清理
  void _performMemoryCleanup() {
    print('Performing memory cleanup...');
    
    // 发送内存清理事件
    _eventController.add(PerformanceEvent(
      type: PerformanceEventType.memoryCleanup,
      data: {
        'action': 'full_cleanup',
        'reason': 'high_memory_pressure',
      },
      timestamp: DateTime.now(),
    ));
    
    // 清理缓存
    _clearCache();
    
    // 强制垃圾回收
    if (!kIsMode) {
      // 在实际应用中，这里会调用垃圾回收
      print('Triggering garbage collection...');
    }
  }
  
  /// 优化缓存
  void _optimizeCache() {
    print('Optimizing cache...');
    
    _eventController.add(PerformanceEvent(
      type: PerformanceEventType.cacheOptimization,
      data: {
        'action': 'optimize',
        'reason': 'medium_memory_pressure',
      },
      timestamp: DateTime.now(),
    ));
    
    // 实现缓存优化逻辑
    _reduceCacheSize();
  }
  
  /// 初始化缓存管理
  void _initializeCacheManagement() {
    // 设置缓存大小限制
    final maxCacheSize = AppConfig.currentPerformanceLevel.estimatedMemoryUsage * 0.3; // 30%的内存用于缓存
    
    print('Cache management initialized with max size: ${maxCacheSize.toStringAsFixed(1)}MB');
  }
  
  /// 清理缓存
  void _clearCache() {
    // 实现缓存清理逻辑
    print('Clearing cache...');
  }
  
  /// 减少缓存大小
  void _reduceCacheSize() {
    // 实现缓存大小减少逻辑
    print('Reducing cache size...');
  }
  
  /// 获取性能指标
  PerformanceMetric? getMetric(String name) {
    return _metrics[name];
  }
  
  /// 获取所有性能指标
  Map<String, PerformanceMetric> getAllMetrics() {
    return Map.from(_metrics);
  }
  
  /// 获取性能报告
  PerformanceReport getPerformanceReport() {
    return PerformanceReport(
      timestamp: DateTime.now(),
      metrics: Map.from(_metrics),
      memoryInfo: _lastMemoryInfo,
      recommendations: _generateRecommendations(),
    );
  }
  
  /// 生成性能建议
  List<String> _generateRecommendations() {
    final recommendations = <String>[];
    
    // 内存建议
    final memoryMetric = _metrics['memory'];
    if (memoryMetric != null) {
      final usagePercentage = memoryMetric.metadata?['usagePercentage'];
      if (usagePercentage != null && double.parse(usagePercentage) > 70) {
        recommendations.add('内存使用率较高，建议降低网格分辨率或启用并行计算');
      }
    }
    
    // CPU建议
    final cpuMetric = _metrics['cpu'];
    if (cpuMetric != null && cpuMetric.value > 80) {
      recommendations.add('CPU使用率较高，建议降低模拟速度或减少计算精度');
    }
    
    // 渲染建议
    final renderingMetric = _metrics['rendering'];
    if (renderingMetric != null && renderingMetric.value < 45) {
      recommendations.add('渲染帧率较低，建议降低可视化质量或关闭动画效果');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('系统性能良好，无需优化');
    }
    
    return recommendations;
  }
  
  /// 优化模拟参数
  SimulationOptimization optimizeSimulationParameters() {
    final currentLevel = AppConfig.currentPerformanceLevel;
    final memoryMetric = _metrics['memory'];
    final cpuMetric = _metrics['cpu'];
    
    // 基于当前性能状况建议优化
    PerformanceLevel? recommendedLevel;
    List<String> reasons = [];
    
    if (memoryMetric != null) {
      final usagePercentage = memoryMetric.metadata?['usagePercentage'];
      if (usagePercentage != null && double.parse(usagePercentage) > 80) {
        recommendedLevel = AppConfig.low;
        reasons.add('内存使用率过高');
      }
    }
    
    if (cpuMetric != null && cpuMetric.value > 85) {
      if (recommendedLevel == null) {
        recommendedLevel = AppConfig.medium;
      }
      reasons.add('CPU使用率过高');
    }
    
    if (recommendedLevel == null) {
      recommendedLevel = currentLevel;
      reasons.add('当前性能配置合适');
    }
    
    return SimulationOptimization(
      recommendedLevel: recommendedLevel,
      currentLevel: currentLevel,
      reasons: reasons,
      estimatedImprovement: _calculateEstimatedImprovement(currentLevel, recommendedLevel),
    );
  }
  
  /// 计算预期性能提升
  double _calculateEstimatedImprovement(PerformanceLevel current, PerformanceLevel recommended) {
    if (current == recommended) return 0.0;
    
    // 简化的性能提升计算
    final currentComplexity = current.totalGridPoints;
    final recommendedComplexity = recommended.totalGridPoints;
    
    return (currentComplexity - recommendedComplexity) / currentComplexity * 100;
  }
  
  /// 释放资源
  void dispose() {
    _monitoringTimer?.cancel();
    _eventController.close();
    _metrics.clear();
  }
}

/// 性能指标
class PerformanceMetric {
  final String name;
  final double value;
  final String unit;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  
  PerformanceMetric({
    required this.name,
    required this.value,
    required this.unit,
    required this.timestamp,
    this.metadata,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'unit': unit,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// 内存信息
class MemoryInfo {
  final int totalMemory;
  final int usedMemory;
  final int freeMemory;
  final DateTime timestamp;
  
  MemoryInfo({
    required this.totalMemory,
    required this.usedMemory,
    required this.freeMemory,
    required this.timestamp,
  });
  
  double get usagePercentage => usedMemory / totalMemory * 100;
  
  Map<String, dynamic> toJson() {
    return {
      'totalMemory': totalMemory,
      'usedMemory': usedMemory,
      'freeMemory': freeMemory,
      'usagePercentage': usagePercentage,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// 性能事件
class PerformanceEvent {
  final PerformanceEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  
  PerformanceEvent({
    required this.type,
    required this.data,
    required this.timestamp,
  });
}

/// 性能事件类型
enum PerformanceEventType {
  memoryUpdate,
  cpuUpdate,
  renderingUpdate,
  warning,
  memoryCleanup,
  cacheOptimization,
}

/// 性能报告
class PerformanceReport {
  final DateTime timestamp;
  final Map<String, PerformanceMetric> metrics;
  final MemoryInfo? memoryInfo;
  final List<String> recommendations;
  
  PerformanceReport({
    required this.timestamp,
    required this.metrics,
    this.memoryInfo,
    required this.recommendations,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'metrics': metrics.map((k, v) => MapEntry(k, v.toJson())),
      'memoryInfo': memoryInfo?.toJson(),
      'recommendations': recommendations,
    };
  }
}

/// 模拟优化建议
class SimulationOptimization {
  final PerformanceLevel recommendedLevel;
  final PerformanceLevel currentLevel;
  final List<String> reasons;
  final double estimatedImprovement;
  
  SimulationOptimization({
    required this.recommendedLevel,
    required this.currentLevel,
    required this.reasons,
    required this.estimatedImprovement,
  });
  
  bool get needsOptimization => recommendedLevel != currentLevel;
  
  Map<String, dynamic> toJson() {
    return {
      'recommendedLevel': {
        'gridNX': recommendedLevel.gridNX,
        'gridNY': recommendedLevel.gridNY,
        'gridNZ': recommendedLevel.gridNZ,
        'complexity': recommendedLevel.complexityLevel,
      },
      'currentLevel': {
        'gridNX': currentLevel.gridNX,
        'gridNY': currentLevel.gridNY,
        'gridNZ': currentLevel.gridNZ,
        'complexity': currentLevel.complexityLevel,
      },
      'reasons': reasons,
      'estimatedImprovement': estimatedImprovement,
      'needsOptimization': needsOptimization,
    };
  }
}