import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/app_config.dart';
import 'controllers/meteorology_controller.dart';
import 'services/meteorology_service.dart';
import 'services/performance_manager.dart';
import 'services/error_handler.dart';
import 'ui/screens/main_screen.dart';
import 'models/meteorology_state.dart';

/// 气象沙盘模拟器主应用入口
/// 
/// 初始化全局配置、性能监控和错误处理系统
/// 支持多设备适配和性能优化模式
void main() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 设置首选设备方向
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  // 初始化性能监控
  await PerformanceManager.instance.initialize();
  
  // 初始化错误处理器
  await ErrorHandler.instance.initialize();
  
  runApp(const MeteorologicalSandbox());
}

/// 气象沙盘模拟器主应用
/// 
/// 采用Provider状态管理，集成性能监控和错误处理
/// 支持Material Design 3.0主题和自适应布局
class MeteorologicalSandbox extends StatelessWidget {
  const MeteorologicalSandbox({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 气象控制器 - 主要业务逻辑
        ChangeNotifierProvider(
          create: (_) => MeteorologyController(),
          lazy: false, // 立即初始化以确保数据加载
        ),
        // 气象服务 - 数据处理和计算
        Provider(
          create: (_) => MeteorologyService(),
          lazy: false,
        ),
        // 性能管理器 - 实时性能监控
        Provider(
          create: (_) => PerformanceManager.instance,
          lazy: false,
        ),
        // 错误处理器 - 全局错误管理
        Provider(
          create: (_) => ErrorHandler.instance,
          lazy: false,
        ),
      ],
      child: Consumer<PerformanceManager>(
        builder: (context, performanceManager, child) {
          return MaterialApp(
            title: AppConfig.appName,
            debugShowCheckedModeBanner: AppConfig.isDebugMode,
            
            // Material Design 3.0主题
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppConfig.primaryColor,
                brightness: Brightness.light,
              ),
              visualDensity: VisualDensity.adaptivePlatformDensity,
              fontFamily: 'Roboto',
              // 高性能滚动配置
              scrollBehavior: const MaterialScrollBehavior().copyWith(
                overscroll: false,
                physics: const BouncingScrollPhysics(),
              ),
            ),
            
            // 深色主题
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppConfig.primaryColor,
                brightness: Brightness.dark,
              ),
              visualDensity: VisualDensity.adaptivePlatformDensity,
              fontFamily: 'Roboto',
            ),
            
            // 主题模式切换
            themeMode: ThemeMode.system,
            
            // 主页面
            home: const MainScreen(),
            
            // 性能监控覆盖层 (仅在调试模式显示)
            builder: AppConfig.isDebugMode
                ? (context, child) => PerformanceOverlay(
                    child: child!,
                  )
                : null,
          );
        },
      ),
    );
  }
}

/// 性能监控覆盖层组件
/// 
/// 在调试模式下显示实时性能指标
class PerformanceOverlay extends StatelessWidget {
  final Widget child;
  
  const PerformanceOverlay({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PerformanceManager>(
      builder: (context, performanceManager, _) {
        return Stack(
          children: [
            child,
            if (AppConfig.isDebugMode)
              Positioned(
                top: 50,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'FPS: ${performanceManager.currentFPS.toStringAsFixed(1)}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        '内存: ${(performanceManager.memoryUsage / 1024 / 1024).toStringAsFixed(1)}MB',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        'CPU: ${performanceManager.cpuUsage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}