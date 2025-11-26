/// 商业级气象沙盘模拟器配置
/// 支持多种性能级别和功能选项
class AppConfig {
  static const String appName = '气象沙盘模拟器';
  static const String version = '2.0.0';
  static const String buildNumber = '2024.11.25';
  
  // 性能级别配置
  static const PerformanceLevel low = PerformanceLevel(
    gridNX: 50, gridNY: 50, gridNZ: 10,
    timeStep: 0.5, targetFPS: 30,
    useParallel: false, useAdaptiveTimeStep: false,
  );
  
  static const PerformanceLevel medium = PerformanceLevel(
    gridNX: 100, gridNY: 100, gridNZ: 20,
    timeStep: 0.1, targetFPS: 60,
    useParallel: false, useAdaptiveTimeStep: true,
  );
  
  static const PerformanceLevel high = PerformanceLevel(
    gridNX: 200, gridNY: 200, gridNZ: 40,
    timeStep: 0.05, targetFPS: 60,
    useParallel: true, useAdaptiveTimeStep: true,
  );
  
  // 默认配置（中等性能）
  static int get gridNX => medium.gridNX;
  static int get gridNY => medium.gridNY;
  static int get gridNZ => medium.gridNZ;
  static double get timeStep => medium.timeStep;
  static int get targetFPS => medium.targetFPS;
  static bool get useParallel => medium.useParallel;
  static bool get useAdaptiveTimeStep => medium.useAdaptiveTimeStep;
  
  // 物理常数（国际标准）
  static const double gravity = 9.80665;  // 重力加速度 m/s²
  static const double gasConstant = 287.058;  // 气体常数 J/(kg·K)
  static const double specificHeat = 1004.685;  // 定压比热 J/(kg·K)
  static const double standardPressure = 101325.0;  // 标准大气压 Pa
  static const double standardTemperature = 288.15;  // 标准温度 K (15°C)
  static const double boltzmannConstant = 1.380649e-23;  // 玻尔兹曼常数 J/K
  static const double avogadroNumber = 6.02214076e23;  // 阿伏伽德罗常数 1/mol
  
  // 模拟参数
  static const int simulationInterval = 3;  // 模拟更新间隔 秒
  static const double maxSimulationSpeed = 10.0;  // 最大模拟速度倍数
  static const double minSimulationSpeed = 0.1;  // 最小模拟速度倍数
  
  // 数值精度配置
  static const double cflSafetyFactor = 0.8;  // CFL安全系数
  static const double convergenceThreshold = 1e-6;  // 收敛阈值
  static const int maxIterations = 100;  // 最大迭代次数
  
  // 地图范围 (中国区域)
  static const double mapWest = 73.0;   // 西边界 经度
  static const double mapEast = 135.0;  // 东边界 经度
  static const double mapSouth = 18.0;  // 南边界 纬度
  static const double mapNorth = 54.0;  // 北边界 纬度
  
  // 商业级功能配置
  static const bool enableDataPersistence = true;  // 数据持久化
  static const bool enableAdvancedVisualization = true;  // 高级可视化
  static const bool enablePerformanceMonitoring = true;  // 性能监控
  static const bool enableErrorRecovery = true;  // 错误恢复
  static const bool enableLogging = true;  // 日志记录
  
  // 数据管理配置
  static const int maxAutoSaveInterval = 300;  // 最大自动保存间隔 秒
  static const int maxUndoLevels = 50;  // 最大撤销级别
  static const String dataFormat = 'json';  // 数据格式
  
  // 渲染配置
  static const bool enableAntiAliasing = true;  // 抗锯齿
  static const bool enableHighDPI = true;  // 高DPI支持
  static const double defaultScale = 1.0;  // 默认缩放比例
  static const double maxScale = 5.0;  // 最大缩放比例
  static const double minScale = 0.1;  // 最小缩放比例
  
  // 用户体验配置
  static const bool enableAnimations = true;  // 动画效果
  static const bool enableDarkMode = true;  // 深色模式
  static const bool enableAccessibility = true;  // 无障碍功能
  static const bool enableTooltips = true;  // 工具提示
  
  // 质量保证配置
  static const bool enableValidation = true;  // 数据验证
  static const bool enableProfiling = false;  // 性能分析
  static const bool enableDebugMode = false;  // 调试模式
}

/// 性能级别配置类
class PerformanceLevel {
  final int gridNX;
  final int gridNY;
  final int gridNZ;
  final double timeStep;
  final int targetFPS;
  final bool useParallel;
  final bool useAdaptiveTimeStep;
  
  const PerformanceLevel({
    required this.gridNX,
    required this.gridNY,
    required this.gridNZ,
    required this.timeStep,
    required this.targetFPS,
    required this.useParallel,
    required this.useAdaptiveTimeStep,
  });
  
  /// 获取总网格点数
  int get totalGridPoints => gridNX * gridNY * gridNZ;
  
  /// 获取内存需求估算 (MB)
  double get estimatedMemoryUsage {
    const bytesPerGridPoint = 8.0 * 8;  // 8个变量，每个8字节
    return (totalGridPoints * bytesPerGridPoint) / (1024 * 1024);
  }
  
  /// 获取计算复杂度级别
  String get complexityLevel {
    if (totalGridPoints < 50000) return '低';
    if (totalGridPoints < 500000) return '中';
    return '高';
  }
}

/// 用户偏好设置
class UserPreferences {
  static PerformanceLevel currentPerformanceLevel = AppConfig.medium;
  static String currentTheme = 'light';
  static String currentLanguage = 'zh_CN';
  static Map<String, dynamic> customSettings = {};
  
  /// 获取当前性能配置
  static Map<String, dynamic> getCurrentSettings() {
    return {
      'performance': {
        'level': currentPerformanceLevel.complexityLevel,
        'gridNX': currentPerformanceLevel.gridNX,
        'gridNY': currentPerformanceLevel.gridNY,
        'gridNZ': currentPerformanceLevel.gridNZ,
        'targetFPS': currentPerformanceLevel.targetFPS,
        'useParallel': currentPerformanceLevel.useParallel,
        'estimatedMemory': '${currentPerformanceLevel.estimatedMemoryUsage.toStringAsFixed(1)}MB',
      },
      'ui': {
        'theme': currentTheme,
        'language': currentLanguage,
        'enableAnimations': AppConfig.enableAnimations,
        'enableDarkMode': AppConfig.enableDarkMode,
      },
      'features': {
        'dataPersistence': AppConfig.enableDataPersistence,
        'advancedVisualization': AppConfig.enableAdvancedVisualization,
        'performanceMonitoring': AppConfig.enablePerformanceMonitoring,
        'errorRecovery': AppConfig.enableErrorRecovery,
      },
      'custom': customSettings,
    };
  }
  
  /// 更新性能级别
  static void updatePerformanceLevel(PerformanceLevel level) {
    currentPerformanceLevel = level;
  }
  
  /// 更新主题
  static void updateTheme(String theme) {
    currentTheme = theme;
  }
  
  /// 更新自定义设置
  static void updateCustomSetting(String key, dynamic value) {
    customSettings[key] = value;
  }
}