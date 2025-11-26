import 'dart:convert';
import 'package:flutter/services.dart';

import '../core/app_config.dart';
import '../models/meteorology_state.dart';

class DataManager {
  static const String _initialStatePath = 'assets/sample_data/initial_state.json';
  
  // 加载初始状态数据
  static Future<Map<String, dynamic>> loadInitialState() async {
    try {
      final String jsonString = await rootBundle.loadString(_initialStatePath);
      final Map<String, dynamic> data = json.decode(jsonString);
      return data;
    } catch (e) {
      throw Exception('加载初始状态数据失败: $e');
    }
  }
  
  // 根据配置数据初始化网格
  static MeteorologyGrid createGridFromConfig(Map<String, dynamic> config) {
    final gridConfig = config['grid'];
    final nx = gridConfig['nx'] as int;
    final ny = gridConfig['ny'] as int;
    final nz = gridConfig['nz'] as int;
    
    final grid = MeteorologyGrid(nx: nx, ny: ny, nz: nz);
    
    // 应用初始条件
    final initialConditions = config['initial_conditions'];
    _applyInitialConditions(grid, initialConditions);
    
    // 应用扰动
    final perturbations = config['perturbations'] as List?;
    if (perturbations != null) {
      _applyPerturbations(grid, perturbations);
    }
    
    return grid;
  }
  
  // 应用初始条件
  static void _applyInitialConditions(MeteorologyGrid grid, 
                                      Map<String, dynamic> conditions) {
    final nx = grid.nx;
    final ny = grid.ny;
    final nz = grid.nz;
    
    // 温度初始化
    final tempConfig = conditions['temperature'];
    final surfaceTemp = tempConfig['surface'] as double;
    final lapseRate = tempConfig['lapse_rate'] as double;
    
    for (int k = 0; k < nz; k++) {
      for (int j = 0; j < ny; j++) {
        for (int i = 0; i < nx; i++) {
          final altitude = k * 200.0; // 假设每层200米
          final temperature = surfaceTemp - lapseRate * altitude / 1000.0;
          grid.setValue(MeteorologyVariable.temperature, i, j, k, temperature);
        }
      }
    }
    
    // 气压初始化
    final pressureConfig = conditions['pressure'];
    final surfacePressure = pressureConfig['surface'] as double;
    
    for (int k = 0; k < nz; k++) {
      for (int j = 0; j < ny; j++) {
        for (int i = 0; i < nx; i++) {
          final altitude = k * 200.0;
          final pressure = surfacePressure * 
              math.exp(-altitude * AppConfig.gravity / (AppConfig.gasConstant * surfaceTemp));
          grid.setValue(MeteorologyVariable.pressure, i, j, k, pressure);
        }
      }
    }
    
    // 湿度初始化
    final humidityConfig = conditions['humidity'];
    final surfaceHumidity = humidityConfig['surface'] as double;
    
    for (int k = 0; k < nz; k++) {
      for (int j = 0; j < ny; j++) {
        for (int i = 0; i < nx; i++) {
          final altitude = k * 200.0;
          final humidity = surfaceHumidity * math.exp(-altitude / 8000.0); // 8km标高
          grid.setValue(MeteorologyVariable.humidity, i, j, k, humidity);
          
          // 计算水汽混合比
          final pressure = grid.getValue(MeteorologyVariable.pressure, i, j, k);
          final temperature = grid.getValue(MeteorologyVariable.temperature, i, j, k);
          final vaporPressure = humidity * pressure / 100.0;
          final mixingRatio = 0.622 * vaporPressure / (pressure - vaporPressure);
          grid.setValue(MeteorologyVariable.qvapor, i, j, k, mixingRatio);
        }
      }
    }
    
    // 风场初始化
    final windConfig = conditions['wind'];
    final uConfig = windConfig['u_component'];
    final vConfig = windConfig['v_component'];
    
    for (int k = 0; k < nz; k++) {
      for (int j = 0; j < ny; j++) {
        for (int i = 0; i < nx; i++) {
          final altitude = k * 200.0;
          
          // 东西风分量（包含垂直切变）
          final uSurface = uConfig['surface'] as double;
          final uShear = uConfig['shear'] as double;
          final uWind = uSurface + uShear * altitude;
          grid.setValue(MeteorologyVariable.uWind, i, j, k, uWind);
          
          // 南北风分量（包含垂直切变）
          final vSurface = vConfig['surface'] as double;
          final vShear = vConfig['shear'] as double;
          final vWind = vSurface + vShear * altitude;
          grid.setValue(MeteorologyVariable.vWind, i, j, k, vWind);
          
          // 垂直风分量（初始为0）
          grid.setValue(MeteorologyVariable.wWind, i, j, k, 0.0);
        }
      }
    }
  }
  
  // 应用扰动
  static void _applyPerturbations(MeteorologyGrid grid, List perturbations) {
    for (final perturbation in perturbations) {
      final type = perturbation['type'] as String;
      final center = perturbation['center'] as Map<String, dynamic>;
      final cx = center['x'] as int;
      final cy = center['y'] as int;
      final cz = center['z'] as int;
      
      switch (type) {
        case 'thermal':
          _applyThermalPerturbation(grid, perturbation, cx, cy, cz);
          break;
        case 'vorticity':
          _applyVorticityPerturbation(grid, perturbation, cx, cy, cz);
          break;
      }
    }
  }
  
  // 应用热力扰动
  static void _applyThermalPerturbation(MeteorologyGrid grid, Map perturbation,
                                       int cx, int cy, int cz) {
    final amplitude = perturbation['amplitude'] as double;
    final radius = perturbation['radius'] as double;
    
    for (int k = 0; k < grid.nz; k++) {
      for (int j = 0; j < grid.ny; j++) {
        for (int i = 0; i < grid.nx; i++) {
          final distance = math.sqrt(
            math.pow(i - cx, 2) + math.pow(j - cy, 2) + math.pow(k - cz, 2)
          );
          
          if (distance < radius) {
            final gaussian = math.exp(-math.pow(distance, 2) / (2 * math.pow(radius / 3, 2)));
            final currentTemp = grid.getValue(MeteorologyVariable.temperature, i, j, k);
            final newTemp = currentTemp + amplitude * gaussian;
            grid.setValue(MeteorologyVariable.temperature, i, j, k, newTemp);
          }
        }
      }
    }
  }
  
  // 应用涡度扰动
  static void _applyVorticityPerturbation(MeteorologyGrid grid, Map perturbation,
                                         int cx, int cy, int cz) {
    final strength = perturbation['strength'] as double;
    final radius = perturbation['radius'] as double;
    
    for (int k = 0; k < grid.nz; k++) {
      for (int j = 0; j < grid.ny; j++) {
        for (int i = 0; i < grid.nx; i++) {
          final dx = i - cx;
          final dy = j - cy;
          final distance = math.sqrt(dx * dx + dy * dy);
          
          if (distance < radius && distance > 0) {
            final gaussian = math.exp(-math.pow(distance, 2) / (2 * math.pow(radius / 3, 2)));
            final tangentialSpeed = strength * distance * gaussian;
            
            // 将切向速度转换为u和v分量
            final uWind = grid.getValue(MeteorologyVariable.uWind, i, j, k);
            final vWind = grid.getValue(MeteorologyVariable.vWind, i, j, k);
            
            final newUWind = uWind - tangentialSpeed * dy / distance;
            final newVWind = vWind + tangentialSpeed * dx / distance;
            
            grid.setValue(MeteorologyVariable.uWind, i, j, k, newUWind);
            grid.setValue(MeteorologyVariable.vWind, i, j, k, newVWind);
          }
        }
      }
    }
  }
}

import 'dart:math' as math;