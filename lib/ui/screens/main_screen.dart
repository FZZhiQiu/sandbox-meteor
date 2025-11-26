import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/meteorology_controller.dart';
import '../../models/meteorology_state.dart';
import '../../render/meteorology_painter.dart';
import '../widgets/control_panel.dart';
import '../widgets/status_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  MeteorologyVariable _selectedVariable = MeteorologyVariable.temperature;
  double _scaleFactor = 1.0;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MeteorologyController>().initialize();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('气象沙盘模拟器'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfo,
          ),
        ],
      ),
      body: Consumer<MeteorologyController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          if (controller.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    controller.error!,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.red.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: controller.initialize,
                    child: const Text('重新初始化'),
                  ),
                ],
              ),
            );
          }
          
          if (controller.currentState == null) {
            return const Center(
              child: Text('未初始化'),
            );
          }
          
          return Column(
            children: [
              // 状态栏
              StatusBar(
                state: controller.currentState!,
                isSimulating: controller.isSimulating,
              ),
              
              // 主显示区域
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: CustomPaint(
                      painter: MeteorologyPainter(
                        state: controller.currentState!,
                        selectedVariable: _selectedVariable,
                        scaleFactor: _scaleFactor,
                      ),
                      child: Container(),
                    ),
                  ),
                ),
              ),
              
              // 控制面板
              ControlPanel(
                selectedVariable: _selectedVariable,
                scaleFactor: _scaleFactor,
                isSimulating: controller.isSimulating,
                onVariableChanged: (variable) {
                  setState(() {
                    _selectedVariable = variable;
                  });
                },
                onScaleChanged: (scale) {
                  setState(() {
                    _scaleFactor = scale;
                  });
                },
                onStartSimulation: controller.startSimulation,
                onStopSimulation: controller.stopSimulation,
                onReset: controller.reset,
              ),
            ],
          );
        },
      ),
    );
  }
  
  void _showInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('关于'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('气象沙盘模拟器 v1.0.0'),
            SizedBox(height: 8),
            Text('基于真实气象学原理的高精度数值模拟系统'),
            SizedBox(height: 16),
            Text('功能特性：'),
            SizedBox(height: 8),
            Text('• 实时风场模拟'),
            Text('• 水汽输送计算'),
            Text('• 降水过程模拟'),
            Text('• 温度场演化'),
            Text('• 锋面系统追踪'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}