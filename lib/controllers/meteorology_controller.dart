import 'package:flutter/foundation.dart';

import '../models/meteorology_state.dart';
import '../services/meteorology_service.dart';

class MeteorologyController extends ChangeNotifier {
  final MeteorologyService _service = MeteorologyService();
  
  MeteorologyState? _currentState;
  bool _isLoading = false;
  String? _error;
  
  // Getters
  MeteorologyState? get currentState => _currentState;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isSimulating => _currentState?.isSimulating ?? false;
  
  // 初始化系统
  Future<void> initialize() async {
    _setLoading(true);
    try {
      final grid = _service.initializeGrid();
      _currentState = MeteorologyState(
        grid: grid,
        timestamp: DateTime.now(),
        isSimulating: false,
      );
      _error = null;
    } catch (e) {
      _error = '初始化失败: $e';
    } finally {
      _setLoading(false);
    }
  }
  
  // 开始模拟
  void startSimulation() {
    if (_currentState == null) {
      _error = '请先初始化系统';
      notifyListeners();
      return;
    }
    
    try {
      _service.startSimulation((state) {
        _currentState = state;
        notifyListeners();
      });
      _error = null;
    } catch (e) {
      _error = '启动模拟失败: $e';
    }
    notifyListeners();
  }
  
  // 停止模拟
  void stopSimulation() {
    try {
      _service.stopSimulation();
      if (_currentState != null) {
        _currentState = _currentState!.copyWith(isSimulating: false);
      }
      _error = null;
    } catch (e) {
      _error = '停止模拟失败: $e';
    }
    notifyListeners();
  }
  
  // 重置系统
  Future<void> reset() async {
    stopSimulation();
    await initialize();
  }
  
  // 更新模拟速度
  void updateSimulationSpeed(double speed) {
    if (_currentState != null) {
      _currentState = _currentState!.copyWith(simulationSpeed: speed);
      notifyListeners();
    }
  }
  
  // 设置错误状态
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }
  
  // 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _service.stopSimulation();
    super.dispose();
  }
}