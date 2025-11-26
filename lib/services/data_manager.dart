import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/meteorology_state.dart';
import '../core/app_config.dart';

/// 数据持久化管理器
/// 提供气象数据的保存、加载、导入导出功能
class DataManager {
  static final DataManager _instance = DataManager._internal();
  factory DataManager() => _instance;
  DataManager._internal();
  
  String? _dataDirectory;
  final Map<String, MeteorologyState> _savedStates = {};
  final Map<String, DateTime> _saveTimestamps = {};
  
  /// 初始化数据管理器
  Future<void> initialize() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      _dataDirectory = '${directory.path}/meteorological_sandbox';
      
      // 创建数据目录
      final dataDir = Directory(_dataDirectory!);
      if (!await dataDir.exists()) {
        await dataDir.create(recursive: true);
      }
      
      // 创建子目录
      await Directory('$_dataDirectory/saves').create(recursive: true);
      await Directory('$_dataDirectory/exports').create(recursive: true);
      await Directory('$_dataDirectory/imports').create(recursive: true);
      await Directory('$_dataDirectory/logs').create(recursive: true);
      
      // 加载已保存的状态列表
      await _loadSavedStatesList();
      
      print('DataManager initialized successfully');
    } catch (e) {
      print('Failed to initialize DataManager: $e');
      throw DataManagerException('初始化失败: $e');
    }
  }
  
  /// 保存气象状态
  Future<bool> saveState(String name, MeteorologyState state) async {
    try {
      if (_dataDirectory == null) {
        throw DataManagerException('数据管理器未初始化');
      }
      
      // 验证状态数据
      if (!_validateState(state)) {
        throw DataManagerException('状态数据验证失败');
      }
      
      final timestamp = DateTime.now();
      final saveData = {
        'name': name,
        'timestamp': timestamp.toIso8601String(),
        'version': AppConfig.version,
        'buildNumber': AppConfig.buildNumber,
        'state': _serializeState(state),
        'metadata': _generateMetadata(state),
      };
      
      // 保存到文件
      final fileName = '${_sanitizeFileName(name)}.json';
      final filePath = '$_dataDirectory/saves/$fileName';
      final file = File(filePath);
      
      await file.writeAsString(jsonEncode(saveData));
      
      // 更新内存缓存
      _savedStates[name] = state;
      _saveTimestamps[name] = timestamp;
      
      // 记录日志
      await _logOperation('save', name, 'success', 'State saved successfully');
      
      return true;
    } catch (e) {
      print('Failed to save state: $e');
      await _logOperation('save', name, 'error', e.toString());
      return false;
    }
  }
  
  /// 加载气象状态
  Future<MeteorologyState?> loadState(String name) async {
    try {
      if (_dataDirectory == null) {
        throw DataManagerException('数据管理器未初始化');
      }
      
      final fileName = '${_sanitizeFileName(name)}.json';
      final filePath = '$_dataDirectory/saves/$fileName';
      final file = File(filePath);
      
      if (!await file.exists()) {
        throw DataManagerException('保存文件不存在: $name');
      }
      
      final content = await file.readAsString();
      final saveData = jsonDecode(content);
      
      // 验证版本兼容性
      if (!_isVersionCompatible(saveData['version'])) {
        throw DataManagerException('版本不兼容: ${saveData['version']}');
      }
      
      // 反序列化状态
      final state = _deserializeState(saveData['state']);
      
      // 验证加载的状态
      if (!_validateState(state)) {
        throw DataManagerException('加载的状态数据验证失败');
      }
      
      // 更新内存缓存
      _savedStates[name] = state;
      _saveTimestamps[name] = DateTime.parse(saveData['timestamp']);
      
      // 记录日志
      await _logOperation('load', name, 'success', 'State loaded successfully');
      
      return state;
    } catch (e) {
      print('Failed to load state: $e');
      await _logOperation('load', name, 'error', e.toString());
      return null;
    }
  }
  
  /// 删除保存的状态
  Future<bool> deleteState(String name) async {
    try {
      if (_dataDirectory == null) {
        throw DataManagerException('数据管理器未初始化');
      }
      
      final fileName = '${_sanitizeFileName(name)}.json';
      final filePath = '$_dataDirectory/saves/$fileName';
      final file = File(filePath);
      
      if (await file.exists()) {
        await file.delete();
      }
      
      // 更新内存缓存
      _savedStates.remove(name);
      _saveTimestamps.remove(name);
      
      // 记录日志
      await _logOperation('delete', name, 'success', 'State deleted successfully');
      
      return true;
    } catch (e) {
      print('Failed to delete state: $e');
      await _logOperation('delete', name, 'error', e.toString());
      return false;
    }
  }
  
  /// 获取已保存的状态列表
  List<String> getSavedStatesList() {
    return _savedStates.keys.toList()..sort();
  }
  
  /// 获取状态保存时间
  DateTime? getStateTimestamp(String name) {
    return _saveTimestamps[name];
  }
  
  /// 导出状态到文件
  Future<String?> exportState(String name, {String format = 'json'}) async {
    try {
      final state = _savedStates[name] ?? await loadState(name);
      if (state == null) {
        throw DataManagerException('状态不存在: $name');
      }
      
      String content;
      String extension;
      
      switch (format.toLowerCase()) {
        case 'json':
          content = _exportToJson(state, name);
          extension = '.json';
          break;
        case 'csv':
          content = _exportToCsv(state);
          extension = '.csv';
          break;
        case 'txt':
          content = _exportToText(state);
          extension = '.txt';
          break;
        default:
          throw DataManagerException('不支持的导出格式: $format');
      }
      
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = '${_sanitizeFileName(name)}_export_$timestamp$extension';
      final filePath = '$_dataDirectory/exports/$fileName';
      
      final file = File(filePath);
      await file.writeAsString(content);
      
      // 记录日志
      await _logOperation('export', name, 'success', 'Exported as $format');
      
      return filePath;
    } catch (e) {
      print('Failed to export state: $e');
      await _logOperation('export', name, 'error', e.toString());
      return null;
    }
  }
  
  /// 从文件导入状态
  Future<MeteorologyState?> importState(String filePath, {String? name}) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw DataManagerException('导入文件不存在: $filePath');
      }
      
      final content = await file.readAsString();
      final extension = filePath.toLowerCase().split('.').last;
      
      MeteorologyState state;
      
      switch (extension) {
        case 'json':
          state = _importFromJson(content);
          break;
        case 'csv':
          state = _importFromCsv(content);
          break;
        default:
          throw DataManagerException('不支持的导入格式: $extension');
      }
      
      // 验证导入的状态
      if (!_validateState(state)) {
        throw DataManagerException('导入的状态数据验证失败');
      }
      
      // 自动保存导入的状态
      final importName = name ?? 'imported_${DateTime.now().millisecondsSinceEpoch}';
      await saveState(importName, state);
      
      // 记录日志
      await _logOperation('import', importName, 'success', 'Imported from $filePath');
      
      return state;
    } catch (e) {
      print('Failed to import state: $e');
      await _logOperation('import', filePath, 'error', e.toString());
      return null;
    }
  }
  
  /// 自动保存功能
  Future<void> autoSave(MeteorologyState state) async {
    try {
      final autoSaveName = 'autosave_${DateTime.now().millisecondsSinceEpoch}';
      await saveState(autoSaveName, state);
      
      // 清理旧的自动保存文件（保留最近的10个）
      await _cleanupAutoSaves();
    } catch (e) {
      print('Auto save failed: $e');
    }
  }
  
  /// 获取数据统计信息
  Future<Map<String, dynamic>> getDataStatistics() async {
    try {
      final savesDir = Directory('$_dataDirectory/saves');
      final files = await savesDir.list().toList();
      
      int totalSize = 0;
      int fileCount = 0;
      
      for (final file in files) {
        if (file is File && file.path.endsWith('.json')) {
          final stat = await file.stat();
          totalSize += stat.size;
          fileCount++;
        }
      }
      
      return {
        'totalSaves': fileCount,
        'totalSize': totalSize,
        'averageSize': fileCount > 0 ? totalSize / fileCount : 0,
        'dataDirectory': _dataDirectory,
        'lastModified': files.isNotEmpty ? (await files.last.modified()).toIso8601String() : null,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  
  /// 验证状态数据
  bool _validateState(MeteorologyState state) {
    try {
      // 检查网格数据完整性
      final grid = state.grid;
      if (grid.nx <= 0 || grid.ny <= 0 || grid.nz <= 0) {
        return false;
      }
      
      // 检查数据范围合理性
      for (final variable in MeteorologyVariable.values) {
        final data = grid.getVariableData(variable);
        if (data != null) {
          for (int k = 0; k < grid.nz; k++) {
            for (int j = 0; j < grid.ny; j++) {
              for (int i = 0; i < grid.nx; i++) {
                final value = data[k][j][i];
                if (value.isNaN || value.isInfinite) {
                  return false;
                }
              }
            }
          }
        }
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// 序列化状态数据
  Map<String, dynamic> _serializeState(MeteorologyState state) {
    final serialized = <String, dynamic>{};
    
    for (final variable in MeteorologyVariable.values) {
      final data = state.grid.getVariableData(variable);
      if (data != null) {
        serialized[variable.name] = data;
      }
    }
    
    serialized['timestamp'] = state.timestamp.toIso8601String();
    serialized['isSimulating'] = state.isSimulating;
    serialized['simulationSpeed'] = state.simulationSpeed;
    
    return serialized;
  }
  
  /// 反序列化状态数据
  MeteorologyState _deserializeState(Map<String, dynamic> data) {
    // 这里需要根据实际的MeteorologyState构造函数来实现
    // 简化实现，实际使用时需要完整实现
    final grid = MeteorologyGrid(
      nx: data['gridNX'] ?? 100,
      ny: data['gridNY'] ?? 100,
      nz: data['gridNZ'] ?? 20,
    );
    
    // 恢复网格数据
    for (final variable in MeteorologyVariable.values) {
      final variableData = data[variable.name];
      if (variableData != null) {
        grid.setVariableData(variable, variableData);
      }
    }
    
    return MeteorologyState(
      grid: grid,
      timestamp: DateTime.parse(data['timestamp']),
      isSimulating: data['isSimulating'] ?? false,
      simulationSpeed: data['simulationSpeed']?.toDouble() ?? 1.0,
    );
  }
  
  /// 生成元数据
  Map<String, dynamic> _generateMetadata(MeteorologyState state) {
    return {
      'gridSize': '${state.grid.nx}x${state.grid.ny}x${state.grid.nz}',
      'totalGridPoints': state.grid.nx * state.grid.ny * state.grid.nz,
      'variables': MeteorologyVariable.values.map((v) => v.name).toList(),
      'isSimulating': state.isSimulating,
      'simulationSpeed': state.simulationSpeed,
    };
  }
  
  /// 清理文件名
  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').toLowerCase();
  }
  
  /// 版本兼容性检查
  bool _isVersionCompatible(String? version) {
    if (version == null) return false;
    
    // 简化的版本检查
    final currentVersion = AppConfig.version;
    return version == currentVersion || 
           version.startsWith('1.') || 
           version.startsWith('2.');
  }
  
  /// 加载已保存状态列表
  Future<void> _loadSavedStatesList() async {
    try {
      final savesDir = Directory('$_dataDirectory/saves');
      final files = await savesDir.list().toList();
      
      for (final file in files) {
        if (file is File && file.path.endsWith('.json')) {
          try {
            final content = await file.readAsString();
            final saveData = jsonDecode(content);
            final name = saveData['name'];
            final timestamp = DateTime.parse(saveData['timestamp']);
            
            _saveTimestamps[name] = timestamp;
          } catch (e) {
            print('Failed to load save file metadata: ${file.path}');
          }
        }
      }
    } catch (e) {
      print('Failed to load saved states list: $e');
    }
  }
  
  /// 清理旧的自动保存文件
  Future<void> _cleanupAutoSaves() async {
    try {
      final autoSaves = _saveTimestamps.entries
          .where((entry) => entry.key.startsWith('autosave_'))
          .toList();
      
      if (autoSaves.length <= 10) return;
      
      // 按时间排序，删除最旧的
      autoSaves.sort((a, b) => a.value.compareTo(b.value));
      
      for (int i = 0; i < autoSaves.length - 10; i++) {
        await deleteState(autoSaves[i].key);
      }
    } catch (e) {
      print('Failed to cleanup auto saves: $e');
    }
  }
  
  /// 记录操作日志
  Future<void> _logOperation(String operation, String target, String status, String message) async {
    try {
      if (!AppConfig.enableLogging) return;
      
      final logFile = File('$_dataDirectory/logs/operations.log');
      final timestamp = DateTime.now().toIso8601String();
      final logEntry = '[$timestamp] $operation:$target:$status - $message\n';
      
      await logFile.writeAsString(logEntry, mode: FileMode.append);
    } catch (e) {
      print('Failed to write log: $e');
    }
  }
  
  /// 导出为JSON格式
  String _exportToJson(MeteorologyState state, String name) {
    final exportData = {
      'name': name,
      'exportTime': DateTime.now().toIso8601String(),
      'version': AppConfig.version,
      'state': _serializeState(state),
      'metadata': _generateMetadata(state),
    };
    
    return const JsonEncoder.withIndent('  ').convert(exportData);
  }
  
  /// 导出为CSV格式
  String _exportToCsv(MeteorologyState state) {
    final buffer = StringBuffer();
    
    // CSV头部
    buffer.writeln('Variable,Level,I,J,K,Value,Timestamp');
    
    final timestamp = state.timestamp.toIso8601String();
    
    // 写入数据
    for (final variable in MeteorologyVariable.values) {
      final data = state.grid.getVariableData(variable);
      if (data != null) {
        for (int k = 0; k < state.grid.nz; k++) {
          for (int j = 0; j < state.grid.ny; j++) {
            for (int i = 0; i < state.grid.nx; i++) {
              buffer.writeln('${variable.name},$k,$j,$i,${data[k][j][i]},$timestamp');
            }
          }
        }
      }
    }
    
    return buffer.toString();
  }
  
  /// 导出为文本格式
  String _exportToText(MeteorologyState state) {
    final buffer = StringBuffer();
    
    buffer.writeln('=== 气象状态导出 ===');
    buffer.writeln('导出时间: ${DateTime.now().toIso8601String()}');
    buffer.writeln('版本: ${AppConfig.version}');
    buffer.writeln('');
    
    buffer.writeln('网格信息:');
    buffer.writeln('  尺寸: ${state.grid.nx} x ${state.grid.ny} x ${state.grid.nz}');
    buffer.writeln('  总点数: ${state.grid.nx * state.grid.ny * state.grid.nz}');
    buffer.writeln('');
    
    buffer.writeln('状态信息:');
    buffer.writeln('  时间戳: ${state.timestamp.toIso8601String()}');
    buffer.writeln('  模拟状态: ${state.isSimulating ? "运行中" : "已停止"}');
    buffer.writeln('  模拟速度: ${state.simulationSpeed}x');
    buffer.writeln('');
    
    buffer.writeln('变量统计:');
    for (final variable in MeteorologyVariable.values) {
      final data = state.grid.getVariableData(variable);
      if (data != null) {
        double minVal = double.infinity;
        double maxVal = -double.infinity;
        double sum = 0.0;
        int count = 0;
        
        for (int k = 0; k < state.grid.nz; k++) {
          for (int j = 0; j < state.grid.ny; j++) {
            for (int i = 0; i < state.grid.nx; i++) {
              final value = data[k][j][i];
              minVal = math.min(minVal, value);
              maxVal = math.max(maxVal, value);
              sum += value;
              count++;
            }
          }
        }
        
        final avg = sum / count;
        buffer.writeln('  ${variable.name}:');
        buffer.writeln('    最小值: ${minVal.toStringAsFixed(4)}');
        buffer.writeln('    最大值: ${maxVal.toStringAsFixed(4)}');
        buffer.writeln('    平均值: ${avg.toStringAsFixed(4)}');
        buffer.writeln('');
      }
    }
    
    return buffer.toString();
  }
  
  /// 从JSON导入
  MeteorologyState _importFromJson(String content) {
    final data = jsonDecode(content);
    return _deserializeState(data['state']);
  }
  
  /// 从CSV导入
  MeteorologyState _importFromCsv(String content) {
    // 简化的CSV导入实现
    final lines = content.split('\n');
    final grid = MeteorologyGrid(
      nx: AppConfig.gridNX,
      ny: AppConfig.gridNY,
      nz: AppConfig.gridNZ,
    );
    
    // 这里需要完整的CSV解析逻辑
    // 简化实现，实际使用时需要完整解析
    
    return MeteorologyState(
      grid: grid,
      timestamp: DateTime.now(),
      isSimulating: false,
      simulationSpeed: 1.0,
    );
  }
}

/// 数据管理异常
class DataManagerException implements Exception {
  final String message;
  DataManagerException(this.message);
  
  @override
  String toString() => 'DataManagerException: $message';
}