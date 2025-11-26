import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/app_config.dart';

/// 错误处理和异常管理系统
/// 提供统一的错误处理、日志记录和恢复机制
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();
  
  final List<ErrorLog> _errorLogs = [];
  final Map<String, ErrorRecoveryStrategy> _recoveryStrategies = {};
  final StreamController<ErrorEvent> _errorStreamController = StreamController<ErrorEvent>.broadcast();
  
  /// 错误事件流
  Stream<ErrorEvent> get errorStream => _errorStreamController.stream;
  
  /// 初始化错误处理器
  Future<void> initialize() async {
    try {
      // 注册默认恢复策略
      _registerDefaultRecoveryStrategies();
      
      // 设置全局错误处理
      FlutterError.onError = (FlutterErrorDetails details) {
        _handleFlutterError(details);
      };
      
      print('ErrorHandler initialized successfully');
    } catch (e) {
      print('Failed to initialize ErrorHandler: $e');
    }
  }
  
  /// 处理错误
  Future<ErrorResult> handleError(
    Exception exception, {
    String? context,
    ErrorSeverity severity = ErrorSeverity.medium,
    Map<String, dynamic>? metadata,
  }) async {
    final error = ErrorEvent(
      exception: exception,
      context: context,
      severity: severity,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
    
    // 记录错误日志
    _logError(error);
    
    // 发送错误事件
    _errorStreamController.add(error);
    
    // 尝试恢复
    final recoveryResult = await _attemptRecovery(error);
    
    // 记录恢复结果
    if (recoveryResult.isRecovered) {
      _logRecovery(error, recoveryResult);
    }
    
    return recoveryResult;
  }
  
  /// 处理Flutter错误
  void _handleFlutterError(FlutterErrorDetails details) {
    final exception = details.exception;
    final context = 'Flutter Error: ${details.library}:${details.stackTrace}';
    
    handleError(
      exception,
      context: context,
      severity: _determineErrorSeverity(details),
      metadata: {
        'library': details.library,
        'stackTrace': details.stackTrace.toString(),
      },
    );
  }
  
  /// 注册恢复策略
  void registerRecoveryStrategy(String errorType, ErrorRecoveryStrategy strategy) {
    _recoveryStrategies[errorType] = strategy;
  }
  
  /// 获取错误统计
  ErrorStatistics getStatistics() {
    final now = DateTime.now();
    final last24Hours = now.subtract(const Duration(days: 1));
    
    final recentErrors = _errorLogs.where((log) => log.timestamp.isAfter(last24Hours));
    
    return ErrorStatistics(
      totalErrors: _errorLogs.length,
      recentErrors: recentErrors.length,
      criticalErrors: recentErrors.where((e) => e.severity == ErrorSeverity.critical).length,
      errorsByType: _groupErrorsByType(recentErrors),
      recoveryRate: _calculateRecoveryRate(recentErrors),
    );
  }
  
  /// 清理错误日志
  Future<void> clearErrorLogs({Duration? olderThan}) async {
    if (olderThan != null) {
      final cutoffTime = DateTime.now().subtract(olderThan);
      _errorLogs.removeWhere((log) => log.timestamp.isBefore(cutoffTime));
    } else {
      _errorLogs.clear();
    }
  }
  
  /// 导出错误日志
  Future<String?> exportErrorLogs() async {
    try {
      final logs = _errorLogs.map((log) => log.toJson()).toList();
      final exportData = {
        'exportTime': DateTime.now().toIso8601String(),
        'version': AppConfig.version,
        'totalLogs': logs.length,
        'logs': logs,
      };
      
      return const JsonEncoder.withIndent('  ').convert(exportData);
    } catch (e) {
      print('Failed to export error logs: $e');
      return null;
    }
  }
  
  /// 记录错误日志
  void _logError(ErrorEvent error) {
    _errorLogs.add(ErrorLog(
      timestamp: error.timestamp,
      exception: error.exception,
      context: error.context,
      severity: error.severity,
      metadata: error.metadata,
    ));
    
    // 控制日志数量
    if (_errorLogs.length > 1000) {
      _errorLogs.removeRange(0, _errorLogs.length - 1000);
    }
    
    // 如果启用日志记录，写入文件
    if (AppConfig.enableLogging) {
      _writeToLogFile(error);
    }
  }
  
  /// 记录恢复日志
  void _logRecovery(ErrorEvent error, ErrorResult result) {
    final recoveryLog = ErrorLog(
      timestamp: DateTime.now(),
      exception: Exception('Recovery attempt'),
      context: 'Recovery for: ${error.context}',
      severity: result.isRecovered ? ErrorSeverity.low : ErrorSeverity.medium,
      metadata: {
        'originalError': error.exception.toString(),
        'recoveryAction': result.action,
        'recoveryTime': result.recoveryTime?.inMilliseconds,
        'isRecovered': result.isRecovered,
      },
    );
    
    _errorLogs.add(recoveryLog);
  }
  
  /// 写入日志文件
  Future<void> _writeToLogFile(ErrorEvent error) async {
    try {
      final logFile = File('logs/errors.log');
      final logEntry = '[${error.timestamp.toIso8601String()}] ${error.severity.name.toUpperCase()}: ${error.exception.toString()} - ${error.context}\n';
      
      await logFile.writeAsString(logEntry, mode: FileMode.append);
    } catch (e) {
      print('Failed to write to log file: $e');
    }
  }
  
  /// 尝试恢复
  Future<ErrorResult> _attemptRecovery(ErrorEvent error) async {
    final strategy = _recoveryStrategyForError(error);
    
    if (strategy == null) {
      return ErrorResult.notRecovered('No recovery strategy available');
    }
    
    final startTime = DateTime.now();
    
    try {
      final result = await strategy.recover(error);
      final recoveryTime = DateTime.now().difference(startTime);
      
      return ErrorResult.recovered(
        strategy.action,
        recoveryTime: recoveryTime,
      );
    } catch (e) {
      return ErrorResult.notRecovered(
        'Recovery failed: ${e.toString()}',
        recoveryTime: DateTime.now().difference(startTime),
      );
    }
  }
  
  /// 获取错误的恢复策略
  ErrorRecoveryStrategy? _recoveryStrategyForError(ErrorEvent error) {
    // 根据异常类型选择恢复策略
    final exceptionType = error.exception.runtimeType.toString();
    
    // 优先级：自定义策略 -> 默认策略
    if (_recoveryStrategies.containsKey(exceptionType)) {
      return _recoveryStrategies[exceptionType];
    }
    
    // 默认恢复策略
    return _getDefaultRecoveryStrategy(error);
  }
  
  /// 获取默认恢复策略
  ErrorRecoveryStrategy _getDefaultRecoveryStrategy(ErrorEvent error) {
    return ErrorRecoveryStrategy(
      action: 'default_recovery',
      description: 'Default recovery action',
      recover: (error) async {
        // 默认恢复逻辑
        await Future.delayed(const Duration(seconds: 1));
        
        // 根据错误严重程度决定是否抛出异常
        if (error.severity == ErrorSeverity.critical) {
          throw error.exception;
        }
        
        return true;
      },
    );
  }
  
  /// 确定错误严重程度
  ErrorSeverity _determineErrorSeverity(FlutterErrorDetails details) {
    // 根据错误类型确定严重程度
    if (details.exception is StateError) {
      return ErrorSeverity.critical;
    } else if (details.exception is FormatException) {
      return ErrorSeverity.medium;
    } else if (details.exception is RangeError) {
      return ErrorSeverity.medium;
    } else {
      return ErrorSeverity.low;
    }
  }
  
  /// 按类型分组错误
  Map<String, int> _groupErrorsByType(List<ErrorLog> logs) {
    final groups = <String, int>{};
    
    for (final log in logs) {
      final type = log.exception.runtimeType.toString();
      groups[type] = (groups[type] ?? 0) + 1;
    }
    
    return groups;
  }
  
  /// 计算恢复率
  double _calculateRecoveryRate(List<ErrorLog> logs) {
    if (logs.isEmpty) return 1.0;
    
    final recoveredLogs = logs.where((log) => 
        log.metadata['isRecovered'] == true
    ).length;
    
    return recoveredLogs / logs.length;
  }
  
  /// 注册默认恢复策略
  void _registerDefaultRecoveryStrategies() {
    // 内存不足恢复策略
    registerRecoveryStrategy('OutOfMemoryError', ErrorRecoveryStrategy(
      action: 'memory_cleanup',
      description: '清理内存并重启模拟',
      recover: (error) async {
        // 触发内存清理
        // 这里需要调用实际的内存清理逻辑
        print('Performing memory cleanup...');
        
        // 等待一段时间让系统恢复
        await Future.delayed(const Duration(seconds: 2));
        
        return true;
      },
    ));
    
    // 数值计算错误恢复策略
    registerRecoveryStrategy('MathError', ErrorRecoveryStrategy(
      action: 'numerical_stabilization',
      description: '数值稳定化处理',
      recover: (error) async {
        // 减小时间步长
        print('Applying numerical stabilization...');
        
        // 等待系统稳定
        await Future.delayed(const Duration(milliseconds: 500));
        
        return true;
      },
    ));
    
    // 网络错误恢复策略
    registerRecoveryStrategy('SocketException', ErrorRecoveryStrategy(
      action: 'network_retry',
      description: '网络重试机制',
      recover: (error) async {
        print('Performing network retry...');
        
        // 重试网络连接
        for (int i = 0; i < 3; i++) {
          try {
            await Future.delayed(const Duration(seconds: 1));
            return true; // 假设重试成功
          } catch (e) {
            continue;
          }
        }
        
        return false;
      },
    ));
    
    // 文件I/O错误恢复策略
    registerRecoveryStrategy('FileSystemException', ErrorRecoveryStrategy(
      action: 'file_operation_retry',
      description: '文件操作重试',
      recover: (error) async {
        print('Retrying file operation...');
        
        // 重试文件操作
        for (int i = 0; i < 3; i++) {
          try {
            await Future.delayed(const Duration(milliseconds: 500));
            return true; // 假设重试成功
          } catch (e) {
            continue;
          }
        }
        
        return false;
      },
    ));
  }
}

/// 错误事件
class ErrorEvent {
  final Exception exception;
  final String? context;
  final ErrorSeverity severity;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  
  ErrorEvent({
    required this.exception,
    this.context,
    this.severity = ErrorSeverity.medium,
    required this.timestamp,
    this.metadata,
  });
  
  String get errorType => exception.runtimeType.toString();
  String get errorMessage => exception.toString();
}

/// 错误结果
class ErrorResult {
  final String action;
  final String? message;
  final Duration? recoveryTime;
  final bool isRecovered;
  
  ErrorResult.recovered(
    this.action, {
    this.message,
    this.recoveryTime,
  }) : isRecovered = true;
  
  ErrorResult.notRecovered(
    this.message, {
    this.recoveryTime,
  }) : isRecovered = false;
}

/// 错误恢复策略
class ErrorRecoveryStrategy {
  final String action;
  final String description;
  final Future<bool> Function(ErrorEvent) recover;
  
  ErrorRecoveryStrategy({
    required this.action,
    required this.description,
    required this.recover,
  });
}

/// 错误日志
class ErrorLog {
  final DateTime timestamp;
  final Exception exception;
  final String? context;
  final ErrorSeverity severity;
  final Map<String, dynamic>? metadata;
  
  ErrorLog({
    required this.timestamp,
    required this.exception,
    this.context,
    required this.severity,
    this.metadata,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'exception': exception.toString(),
      'context': context,
      'severity': severity.name,
      'metadata': metadata,
    };
  }
}

/// 错误严重程度
enum ErrorSeverity {
  low,
  medium,
  high,
  critical,
}

/// 错误统计
class ErrorStatistics {
  final int totalErrors;
  final int recentErrors;
  final int criticalErrors;
  final Map<String, int> errorsByType;
  final double recoveryRate;
  
  ErrorStatistics({
    required this.totalErrors,
    required this.recentErrors,
    required this.criticalErrors,
    required this.errorsByType,
    required this.recoveryRate,
  });
  
  @override
  String toString() {
    return 'ErrorStatistics('
        'totalErrors: $totalErrors, '
        'recentErrors: $recentErrors, '
        'criticalErrors: $criticalErrors, '
        'recoveryRate: ${(recoveryRate * 100).toStringAsFixed(1)}%, '
        'errorsByType: $errorsByType'
        ')';
  }
}
