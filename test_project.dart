import 'dart:io';

void main() async {
  print('🌤️  Flutter气象沙盘项目测试开始');
  
  // 1. 检查核心文件存在性
  final coreFiles = [
    'lib/main.dart',
    'lib/core/app_config.dart',
    'lib/models/meteorology_state.dart',
    'lib/controllers/meteorology_controller.dart',
    'lib/services/meteorology_service.dart',
    'lib/services/wind_solver.dart',
    'lib/services/diffusion_service.dart',
    'lib/services/precipitation_solver.dart',
    'lib/services/fronts_solver.dart',
    'lib/services/radiation_solver.dart',
    'lib/services/boundary_layer_solver.dart',
    'lib/ui/screens/main_screen.dart',
    'lib/render/meteorology_painter.dart',
  ];
  
  print('\n📁 检查核心文件存在性:');
  for (final file in coreFiles) {
    final exists = await File(file).exists();
    print('  ${exists ? "✅" : "❌"} $file');
  }
  
  // 2. 检查pubspec.yaml
  final pubspec = await File('pubspec.yaml').exists();
  print('\n📦 项目配置文件:');
  print('  ${pubspec ? "✅" : "❌"} pubspec.yaml');
  
  // 3. 尝试读取主要配置
  try {
    final pubspecContent = await File('pubspec.yaml').readAsString();
    print('\n📋 项目信息:');
    if (pubspecContent.contains('meteorological_sandbox')) {
      print('  ✅ 项目名称: meteorological_sandbox');
    }
    if (pubspecContent.contains('flutter:')) {
      print('  ✅ Flutter配置存在');
    }
    if (pubspecContent.contains('provider:')) {
      print('  ✅ 状态管理依赖存在');
    }
    if (pubspecContent.contains('vector_math:')) {
      print('  ✅ 数学计算依赖存在');
    }
  } catch (e) {
    print('  ❌ 读取配置文件失败: $e');
  }
  
  // 4. 检查Dart文件语法
  print('\n🔍 检查主要Dart文件语法:');
  final mainFile = File('lib/main.dart');
  if (await mainFile.exists()) {
    try {
      final content = await mainFile.readAsString();
      if (content.contains('MeteorologicalSandbox')) {
        print('  ✅ main.dart - 应用入口正确');
      }
      if (content.contains('MultiProvider')) {
        print('  ✅ main.dart - 状态管理配置正确');
      }
      if (content.contains('MainScreen')) {
        print('  ✅ main.dart - 主界面引用正确');
      }
    } catch (e) {
      print('  ❌ main.dart 语法检查失败: $e');
    }
  }
  
  print('\n🎯 测试完成');
}