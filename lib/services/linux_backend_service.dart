import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Linux后端数据服务
/// 连接到Linux环境的气象计算后端
class LinuxBackendService {
  static const String _baseUrl = 'http://localhost:8080';
  static const Duration _timeout = Duration(seconds: 10);
  
  /// 获取雷达数据
  static Future<Map<String, dynamic>> getRadarData({int timeStep = 0}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/weather/radar?time=$timeStep'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load radar data: ${response.statusCode}');
      }
    } catch (e) {
      print('Linux backend error: $e');
      return _getFallbackRadarData(timeStep);
    }
  }
  
  /// 获取WRF预报数据
  static Future<Map<String, dynamic>> getWRFData({
    int timeStep = 0, 
    String variable = 'temperature'
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/weather/wrf?time=$timeStep&var=$variable'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load WRF data: ${response.statusCode}');
      }
    } catch (e) {
      print('Linux backend error: $e');
      return _getFallbackWRFData(timeStep, variable);
    }
  }
  
  /// 获取系统状态
  static Future<Map<String, dynamic>> getSystemStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/weather/status'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get system status: ${response.statusCode}');
      }
    } catch (e) {
      print('Linux backend error: $e');
      return _getFallbackStatus();
    }
  }
  
  /// 运行WRF模拟
  static Future<bool> runWRFModel() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/weather/wrf/run'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);
      
      return response.statusCode == 200;
    } catch (e) {
      print('Linux backend error: $e');
      return false;
    }
  }
  
  /// 检查后端连接状态
  static Future<bool> checkConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/weather/status'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 3));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  /// 计算大气对流参数
  static Map<String, double> _calculateConvectionParameters(
    List<List<double>> temperature,
    List<List<double>> humidity,
    List<List<double>> uWind,
    List<List<double>> vWind,
    int i, int j
  ) {
    // 从地面到高层的大气廓线
    List<double> tempProfile = [];
    List<double> humProfile = [];
    List<double> heightProfile = [];
    
    for (int k = 0; k < temperature.length; k++) {
      tempProfile.add(temperature[k][i]);
      humProfile.add(humidity[k][i]);
      heightProfile.add(k * 1000.0); // 每层1km
    }
    
    // 计算CAPE (对流有效位能)
    double cape = _calculateCAPE(tempProfile, humProfile, heightProfile);
    
    // 计算CIN (对流抑制能)
    double cin = _calculateCIN(tempProfile, humProfile, heightProfile);
    
    // 计算风切变
    double shear0_6km = _calculateWindShear(uWind, vWind, 0, 6, i, j);
    double shear0_1km = _calculateWindShear(uWind, vWind, 0, 1, i, j);
    
    // 计算抬升指数
    double li = _calculateLiftedIndex(tempProfile, humProfile, heightProfile);
    
    // 计算K指数
    double kIndex = _calculateKIndex(tempProfile, humProfile, heightProfile);
    
    // 计算TT指数
    double ttIndex = _calculateTTIndex(tempProfile, humProfile, heightProfile);
    
    return {
      'cape': cape,
      'cin': cin,
      'shear_0_6km': shear0_6km,
      'shear_0_1km': shear0_1km,
      'lifted_index': li,
      'k_index': kIndex,
      'tt_index': ttIndex,
    };
  }
  
  /// 计算CAPE (对流有效位能)
  static double _calculateCAPE(
    List<double> tempProfile,
    List<double> humProfile,
    List<double> heightProfile
  ) {
    const double g = 9.81;
    const double cp = 1004.0;
    const double Rd = 287.0;
    const double Rv = 461.0;
    
    double cape = 0.0;
    double parcelTemp = tempProfile[0]; // 气块初始温度
    double parcelPressure = 100000.0; // 地面气压
    
    // 计算地面混合比
    double eSat = 610.78 * exp(17.27 * (parcelTemp - 273.15) / (parcelTemp - 273.15 + 237.3));
    double mixingRatio = 0.622 * eSat / (parcelPressure - eSat);
    
    for (int k = 1; k < tempProfile.length; k++) {
      double envTemp = tempProfile[k];
      double envHum = humProfile[k];
      double height = heightProfile[k];
      
      // 气块绝热上升温度
      double pressure = parcelPressure * exp(-g * height / (Rd * parcelTemp));
      double parcelTempLifted = parcelTemp * pow(pressure / parcelPressure, 0.286);
      
      // 环境虚温
      double eEnv = 610.78 * exp(17.27 * (envTemp - 273.15) / (envTemp - 273.15 + 237.3));
      double mixingRatioEnv = 0.622 * eEnv * envHum / (pressure - eEnv * envHum);
      double virtualTempEnv = envTemp * (1 + 0.61 * mixingRatioEnv);
      
      // 气块虚温
      double virtualTempParcel = parcelTempLifted * (1 + 0.61 * mixingRatio);
      
      // 如果气块比环境暖，累积CAPE
      if (virtualTempParcel > virtualTempEnv) {
        double dz = height - heightProfile[k-1];
        cape += g * dz * (virtualTempParcel - virtualTempEnv) / virtualTempEnv;
      }
      
      parcelTemp = parcelTempLifted;
    }
    
    return cape;
  }
  
  /// 计算CIN (对流抑制能)
  static double _calculateCIN(
    List<double> tempProfile,
    List<double> humProfile,
    List<double> heightProfile
  ) {
    const double g = 9.81;
    const double cp = 1004.0;
    const double Rd = 287.0;
    
    double cin = 0.0;
    double parcelTemp = tempProfile[0];
    double parcelPressure = 100000.0;
    
    // 计算地面混合比
    double eSat = 610.78 * exp(17.27 * (parcelTemp - 273.15) / (parcelTemp - 273.15 + 237.3));
    double mixingRatio = 0.622 * eSat / (parcelPressure - eSat);
    
    for (int k = 1; k < tempProfile.length && k < 10; k++) { // 只计算低层
      double envTemp = tempProfile[k];
      double height = heightProfile[k];
      
      // 气块绝热上升温度
      double pressure = parcelPressure * exp(-g * height / (Rd * parcelTemp));
      double parcelTempLifted = parcelTemp * pow(pressure / parcelPressure, 0.286);
      
      // 如果气块比环境冷，累积CIN
      if (parcelTempLifted < envTemp) {
        double dz = height - heightProfile[k-1];
        cin += g * dz * (envTemp - parcelTempLifted) / envTemp;
      }
      
      parcelTemp = parcelTempLifted;
    }
    
    return cin;
  }
  
  /// 计算风切变
  static double _calculateWindShear(
    List<List<double>> uWind,
    List<List<double>> vWind,
    int level1, int level2,
    int i, int j
  ) {
    double u1 = uWind[level1][i];
    double v1 = vWind[level1][i];
    double u2 = uWind[level2][i];
    double v2 = vWind[level2][i];
    
    double du = u2 - u1;
    double dv = v2 - v1;
    
    return sqrt(du * du + dv * dv);
  }
  
  /// 计算抬升指数
  static double _calculateLiftedIndex(
    List<double> tempProfile,
    List<double> humProfile,
    List<double> heightProfile
  ) {
    // 将地面气块抬升到500hPa
    double parcelTemp = tempProfile[0];
    double parcelPressure = 100000.0;
    double targetPressure = 50000.0; // 500hPa
    
    // 绝热膨胀到500hPa
    double parcelTemp500 = parcelTemp * pow(targetPressure / parcelPressure, 0.286);
    
    // 找到500hPa环境温度
    double envTemp500 = tempProfile[5]; // 假设第5层接近500hPa
    
    return envTemp500 - parcelTemp500; // LI = 环境温度 - 气块温度
  }
  
  /// 计算K指数
  static double _calculateKIndex(
    List<double> tempProfile,
    List<double> humProfile,
    List<double> heightProfile
  ) {
    // K指数 = (850hPa温度 - 500hPa温度) + 850hPa露点 - 700hPa露点
    double t850 = tempProfile[1]; // 850hPa
    double t500 = tempProfile[5]; // 500hPa
    double t700 = tempProfile[3]; // 700hPa
    
    // 简化露点计算
    double td850 = t850 - (1 - humProfile[1]) * 20;
    double td700 = t700 - (1 - humProfile[3]) * 20;
    
    return (t850 - t500) + td850 - td700;
  }
  
  /// 计算TT指数
  static double _calculateTTIndex(
    List<double> tempProfile,
    List<double> humProfile,
    List<double> heightProfile
  ) {
    // TT指数 = 总指数 = (850hPa温度 + 850hPa露点) - 2*500hPa温度
    double t850 = tempProfile[1];
    double t500 = tempProfile[5];
    double td850 = t850 - (1 - humProfile[1]) * 20;
    
    return (t850 + td850) - 2 * t500;
  }
  
  /// 判断雷暴类型和强度
  static Map<String, dynamic> _classifyThunderstorm(
    Map<String, double> convectionParams
  ) {
    double cape = convectionParams['cape']!;
    double cin = convectionParams['cin']!;
    double shear = convectionParams['shear_0_6km']!;
    double li = convectionParams['lifted_index']!;
    double kIndex = convectionParams['k_index']!;
    
    String stormType = 'none';
    double intensity = 0.0;
    List<String> features = [];
    
    // 雷暴判定条件
    if (cape > 0 && cape < 1000) {
      if (li < 0 && kIndex > 20) {
        stormType = 'single_cell';
        intensity = cape / 1000.0;
        features.add('普通单体雷暴');
      }
    } else if (cape >= 1000 && cape < 2500) {
      if (shear > 15 && li < -2) {
        stormType = 'multi_cell';
        intensity = 0.5 + (cape - 1000) / 3000.0;
        features.add('多单体雷暴');
        features.add('中等强度');
      } else if (li < -3) {
        stormType = 'pulse_severe';
        intensity = 0.6 + cape / 4000.0;
        features.add('脉冲强雷暴');
      }
    } else if (cape >= 2500 && cape < 4000) {
      if (shear > 20 && li < -4) {
        stormType = 'supercell';
        intensity = 0.7 + (cape - 2500) / 5000.0;
        features.add('超级单体雷暴');
        features.add('强旋转');
        if (shear > 25) {
          features.add('龙卷风可能');
        }
      }
    } else if (cape >= 4000) {
      if (shear > 25 && li < -6) {
        stormType = 'extreme_severe';
        intensity = 0.9 + min(0.1, (cape - 4000) / 10000.0);
        features.add('极端强雷暴');
        features.add('灾害性天气');
        features.add('大冰雹可能');
        features.add('强龙卷风可能');
      }
    }
    
    // 特殊环境条件
    if (cin < -50) {
      features.add('强对流抑制');
    } else if (cin > 100) {
      features.add('弱对流抑制');
    }
    
    if (shear > 30) {
      features.add('强风切变');
    }
    
    return {
      'type': stormType,
      'intensity': min(1.0, intensity),
      'features': features,
      'parameters': convectionParams,
    };
  }
  
  /// 生成雷暴雷达回波
  static List<List<double>> _generateThunderstormEcho(
    Map<String, dynamic> stormInfo,
    int gridSize,
    int centerX, int centerY,
    int timeStep
  ) {
    List<List<double>> reflectivity = List.generate(
      gridSize, (i) => List.filled(gridSize, 0.0)
    );
    
    String stormType = stormInfo['type'];
    double intensity = stormInfo['intensity'];
    
    switch (stormType) {
      case 'single_cell':
        _generateSingleCell(reflectivity, gridSize, centerX, centerY, intensity, timeStep);
        break;
      case 'multi_cell':
        _generateMultiCell(reflectivity, gridSize, centerX, centerY, intensity, timeStep);
        break;
      case 'supercell':
        _generateSupercell(reflectivity, gridSize, centerX, centerY, intensity, timeStep);
        break;
      case 'extreme_severe':
        _generateExtremeSevere(reflectivity, gridSize, centerX, centerY, intensity, timeStep);
        break;
    }
    
    return reflectivity;
  }
  
  /// 生成单体雷暴
  static void _generateSingleCell(
    List<List<double>> reflectivity,
    int gridSize,
    int centerX, int centerY,
    double intensity,
    int timeStep
  ) {
    double maxReflectivity = 45 + intensity * 20;
    double stormRadius = 8 + intensity * 5;
    
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        double dx = j - centerX;
        double dy = i - centerY;
        double distance = sqrt(dx * dx + dy * dy);
        
        if (distance < stormRadius) {
          // 对流核
          double coreIntensity = maxReflectivity * exp(-distance * distance / (2 * stormRadius * stormRadius));
          
          // 生命周期演化
          double lifeCycle = 1.0 - 0.3 * sin(timeStep * 0.2);
          
          // 湍流扰动
          double turbulence = (Math.random() - 0.5) * 5;
          
          reflectivity[i][j] = max(0, coreIntensity * lifeCycle + turbulence);
        }
      }
    }
  }
  
  /// 生成多单体雷暴
  static void _generateMultiCell(
    List<List<double>> reflectivity,
    int gridSize,
    int centerX, int centerY,
    double intensity,
    int timeStep
  ) {
    // 主单体
    _generateSingleCell(reflectivity, gridSize, centerX, centerY, intensity, timeStep);
    
    // 次生单体
    int numCells = 2 + (intensity * 3).toInt();
    for (int c = 0; c < numCells; c++) {
      double offsetX = (c - numCells/2) * 15 * cos(timeStep * 0.05);
      double offsetY = (c - numCells/2) * 10 * sin(timeStep * 0.05);
      int cellX = (centerX + offsetX).toInt() % gridSize;
      int cellY = (centerY + offsetY).toInt() % gridSize;
      
      double cellIntensity = intensity * 0.7;
      _generateSingleCell(reflectivity, gridSize, cellX, cellY, cellIntensity, timeStep + c);
    }
  }
  
  /// 生成超级单体雷暴
  static void _generateSupercell(
    List<List<double>> reflectivity,
    int gridSize,
    int centerX, int centerY,
    double intensity,
    int timeStep
  ) {
    // 主对流核
    double maxReflectivity = 55 + intensity * 25;
    double coreRadius = 10 + intensity * 8;
    
    // 前侧下沉气流区
    int ffwdX = centerX + 15;
    int ffwdY = centerY - 5;
    
    // 后侧上升气流区
    int rearX = centerX - 10;
    int rearY = centerY + 8;
    
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        // 主对流核
        double dx = j - centerX;
        double dy = i - centerY;
        double distance = sqrt(dx * dx + dy * dy);
        
        if (distance < coreRadius) {
          double coreIntensity = maxReflectivity * exp(-distance * distance / (2.5 * coreRadius * coreRadius));
          
          // 悬垂回波特征
          double overhang = 5 * exp(-pow(distance - coreRadius*0.7, 2) / 20);
          
          reflectivity[i][j] = coreIntensity + overhang;
        }
        
        // 前侧下沉气流
        double dxffwd = j - ffwdX;
        double dyffwd = i - ffwdY;
        double distffwd = sqrt(dxffwd * dxffwd + dyffwd * dyffwd);
        
        if (distffwd < 8) {
          double ffwdIntensity = 35 * exp(-distffwd * distffwd / 32);
          reflectivity[i][j] = max(reflectivity[i][j], ffwdIntensity);
        }
        
        // 后侧上升气流
        double dxrear = j - rearX;
        double dyrear = i - rearY;
        double distrear = sqrt(dxrear * dxrear + dyrear * dyrear);
        
        if (distrear < 6) {
          double rearIntensity = 40 * exp(-distrear * distrear / 18);
          reflectivity[i][j] = max(reflectivity[i][j], rearIntensity);
        }
        
        // 钩状回波特征
        double hookX = centerX + 12 * cos(timeStep * 0.1);
        double hookY = centerY + 12 * sin(timeStep * 0.1);
        double dxhook = j - hookX;
        double dyhook = i - hookY;
        double disthook = sqrt(dxhook * dxhook + dyhook * dyhook);
        
        if (disthook < 5) {
          double hookIntensity = 30 * exp(-disthook * disthook / 8);
          reflectivity[i][j] = max(reflectivity[i][j], hookIntensity);
        }
      }
    }
  }
  
  /// 生成极端强雷暴
  static void _generateExtremeSevere(
    List<List<double>> reflectivity,
    int gridSize,
    int centerX, int centerY,
    double intensity,
    int timeStep
  ) {
    // 超级单体结构
    _generateSupercell(reflectivity, gridSize, centerX, centerY, intensity, timeStep);
    
    // 增强反射率核心
    double maxReflectivity = 65 + intensity * 15;
    
    // 降雹特征
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        double dx = j - centerX;
        double dy = i - centerY;
        double distance = sqrt(dx * dx + dy * dy);
        
        if (distance < 5) {
          // 三体散射特征 (TBSS)
          double tbssAngle = atan2(dy, dx);
          double tbssDist = 20 + 10 * sin(timeStep * 0.15);
          int tbssX = (centerX + tbssDist * cos(tbssAngle)).toInt();
          int tbssY = (centerY + tbssDist * sin(tbssAngle)).toInt();
          
          if (tbssX >= 0 && tbssX < gridSize && tbssY >= 0 && tbssY < gridSize) {
            reflectivity[tbssY][tbssX] = max(reflectivity[tbssY][tbssX], 25);
          }
          
          // 增强核心反射率
          if (distance < 3) {
            reflectivity[i][j] = max(reflectivity[i][j], maxReflectivity);
          }
        }
      }
    }
    
    // 弓形回波特征
    double bowAngle = timeStep * 0.05;
    for (int b = 0; b < 20; b++) {
      double bowX = centerX + 25 * cos(bowAngle + b * 0.1);
      double bowY = centerY + 15 * sin(bowAngle + b * 0.1);
      
      if (bowX >= 0 && bowX < gridSize && bowY >= 0 && bowY < gridSize) {
        reflectivity[bowY.toInt()][bowX.toInt()] = 
          max(reflectivity[bowY.toInt()][bowX.toInt()], 45);
      }
    }
  }
  
  /// 获取雷达数据（备用方案）- 高真实度物理模型
  static Map<String, dynamic> _getFallbackRadarData(int timeStep) {
    final int gridSize = 100;
    List<List<double>> reflectivity = [];
    List<List<double>> velocity = [];
    List<List<double>> spectrumWidth = [];
    
    // 物理常数
    const double k = 0.93; // 雷达常数
    const double lambda = 0.10; // 波长 (m) - S波段
    const double beamWidth = 0.0175; // 波束宽度 (rad)
    const double nyquistVel = 30.0; // 尼奎斯特速度 (m/s)
    
    // 模拟风暴系统参数
    final stormCenterX = 50.0 + 10 * sin(timeStep * 0.1);
    final stormCenterY = 50.0 + 8 * cos(timeStep * 0.08);
    final stormIntensity = 50.0 + 20 * sin(timeStep * 0.05);
    final stormRadius = 15.0 + 5 * sin(timeStep * 0.15);
    
    // 模拟中气旋
    final mesocycloneX = 60.0 + 15 * cos(timeStep * 0.12);
    final mesocycloneY = 40.0 + 12 * sin(timeStep * 0.1);
    final mesocycloneStrength = 25.0 + 10 * sin(timeStep * 0.2);
    
    // 模拟锋面系统
    final frontPosition = 30.0 + 20 * timeStep * 0.02;
    final frontIntensity = 35.0 + 15 * sin(timeStep * 0.08);
    
    // 首先获取大气环境数据
    List<List<double>> tempProfile = [];
    List<List<double>> humProfile = [];
    List<List<double>> uWindProfile = [];
    List<List<double>> vWindProfile = [];
    
    // 生成大气廓线
    for (int k = 0; k < 20; k++) {
      List<double> tempLayer = [];
      List<double> humLayer = [];
      List<double> uWindLayer = [];
      List<double> vWindLayer = [];
      
      for (int i = 0; i < gridSize; i++) {
        for (int j = 0; j < gridSize; j++) {
          // 基础温度廓线
          double height = k * 1000.0;
          double baseTemp = 288.15 - 6.5 * height / 1000.0;
          
          // 地表影响
          Map<String, double> surface = _getSurfaceType(i, j, gridSize, gridSize);
          double surfaceInfluence = exp(-height / 2000.0);
          double temp = baseTemp + (surface['surface_temperature']! - 288.15) * surfaceInfluence;
          
          // 湿度
          double baseHum = 0.01 * exp(-height / 8000.0);
          double hum = baseHum + surface['moisture_availability']! * 0.005 * surfaceInfluence;
          
          // 风场
          double uWind = 10.0 * exp(-height / 10000.0);
          double vWind = 5.0 * sin(j * 0.1 + timeStep * 0.05) * exp(-height / 8000.0);
          
          tempLayer.add(temp);
          humLayer.add(hum);
          uWindLayer.add(uWind);
          vWindLayer.add(vWind);
        }
      }
      
      tempProfile.add(tempLayer);
      humProfile.add(humLayer);
      uWindProfile.add(uWindLayer);
      vWindProfile.add(vWindLayer);
    }
    
    // 初始化反射率场
    List<List<double>> baseReflectivity = List.generate(
      gridSize, (i) => List.filled(gridSize, 0.0)
    );
    
    // 扫描每个网格点，检查雷暴条件
    for (int i = 5; i < gridSize - 5; i += 10) {
      for (int j = 5; j < gridSize - 5; j += 10) {
        // 计算对流参数
        Map<String, double> convectionParams = _calculateConvectionParameters(
          tempProfile, humProfile, uWindProfile, vWindProfile, i, j
        );
        
        // 分类雷暴
        Map<String, dynamic> stormInfo = _classifyThunderstorm(convectionParams);
        
        if (stormInfo['type'] != 'none') {
          // 生成雷暴雷达回波
          List<List<double>> stormEcho = _generateThunderstormEcho(
            stormInfo, gridSize, i, j, timeStep
          );
          
          // 合并到总反射率场
          for (int si = 0; si < gridSize; si++) {
            for (int sj = 0; sj < gridSize; sj++) {
              baseReflectivity[si][sj] = max(baseReflectivity[si][sj], stormEcho[si][sj]);
            }
          }
        }
      }
    }
    
    // 应用空间平滑
    baseReflectivity = _applySpatialFilter(baseReflectivity);
    
    // 生成最终雷达数据
    for (int i = 0; i < gridSize; i++) {
      List<double> reflRow = [];
      List<double> velRow = [];
      List<double> specRow = [];
      
      for (int j = 0; j < gridSize; j++) {
        double totalReflectivity = baseReflectivity[i][j];
        
        // 添加其他天气系统
        double dx = j - stormCenterX;
        double dy = i - stormCenterY;
        double distance = sqrt(dx * dx + dy * dy);
        
        // 锋面系统
        double frontReflectivity = 0.0;
        if (abs(j - frontPosition) < 5) {
          double frontFactor = exp(-pow(j - frontPosition, 2) / 8);
          frontReflectivity = frontIntensity * frontFactor;
        }
        
        // 地形降水
        double terrainEffect = 0.0;
        double terrainHeight = 500 * sin(j * 0.1) * cos(i * 0.1);
        if (terrainHeight > 200) {
          terrainEffect = 5 * (terrainHeight / 500);
        }
        
        // 综合反射率
        totalReflectivity = max(totalReflectivity, frontReflectivity + terrainEffect);
        
        // 添加噪声
        double measurementNoise = (Math.random() - 0.5) * 2;
        totalReflectivity += measurementNoise;
        totalReflectivity = max(0, min(80, totalReflectivity));
        
        // 计算速度场
        double environmentalWind = 15 * sin(i * 0.05 + timeStep * 0.02);
        double stormInflow = -20 * exp(-distance / stormRadius) * (dx / max(distance, 1));
        double totalVelocity = environmentalWind + stormInflow;
        
        // 速度折叠处理
        totalVelocity = ((totalVelocity + nyquistVel) % (2 * nyquistVel)) - nyquistVel;
        
        // 谱宽计算
        double turbulenceIntensity = abs(totalVelocity) * 0.1 + 
                                   2 * sin(distance * 0.5 + timeStep * 0.2);
        double spectrumWidth = max(0.5, min(15, turbulenceIntensity));
        
        // 地物杂波
        if (distance < 5) {
          double clutterIntensity = 30 * exp(-distance / 2);
          totalReflectivity = max(totalReflectivity, clutterIntensity);
          totalVelocity *= 0.1;
          spectrumWidth *= 0.3;
        }
        
        reflRow.add(totalReflectivity);
        velRow.add(totalVelocity);
        specRow.add(spectrumWidth);
      }
      
      reflectivity.add(reflRow);
      velocity.add(velRow);
      spectrumWidth.add(specRow);
    }
    
    // 应用空间平滑滤波器
    reflectivity = _applySpatialFilter(reflectivity);
    velocity = _applySpatialFilter(velocity);
    
    return {
      'time_step': timeStep,
      'reflectivity': reflectivity,
      'velocity': velocity,
      'spectrum_width': spectrumWidth,
      'metadata': {
        'storm_center': {'x': stormCenterX, 'y': stormCenterY},
        'storm_intensity': stormIntensity,
        'mesocyclone': {'x': mesocycloneX, 'y': mesocycloneY, 'strength': mesocycloneStrength},
        'front_position': frontPosition,
        'nyquist_velocity': nyquistVel,
        'wavelength': lambda,
        'beam_width': beamWidth,
      },
      'fallback': true,
      'message': 'Using enhanced physics-based radar simulation'
    };
  }
  
  /// 应用空间滤波器 - 模拟雷达波束平滑效应
  static List<List<double>> _applySpatialFilter(List<List<double>> data) {
    final int size = data.length;
    final List<List<double>> filtered = List.generate(size, (i) => List.filled(size, 0.0));
    
    // 3x3高斯滤波器
    const List<List<double>> kernel = [
      [1/16, 2/16, 1/16],
      [2/16, 4/16, 2/16],
      [1/16, 2/16, 1/16]
    ];
    
    for (int i = 1; i < size - 1; i++) {
      for (int j = 1; j < size - 1; j++) {
        double sum = 0.0;
        for (int ki = -1; ki <= 1; ki++) {
          for (int kj = -1; kj <= 1; kj++) {
            sum += data[i + ki][j + kj] * kernel[ki + 1][kj + 1];
          }
        }
        filtered[i][j] = sum;
      }
    }
    
    // 边界处理
    for (int i = 0; i < size; i++) {
      filtered[i][0] = data[i][0];
      filtered[i][size-1] = data[i][size-1];
      filtered[0][i] = data[0][i];
      filtered[size-1][i] = data[size-1][i];
    }
    
    return filtered;
  }
  
  /// 获取WRF数据（备用方案）- 高真实度数值天气预报模型
  static Map<String, dynamic> _getFallbackWRFData(int timeStep, String variable) {
    // 如果是蒸发相关变量，使用增强版模拟
    if (['evaporation', 'surface_temperature', 'sensible_heat_flux', 
         'latent_heat_flux', 'boundary_layer_height', 'soil_moisture'].contains(variable)) {
      return _getEnhancedWRFData(timeStep, variable);
    }
    
    // 其他变量使用标准模拟
    final int nx = 50, ny = 50, nz = 20;
    List<List<List<List<double>>>> data = [];
    
    // 物理常数
    const double g = 9.81; // 重力加速度 (m/s²)
    const double cp = 1004.0; // 定压比热 (J/kg/K)
    const double R = 287.0; // 干空气气体常数 (J/kg/K)
    const double Lv = 2.5e6; // 水汽潜热 (J/kg)
    const double omega = 7.292e-5; // 地球角速度 (rad/s)
    const double p0 = 100000.0; // 参考气压 (Pa)
    
    // 模拟区域参数
    const double dx = 20000.0; // 网格间距 (m)
    const double dy = 20000.0;
    const double dz = 1000.0;
    
    // 模拟天气系统
    final double lowPressureX = 25.0 + 10 * sin(timeStep * 0.05);
    final double lowPressureY = 25.0 + 8 * cos(timeStep * 0.04);
    final double lowPressureDepth = 980.0 + 15 * sin(timeStep * 0.03);
    
    final double jetStreamY = 10.0 + 5 * sin(timeStep * 0.02);
    final double jetStreamIntensity = 40.0 + 20 * cos(timeStep * 0.06);
    
    final double coldFrontX = 10.0 + 30 * timeStep * 0.01;
    final double coldFrontIntensity = 15.0 * sin(timeStep * 0.08);
    
    for (int k = 0; k < nz; k++) {
      List<List<double>> layer = [];
      double height = k * dz;
      double pressure = p0 * pow(1 - 0.0065 * height / 288.15, 5.255);
      
      for (int i = 0; i < ny; i++) {
        List<double> row = [];
        
        for (int j = 0; j < nx; j++) {
          // 计算地理坐标
          double x = j * dx;
          double y = i * dy;
          double lat = 35.0 + y / 111000.0; // 纬度
          double lon = 115.0 + x / (111000.0 * cos(lat * pi / 180)); // 经度
          
          // 科里奥利参数
          double f = 2 * omega * sin(lat * pi / 180);
          
          double value = 0.0;
          
          switch (variable) {
            case 'temperature':
              // 标准大气温度廓线
              double T_std = 288.15 - 6.5 * height / 1000.0;
              
              // 低压系统温度异常
              double dx_low = j - lowPressureX;
              double dy_low = i - lowPressureY;
              double r_low = sqrt(dx_low * dx_low + dy_low * dy_low);
              double tempAnomaly = 5.0 * exp(-r_low * r_low / 200) * 
                                (1 - height / 20000);
              
              // 冷锋温度梯度
              double frontGradient = 0.0;
              if (abs(j - coldFrontX) < 10) {
                frontGradient = -coldFrontIntensity * exp(-pow(j - coldFrontX, 2) / 50);
              }
              
              // 日变化
              double diurnalVariation = 3.0 * sin(2 * pi * (timeStep % 24) / 24 + height / 5000);
              
              // 地形影响
              double terrainHeight = 800 * sin(j * 0.1) * cos(i * 0.08);
              double terrainEffect = -0.0065 * terrainHeight * (height < terrainHeight ? 1 : 0);
              
              value = T_std + tempAnomaly + frontGradient + diurnalVariation + terrainEffect;
              
              // 添加湍流
              double turbulence = (Math.random() - 0.5) * 1.5 * exp(-height / 8000);
              value += turbulence;
              
              break;
              
            case 'pressure':
              // 标准大气压力
              double p_std = pressure;
              
              // 低压系统
              double dx_p = j - lowPressureX;
              double dy_p = i - lowPressureY;
              double r_p = sqrt(dx_p * dx_p + dy_p * dy_p);
              double pressureDeficit = 20.0 * exp(-r_p * r_p / 300) * 
                                      (1 - height / 15000);
              
              // 高空槽影响
              double troughEffect = 5.0 * sin(j * 0.1 + timeStep * 0.05) * 
                                  exp(-height / 10000);
              
              value = p_std - pressureDeficit * 100 + troughEffect * 100;
              
              // 动压修正
              if (k > 0) {
                double hydrostaticCorrection = -g * dz * 1.2; // 假设密度1.2 kg/m³
                value += hydrostaticCorrection;
              }
              
              break;
              
            case 'u_wind':
              // 地转风分量
              double dp_dy = 0.0;
              if (i > 0 && i < ny - 1) {
                dp_dy = (lowPressureDepth - 980.0) * 
                        exp(-pow(i - lowPressureY, 2) / 100) * 
                        (lowPressureX - j) / 50;
              }
              double geostrophicU = -dp_dy / (f * 1.2);
              
              // 急流
              double jetEffect = 0.0;
              if (abs(i - jetStreamY) < 5) {
                jetEffect = jetStreamIntensity * 
                           exp(-pow(i - jetStreamY, 2) / 10) * 
                           exp(-pow(height - 10000, 2) / 5e7);
              }
              
              // 边界层风廓线
              double boundaryLayerEffect = 1.0;
              if (height < 2000) {
                boundaryLayerEffect = pow(height / 2000, 0.7);
              }
              
              // 冷锋风
              double frontWind = 0.0;
              if (abs(j - coldFrontX) < 8) {
                frontWind = coldFrontIntensity * 
                           exp(-pow(j - coldFrontX, 2) / 30) * 
                           (1 - height / 5000);
              }
              
              value = (geostrophicU + jetEffect) * boundaryLayerEffect + frontWind;
              
              // 湍流脉动
              double turbulenceU = (Math.random() - 0.5) * 3.0 * exp(-height / 5000);
              value += turbulenceU;
              
              break;
              
            case 'v_wind':
              // 地转风分量
              double dp_dx = 0.0;
              if (j > 0 && j < nx - 1) {
                dp_dx = (lowPressureDepth - 980.0) * 
                        exp(-pow(j - lowPressureX, 2) / 100) * 
                        (i - lowPressureY) / 50;
              }
              double geostrophicV = dp_dx / (f * 1.2);
              
              // 涡旋运动
              double vorticity = 0.0;
              double dx_v = j - lowPressureX;
              double dy_v = i - lowPressureY;
              double r_v = sqrt(dx_v * dx_v + dy_v * dy_v);
              if (r_v > 0) {
                vorticity = 10.0 * exp(-r_v / 15) * (dx_v / r_v);
              }
              
              // 边界层效应
              double boundaryLayerV = 1.0;
              if (height < 2000) {
                boundaryLayerV = pow(height / 2000, 0.7);
              }
              
              value = (geostrophicV + vorticity) * boundaryLayerV;
              
              // 湍流脉动
              double turbulenceV = (Math.random() - 0.5) * 3.0 * exp(-height / 5000);
              value += turbulenceV;
              
              break;
              
            case 'humidity':
              // 基础湿度廓线
              double q_std = 0.01 * exp(-height / 8000);
              
              // 低压系统湿度增加
              double dx_h = j - lowPressureX;
              double dy_h = i - lowPressureY;
              double r_h = sqrt(dx_h * dx_h + dy_h * dy_h);
              double moistureAnomaly = 0.008 * exp(-r_h * r_h / 400) * 
                                      (1 - height / 10000);
              
              // 锋面湿度
              double frontMoisture = 0.0;
              if (abs(j - coldFrontX) < 12) {
                frontMoisture = 0.005 * exp(-pow(j - coldFrontX, 2) / 40);
              }
              
              // 地形抬升
              double terrainHeight = 800 * sin(j * 0.1) * cos(i * 0.08);
              double orographicLift = 0.0;
              if (height < terrainHeight + 1000) {
                orographicLift = 0.003 * exp(-pow(height - terrainHeight, 2) / 1e6);
              }
              
              value = q_std + moistureAnomaly + frontMoisture + orographicLift;
              value = max(0.0001, min(0.03, value));
              
              break;
              
            case 'vertical_velocity':
              // 垂直速度 - 连续性约束
              double divergence = 0.0;
              if (j > 0 && j < nx - 1 && i > 0 && i < ny - 1) {
                // 简化的散度计算
                divergence = 0.0001 * sin(j * 0.1 + timeStep * 0.05) * 
                           cos(i * 0.1 + timeStep * 0.04);
              }
              
              // 积分得到垂直速度
              double w = -divergence * height * 0.1;
              
              // 对流垂直速度
              double dx_w = j - lowPressureX;
              double dy_w = i - lowPressureY;
              double r_w = sqrt(dx_w * dx_w + dy_w * dy_w);
              if (r_w < 20 && height < 8000) {
                w += 2.0 * exp(-r_w / 10) * sin(height * pi / 8000);
              }
              
              value = w;
              break;
              
            default:
              value = 0.0;
          }
          
          row.add(value);
        }
        layer.add(row);
      }
      data.add(layer);
    }
    
    // 应用垂直平滑
    data = _applyVerticalSmoothing(data);
    
    return {
      'time_step': timeStep,
      'variable': variable,
      'data': data,
      'metadata': {
        'grid_dimensions': {'nx': nx, 'ny': ny, 'nz': nz},
        'grid_spacing': {'dx': dx, 'dy': dy, 'dz': dz},
        'low_pressure': {'x': lowPressureX, 'y': lowPressureY, 'depth': lowPressureDepth},
        'jet_stream': {'y': jetStreamY, 'intensity': jetStreamIntensity},
        'cold_front': {'position': coldFrontX, 'intensity': coldFrontIntensity},
        'physics_constants': {'g': g, 'cp': cp, 'R': R, 'Lv': Lv},
      },
      'fallback': true,
      'message': 'Using enhanced physics-based WRF simulation'
    };
  }
  
  /// 应用垂直平滑滤波器
  static List<List<List<List<double>>>> _applyVerticalSmoothing(
    List<List<List<List<double>>>> data
  ) {
    final int nz = data.length;
    final int ny = data[0].length;
    final int nx = data[0][0].length;
    
    for (int k = 1; k < nz - 1; k++) {
      for (int i = 0; i < ny; i++) {
        for (int j = 0; j < nx; j++) {
          // 垂直三点平滑
          data[k][i][j] = (data[k-1][i][j] + 2*data[k][i][j] + data[k+1][i][j]) / 4;
        }
      }
    }
    
    return data;
  }
  
  /// 获取地表类型和蒸发参数
  static Map<String, double> _getSurfaceType(int i, int j, int nx, int ny) {
    // 定义地表分布
    double x = j / nx;
    double y = i / ny;
    
    // 海洋区域 (东部和南部)
    if (x > 0.6 || y > 0.7) {
      return {
        'type': 0, // 海洋
        'albedo': 0.06, // 反照率
        'roughness': 0.0002, // 粗糙度
        'moisture_availability': 1.0, // 水分可用性
        'heat_capacity': 4186.0, // 热容量 (J/kg/K)
        'evaporation_rate': 5.0, // 蒸发率 (mm/day)
        'surface_temperature': 298.15, // 表面温度 (K)
      };
    }
    
    // 雨林区域 (中部)
    if (x > 0.3 && x < 0.5 && y > 0.3 && y < 0.5) {
      return {
        'type': 1, // 雨林
        'albedo': 0.12,
        'roughness': 1.0,
        'moisture_availability': 0.8,
        'heat_capacity': 2500.0,
        'evaporation_rate': 4.5,
        'surface_temperature': 295.15,
        'vegetation_fraction': 0.9, // 植被覆盖度
        'leaf_area_index': 6.0, // 叶面积指数
      };
    }
    
    // 草原区域 (西部和北部)
    if ((x < 0.3 && y < 0.4) || (x > 0.2 && x < 0.4 && y > 0.6)) {
      return {
        'type': 2, // 草原
        'albedo': 0.20,
        'roughness': 0.05,
        'moisture_availability': 0.4,
        'heat_capacity': 1500.0,
        'evaporation_rate': 2.0,
        'surface_temperature': 292.15,
        'vegetation_fraction': 0.6,
        'leaf_area_index': 2.0,
      };
    }
    
    // 沙漠区域 (西北部)
    if (x < 0.2 && y < 0.3) {
      return {
        'type': 3, // 沙漠
        'albedo': 0.35,
        'roughness': 0.001,
        'moisture_availability': 0.05,
        'heat_capacity': 800.0,
        'evaporation_rate': 0.5,
        'surface_temperature': 308.15,
        'vegetation_fraction': 0.1,
      };
    }
    
    // 湖泊区域 (散布的小湖泊)
    if ((x > 0.7 && x < 0.8 && y > 0.2 && y < 0.3) ||
        (x > 0.4 && x < 0.5 && y > 0.7 && y < 0.8)) {
      return {
        'type': 4, // 湖泊
        'albedo': 0.08,
        'roughness': 0.0001,
        'moisture_availability': 1.0,
        'heat_capacity': 4186.0,
        'evaporation_rate': 4.0,
        'surface_temperature': 296.15,
      };
    }
    
    // 默认陆地
    return {
      'type': 5, // 一般陆地
      'albedo': 0.25,
      'roughness': 0.1,
      'moisture_availability': 0.3,
      'heat_capacity': 1200.0,
      'evaporation_rate': 1.5,
      'surface_temperature': 290.15,
      'vegetation_fraction': 0.4,
    };
  }
  
  /// 计算蒸发通量 (Penman-Monteith方程)
  static double _calculateEvaporation(
    Map<String, double> surface,
    double airTemp,
    double humidity,
    double windSpeed,
    double netRadiation,
    double pressure
  ) {
    // Penman-Monteith方程参数
    const double L = 2.5e6; // 水汽潜热 (J/kg)
    const double cp = 1004.0; // 空气比热 (J/kg/K)
    const double rho = 1.2; // 空气密度 (kg/m³)
    const double epsilon = 0.622; // 水汽与干空气分子量比
    const double gamma = cp * pressure / (epsilon * L); // 干湿常数
    
    // 饱和水汽压 (Tetens公式)
    double es = 610.78 * exp(17.27 * (airTemp - 273.15) / (airTemp - 273.15 + 237.3));
    // 实际水汽压
    double ea = es * humidity;
    
    // 饱和水汽压斜率
    double delta = 4098 * es / pow(airTemp - 273.15 + 237.3, 2);
    
    // 空气动力学阻抗
    double ra = 1.0 / (0.16 * windSpeed); // 简化的阻抗计算
    
    // 表面阻抗 (考虑地表类型)
    double rs = 100.0 / surface['moisture_availability']!; // 地表阻抗
    
    // 蒸发率 (kg/m²/s)
    double lambdaE = (delta * netRadiation + rho * cp * (es - ea) / ra) / 
                    (delta + gamma * (1 + rs / ra));
    
    // 转换为 mm/day
    double evaporation = lambdaE * 86400.0 / 1000.0;
    
    // 考虑地表类型的蒸发限制
    double maxEvaporation = surface['evaporation_rate']!;
    evaporation = min(evaporation, maxEvaporation);
    
    return max(0, evaporation);
  }
  
  /// 计算地表能量平衡
  static Map<String, double> _calculateSurfaceEnergyBalance(
    Map<String, double> surface,
    double solarRadiation,
    double airTemp,
    double humidity,
    double windSpeed,
    double timeStep
  ) {
    // 短波辐射吸收
    double swAbsorbed = solarRadiation * (1 - surface['albedo']!);
    
    // 长波辐射 (简化计算)
    double emissivity = 0.95;
    double surfaceTemp = surface['surface_temperature']!;
    double longwaveLoss = emissivity * 5.67e-8 * pow(surfaceTemp, 4);
    
    // 净辐射
    double netRadiation = swAbsorbed - longwaveLoss;
    
    // 感热通量
    double sensibleHeat = 10.0 * (surfaceTemp - airTemp) * windSpeed;
    
    // 潜热通量 (蒸发)
    double evaporation = _calculateEvaporation(
      surface, airTemp, humidity, windSpeed, netRadiation, 101325.0
    );
    double latentHeat = evaporation * 2.5e6 / 86400.0; // 转换为 W/m²
    
    // 地热通量
    double groundHeat = netRadiation - sensibleHeat - latentHeat;
    
    return {
      'net_radiation': netRadiation,
      'sensible_heat': sensibleHeat,
      'latent_heat': latentHeat,
      'ground_heat': groundHeat,
      'evaporation': evaporation,
      'surface_temperature': surfaceTemp + (groundHeat / surface['heat_capacity']!) * 0.1,
    };
  }
  
  /// 计算海陆风环流
  static Map<String, double> _calculateSeaLandBreeze(
    Map<String, double> surface1,
    Map<String, double> surface2,
    double timeStep
  ) {
    // 海陆温差
    double tempDiff = surface1['surface_temperature']! - surface2['surface_temperature']!;
    
    // 海陆风强度 (简化模型)
    double windStrength = 2.0 * sin(tempDiff / 10.0);
    
    // 考虑日变化
    double hourAngle = 2 * pi * (timeStep % 24) / 24;
    double diurnalFactor = sin(hourAngle - pi / 2);
    
    return {
      'u_component': windStrength * diurnalFactor,
      'v_component': windStrength * cos(hourAngle) * 0.5,
      'circulation_strength': abs(windStrength * diurnalFactor),
    };
  }
  
  /// 计算植被蒸腾作用
  static double _calculateTranspiration(
    Map<String, double> surface,
    double airTemp,
    double humidity,
    double solarRadiation,
    double windSpeed
  ) {
    if (!surface.containsKey('vegetation_fraction')) return 0.0;
    
    double vegFraction = surface['vegetation_fraction']!;
    double lai = surface['leaf_area_index'] ?? 2.0;
    
    // 光合有效辐射
    double par = solarRadiation * 0.45; // PAR约为总辐射的45%
    
    // 光限制因子
    double lightLimit = 1.0 - exp(-0.5 * lai * par / 1000.0);
    
    // 温度限制因子
    double tempOptimum = 298.15; // 最适温度
    double tempLimit = exp(-pow((airTemp - tempOptimum) / 15.0, 2));
    
    // 湿度限制因子
    double vpd = (1 - humidity) * 1000; // 水汽压差
    double moistureLimit = exp(-vpd / 500.0);
    
    // 最大蒸腾速率
    double maxTranspiration = 8.0; // mm/day
    
    // 实际蒸腾
    double transpiration = maxTranspiration * vegFraction * 
                          lightLimit * tempLimit * moistureLimit;
    
    return transpiration;
  }
  
  /// 增强版WRF数据生成 - 水汽精确系统终结版
  static Map<String, dynamic> _getEnhancedWRFData(int timeStep, String variable) {
    final int nx = 50, ny = 50, nz = 20;
    
    // 调用水汽精确系统
    Map<String, dynamic> waterVaporSystem = _calculatePreciseWaterVaporSystem(timeStep, nx, ny, nz);
    
    // 根据请求的变量返回相应数据
    switch (variable) {
      case 'water_vapor_system':
        return waterVaporSystem;
        
      case 'humidity_3d':
        return {
          'time_step': timeStep,
          'variable': 'humidity',
          'data': waterVaporSystem['humidity'],
          'units': 'kg/kg',
          'description': '水汽混合比三维场',
          'water_budget': waterVaporSystem['water_budget'],
        };
        
      case 'cloud_water_3d':
        return {
          'time_step': timeStep,
          'variable': 'cloud_water',
          'data': waterVaporSystem['cloud_water'],
          'units': 'kg/kg',
          'description': '云水含量三维场',
          'total_content': waterVaporSystem['water_budget']['cloud_water_content'],
        };
        
      case 'precipitation_rate':
        List<List<double>> precipitationRate = List.generate(ny, (i) => 
          List.filled(nx, 0.0));
        
        for (int k = 0; k < nz; k++) {
          for (int i = 0; i < ny; i++) {
            for (int j = 0; j < nx; j++) {
              precipitationRate[i][j] += waterVaporSystem['rain_water'][k][i][j] * 3600.0 * 1000.0;
            }
          }
        }
        
        return {
          'time_step': timeStep,
          'variable': 'precipitation_rate',
          'data': precipitationRate,
          'units': 'mm/h',
          'description': '地面降水率',
          'total_precipitation': waterVaporSystem['water_budget']['total_precipitation'],
        };
        
      case 'vertical_velocity_3d':
        return {
          'time_step': timeStep,
          'variable': 'vertical_velocity',
          'data': waterVaporSystem['vertical_velocity'],
          'units': 'm/s',
          'description': '垂直速度三维场',
        };
        
      case 'evapotranspiration':
        return {
          'time_step': timeStep,
          'variable': 'evapotranspiration',
          'data': {
            'evaporation': waterVaporSystem['surface_evaporation'],
            'transpiration': waterVaporSystem['surface_transpiration'],
            'total': waterVaporSystem['water_budget']['total_evaporation'] + 
                    waterVaporSystem['water_budget']['total_transpiration'],
          },
          'units': 'mm/day',
          'description': '地表蒸散发',
        };
        
      case 'water_budget':
        return {
          'time_step': timeStep,
          'variable': 'water_budget',
          'data': waterVaporSystem['water_budget'],
          'description': '水汽收支平衡',
        };
        
      case 'cloud_microphysics':
        return {
          'time_step': timeStep,
          'variable': 'cloud_microphysics',
          'data': {
            'cloud_water': waterVaporSystem['cloud_water'],
            'cloud_ice': waterVaporSystem['cloud_ice'],
            'rain_water': waterVaporSystem['rain_water'],
          },
          'units': 'kg/kg',
          'description': '云微物理过程',
        };
        
      default:
        // 对于其他变量，使用水汽精确系统的计算结果
        return {
          'time_step': timeStep,
          'variable': variable,
          'data': _getStandardWRFValue(variable, 0, 0, 0, nx, ny, nz, timeStep, {}),
          'system': 'precise_water_vapor_system',
          'message': 'Using precise water vapor system calculation',
        };
    }
    
    // 太阳辐射计算
    double solarDeclination = 23.45 * sin(2 * pi * (timeStep % 365) / 365);
    double hourAngle = 2 * pi * (timeStep % 24) / 24 - pi;
    double solarRadiation = max(0, 1361 * sin(solarDeclination * pi / 180) * 
                              cos(hourAngle));
    
    // 存储地表能量平衡数据
    List<List<Map<String, double>>> surfaceData = [];
    
    for (int k = 0; k < nz; k++) {
      List<List<double>> layer = [];
      double height = k * 1000.0;
      
      for (int i = 0; i < ny; i++) {
        List<double> row = [];
        
        for (int j = 0; j < nx; j++) {
          // 获取地表类型
          Map<String, double> surface = _getSurfaceType(i, j, nx, ny);
          
          // 计算地表能量平衡
          Map<String, double> energyBalance = _calculateSurfaceEnergyBalance(
            surface, solarRadiation, 288.15, 0.6, 5.0, timeStep
          );
          
          // 存储地表数据 (仅在底层)
          if (k == 0) {
            surfaceData.add(energyBalance);
          }
          
          double value = 0.0;
          
          switch (variable) {
            case 'evaporation':
              if (k == 0) {
                // 总蒸发 = 土壤蒸发 + 植被蒸腾
                double soilEvap = energyBalance['evaporation']!;
                double transpiration = _calculateTranspiration(
                  surface, 288.15, 0.6, solarRadiation, 5.0
                );
                value = soilEvap + transpiration;
              } else {
                // 高层蒸发为0
                value = 0.0;
              }
              break;
              
            case 'surface_temperature':
              if (k == 0) {
                value = energyBalance['surface_temperature']!;
              } else {
                // 大气温度廓线
                value = 288.15 - 6.5 * height / 1000.0;
                
                // 考虑地表影响
                double surfaceInfluence = exp(-height / 2000.0);
                value += (energyBalance['surface_temperature']! - 288.15) * surfaceInfluence;
              }
              break;
              
            case 'sensible_heat_flux':
              if (k == 0) {
                value = energyBalance['sensible_heat']!;
              } else {
                // 感热通量随高度递减
                value = energyBalance['sensible_heat']! * exp(-height / 1000.0);
              }
              break;
              
            case 'latent_heat_flux':
              if (k == 0) {
                value = energyBalance['latent_heat']!;
              } else {
                // 潜热通量随高度递减
                value = energyBalance['latent_heat']! * exp(-height / 1500.0);
              }
              break;
              
            case 'boundary_layer_height':
              if (k == 0) {
                // 边界层高度计算
                double blHeight = 1000.0; // 基础高度
                
                // 根据地表类型调整
                if (surface['type'] == 0) { // 海洋
                  blHeight = 600.0;
                } else if (surface['type'] == 1) { // 雨林
                  blHeight = 1500.0;
                } else if (surface['type'] == 3) { // 沙漠
                  blHeight = 2000.0;
                }
                
                // 考虑热力对流
                double thermalConvection = energyBalance['sensible_heat']! / 100.0;
                blHeight += thermalConvection;
                
                value = blHeight;
              } else {
                value = 0.0;
              }
              break;
              
            case 'soil_moisture':
              if (k == 0) {
                // 土壤湿度计算
                double moisture = surface['moisture_availability']! * 0.3; // 体积含水率
                
                // 考虑蒸发消耗
                double evapDepletion = energyBalance['evaporation']! * 0.001;
                moisture -= evapDepletion;
                
                // 考虑降水补给 (简化)
                if (timeStep % 24 < 6) { // 假设夜间降水
                  moisture += 0.01;
                }
                
                value = max(0.05, min(0.4, moisture));
              } else {
                value = 0.0;
              }
              break;
              
            default:
              // 使用原有的WRF数据生成逻辑
              value = _getStandardWRFValue(variable, k, i, j, nx, ny, nz, timeStep, surface);
              break;
          }
          
          row.add(value);
        }
        layer.add(row);
      }
      data.add(layer);
    }
    
    return {
      'time_step': timeStep,
      'variable': variable,
      'data': data,
      'surface_data': surfaceData,
      'metadata': {
        'grid_dimensions': {'nx': nx, 'ny': ny, 'nz': nz},
        'solar_radiation': solarRadiation,
        'surface_types': ['海洋', '雨林', '草原', '沙漠', '湖泊', '一般陆地'],
        'enhanced_physics': ['蒸发系统', '能量平衡', '植被蒸腾', '海陆风环流'],
      },
      'fallback': true,
      'message': 'Using enhanced WRF simulation with surface evaporation system'
    };
  }
  
  /// 水汽精确系统 - 终结全局气象系统核心
  static Map<String, dynamic> _calculatePreciseWaterVaporSystem(
    int timeStep, int nx, int ny, int nz
  ) {
    // 物理常数
    const double g = 9.81; // 重力加速度
    const double cp = 1004.0; // 定压比热
    const double Lv = 2.5e6; // 水汽潜热
    const double Rv = 461.5; // 水汽气体常数
    const double Rd = 287.0; // 干空气气体常数
    const double epsilon = 0.622; // 水汽与干空气分子量比
    const double sigma = 5.67e-8; // 斯特藩-玻尔兹曼常数
    
    // 水汽场初始化
    List<List<List<double>>> humidity = List.generate(nz, (k) => 
      List.generate(ny, (i) => List.filled(nx, 0.0)));
    List<List<List<double>>> temperature = List.generate(nz, (k) => 
      List.generate(ny, (i) => List.filled(nx, 0.0)));
    List<List<List<double>>> pressure = List.generate(nz, (k) => 
      List.generate(ny, (i) => List.filled(nx, 0.0)));
    List<List<List<double>>> cloudWater = List.generate(nz, (k) => 
      List.generate(ny, (i) => List.filled(nx, 0.0)));
    List<List<List<double>>> cloudIce = List.generate(nz, (k) => 
      List.generate(ny, (i) => List.filled(nx, 0.0)));
    List<List<List<double>>> rainWater = List.generate(nz, (k) => 
      List.generate(ny, (i) => List.filled(nx, 0.0)));
    List<List<List<double>>> verticalVelocity = List.generate(nz, (k) => 
      List.generate(ny, (i) => List.filled(nx, 0.0)));
    
    // 地表水汽源
    List<List<double>> surfaceEvaporation = List.generate(ny, (i) => 
      List.filled(nx, 0.0));
    List<List<double>> surfaceTranspiration = List.generate(ny, (i) => 
      List.filled(nx, 0.0));
    
    // 水汽收支计算
    double totalEvaporation = 0.0;
    double totalTranspiration = 0.0;
    double totalCondensation = 0.0;
    double totalPrecipitation = 0.0;
    
    // 第一阶段：初始化大气状态
    for (int k = 0; k < nz; k++) {
      double height = k * 1000.0;
      double p0 = 101325.0; // 海平面气压
      
      for (int i = 0; i < ny; i++) {
        for (int j = 0; j < nx; j++) {
          // 获取地表类型
          Map<String, double> surface = _getSurfaceType(i, j, nx, ny);
          
          // 温度廓线 - 考虑地表影响
          double T_standard = 288.15 - 6.5 * height / 1000.0;
          double surfaceInfluence = exp(-height / 2000.0);
          double diurnalVariation = 3.0 * sin(2 * pi * (timeStep % 24) / 24 - height / 5000);
          
          temperature[k][i][j] = T_standard + 
            (surface['surface_temperature']! - 288.15) * surfaceInfluence * 0.3 +
            diurnalVariation;
          
          // 气压廓线
          pressure[k][i][j] = p0 * pow(1 - 0.0065 * height / 288.15, 5.255);
          
          // 水汽混合比 - 精确计算
          double e_sat = _calculateSaturationVaporPressure(temperature[k][i][j]);
          double RH = 0.3 + 0.4 * surface['moisture_availability']! * surfaceInfluence;
          
          // 考虑高度对湿度的影响
          RH *= exp(-height / 8000.0);
          
          // 水汽混合比 (kg/kg)
          humidity[k][i][j] = epsilon * RH * e_sat / (pressure[k][i][j] - RH * e_sat);
          
          // 云水含量（初步）
          if (height < 12000 && RH > 0.8) {
            cloudWater[k][i][j] = 0.001 * (RH - 0.8) * 5.0;
          }
          
          // 冰晶含量（高层）
          if (height > 8000 && temperature[k][i][j] < 273.15) {
            cloudIce[k][i][j] = 0.0005 * (RH - 0.7) * 3.0;
          }
        }
      }
    }
    
    // 第二阶段：地表水汽通量计算
    for (int i = 0; i < ny; i++) {
      for (int j = 0; j < nx; j++) {
        Map<String, double> surface = _getSurfaceType(i, j, nx, ny);
        
        // 净辐射计算
        double solarRadiation = _calculateSolarRadiation(timeStep, i, j, nx, ny);
        double netRadiation = _calculateNetRadiation(
          solarRadiation, surface, temperature[0][i][j], humidity[0][i][j]
        );
        
        // Penman-Monteith蒸发
        double evaporation = _calculatePreciseEvaporation(
          surface, temperature[0][i][j], humidity[0][i][j], 
          pressure[0][i][j], netRadiation, windSpeed = 5.0
        );
        
        surfaceEvaporation[i][j] = evaporation;
        totalEvaporation += evaporation;
        
        // 植被蒸腾
        if (surface.containsKey('vegetation_fraction')) {
          double transpiration = _calculatePreciseTranspiration(
            surface, temperature[0][i][j], humidity[0][i][j],
            pressure[0][i][j], solarRadiation
          );
          surfaceTranspiration[i][j] = transpiration;
          totalTranspiration += transpiration;
        }
      }
    }
    
    // 第三阶段：垂直水汽输送和对流
    for (int k = 1; k < nz - 1; k++) {
      for (int i = 1; i < ny - 1; i++) {
        for (int j = 1; j < nx - 1; j++) {
          // 垂直速度计算 - 连续性方程
          double divergence = (
            (humidity[k][i+1][j] - humidity[k][i-1][j]) / 20000.0 +
            (humidity[k][i][j+1] - humidity[k][i][j-1]) / 20000.0
          );
          
          verticalVelocity[k][i][j] = -divergence * 1000.0; // 简化计算
          
          // 对流调整
          if (humidity[k][i][j] > 0.015) { // 高湿度触发对流
            verticalVelocity[k][i][j] += 2.0 * (humidity[k][i][j] - 0.015) / 0.01;
          }
          
          // 湿度平流
          double u_wind = 10.0 * exp(-k * 1000.0 / 10000.0);
          double v_wind = 5.0 * sin(j * 0.1 + timeStep * 0.05) * exp(-k * 1000.0 / 8000.0);
          
          double humidityAdvection = -(
            u_wind * (humidity[k][i][j+1] - humidity[k][i][j-1]) / 20000.0 +
            v_wind * (humidity[k+1][i][j] - humidity[k-1][i][j]) / 1000.0
          );
          
          // 湿度倾向方程
          double dt = 60.0; // 时间步长（秒）
          humidity[k][i][j] += dt * (humidityAdvection - verticalVelocity[k][i][j] * 0.0001);
          
          // 云微物理过程
          _calculateCloudMicrophysics(
            k, i, j, temperature, humidity, cloudWater, cloudIce, rainWater,
            pressure, dt
          );
        }
      }
    }
    
    // 第四阶段：边界层水汽混合
    for (int i = 0; i < ny; i++) {
      for (int j = 0; j < nx; j++) {
        // 地表蒸发注入到最低层
        if (surfaceEvaporation[i][j] > 0 || surfaceTranspiration[i][j] > 0) {
          double totalMoistureFlux = (surfaceEvaporation[i][j] + surfaceTranspiration[i][j]) / 86400.0;
          humidity[0][i][j] += totalMoistureFlux * 60.0 / 1000.0; // 转换为kg/kg
        }
        
        // 边界层混合
        for (int k = 1; k < 5 && k < nz; k++) {
          double mixingCoeff = 0.1 * exp(-k * 1000.0 / 2000.0);
          humidity[k][i][j] = (1 - mixingCoeff) * humidity[k][i][j] + 
                              mixingCoeff * humidity[k-1][i][j];
        }
      }
    }
    
    // 第五阶段：降水计算
    for (int k = 0; k < nz; k++) {
      for (int i = 0; i < ny; i++) {
        for (int j = 0; j < nx; j++) {
          if (rainWater[k][i][j] > 0.0001) {
            // 降水率 (mm/h)
            double precipitationRate = rainWater[k][i][j] * 3600.0 * 1000.0;
            totalPrecipitation += precipitationRate;
            
            // 降水蒸发
            if (k > 0 && temperature[k][i][j] > 273.15) {
              double rainEvaporation = min(rainWater[k][i][j], 0.0001);
              rainWater[k][i][j] -= rainEvaporation;
              humidity[k][i][j] += rainEvaporation;
            }
          }
          
          // 凝结过程
          if (cloudWater[k][i][j] > 0.002) {
            double condensation = min(cloudWater[k][i][j] - 0.002, 0.0005);
            cloudWater[k][i][j] -= condensation;
            rainWater[k][i][j] += condensation;
            totalCondensation += condensation;
            
            // 潜热释放
            temperature[k][i][j] += (Lv * condensation) / (cp * 1000.0);
          }
        }
      }
    }
    
    // 第六阶段：水汽收支平衡
    Map<String, double> waterBudget = {
      'total_evaporation': totalEvaporation,
      'total_transpiration': totalTranspiration,
      'total_condensation': totalCondensation,
      'total_precipitation': totalPrecipitation,
      'water_vapor_content': _calculateTotalWaterVapor(humidity, pressure),
      'cloud_water_content': _calculateTotalCloudWater(cloudWater, cloudIce),
      'precipitable_water': _calculatePrecipitableWater(humidity, pressure),
      'relative_humidity_mean': _calculateMeanRelativeHumidity(humidity, temperature, pressure),
    };
    
    return {
      'humidity': humidity,
      'temperature': temperature,
      'pressure': pressure,
      'cloud_water': cloudWater,
      'cloud_ice': cloudIce,
      'rain_water': rainWater,
      'vertical_velocity': verticalVelocity,
      'surface_evaporation': surfaceEvaporation,
      'surface_transpiration': surfaceTranspiration,
      'water_budget': waterBudget,
      'time_step': timeStep,
      'system_type': 'precise_water_vapor_system',
    };
  }
  
  /// 计算饱和水汽压 (Magnus公式)
  static double _calculateSaturationVaporPressure(double temperature) {
    double T_celsius = temperature - 273.15;
    
    if (T_celsius >= 0) {
      // 水面
      return 610.78 * exp(17.27 * T_celsius / (T_celsius + 237.3));
    } else {
      // 冰面
      return 610.78 * exp(21.875 * T_celsius / (T_celsius + 265.5));
    }
  }
  
  /// 计算太阳辐射
  static double _calculateSolarRadiation(int timeStep, int i, int j, int nx, int ny) {
    // 太阳赤纬
    double dayOfYear = (timeStep / 24.0) % 365;
    double solarDeclination = 23.45 * sin(2 * pi * (dayOfYear - 81) / 365);
    
    // 时角
    double hourAngle = 2 * pi * ((timeStep % 24) - 12) / 24;
    
    // 纬度（假设35°N）
    double latitude = 35.0 * pi / 180;
    
    // 太阳高度角
    double solarElevation = asin(
      sin(latitude) * sin(solarDeclination * pi / 180) +
      cos(latitude) * cos(solarDeclination * pi / 180) * cos(hourAngle)
    );
    
    // 太阳辐射
    double solarConstant = 1361.0; // W/m²
    double atmosphericTransmission = 0.7; // 大气透射率
    
    return max(0, solarConstant * atmosphericTransmission * sin(solarElevation));
  }
  
  /// 计算净辐射
  static double _calculateNetRadiation(
    double solarRadiation,
    Map<String, double> surface,
    double temperature,
    double humidity
  ) {
    // 短波辐射吸收
    double shortwaveAbsorbed = solarRadiation * (1 - surface['albedo']!);
    
    // 长波辐射
    double emissivity = 0.95;
    double longwaveLoss = emissivity * 5.67e-8 * pow(temperature, 4);
    
    // 大气逆辐射
    double e = _calculateSaturationVaporPressure(temperature);
    double atmosphericEmissivity = 0.7 + 0.3 * (e * humidity / 1000.0);
    double longwaveGain = atmosphericEmissivity * 5.67e-8 * pow(temperature, 4);
    
    return shortwaveAbsorbed - longwaveLoss + longwaveGain;
  }
  
  /// 精确蒸发计算
  static double _calculatePreciseEvaporation(
    Map<String, double> surface,
    double temperature,
    double humidity,
    double pressure,
    double netRadiation,
    double windSpeed
  ) {
    // 饱和水汽压
    double es = _calculateSaturationVaporPressure(temperature);
    // 实际水汽压
    double ea = es * (humidity * 287.0 / (es * 461.5));
    
    // 饱和水汽压斜率
    double delta = 4098.0 * es / pow(temperature - 273.15 + 237.3, 2);
    
    // 干湿常数
    double gamma = 1004.0 * pressure / (0.622 * 2.5e6);
    
    // 空气动力学阻抗
    double ra = 1.0 / (0.16 * windSpeed);
    
    // 地表阻抗
    double rs = 100.0 / surface['moisture_availability']!;
    
    // Penman-Monteith方程
    double lambdaE = (delta * netRadiation + 1004.0 * 1.2 * (es - ea) / ra) /
                    (delta + gamma * (1 + rs / ra));
    
    // 转换为mm/day
    double evaporation = lambdaE * 86400.0 / (2.5e6 * 1000.0);
    
    return max(0, evaporation);
  }
  
  /// 精确蒸腾计算
  static double _calculatePreciseTranspiration(
    Map<String, double> surface,
    double temperature,
    double humidity,
    double pressure,
    double solarRadiation
  ) {
    if (!surface.containsKey('vegetation_fraction')) return 0.0;
    
    double vegFraction = surface['vegetation_fraction']!;
    double lai = surface['leaf_area_index'] ?? 2.0;
    
    // 光合有效辐射
    double par = solarRadiation * 0.45;
    
    // 光限制因子
    double alpha = 0.04; // 光利用效率
    double lightLimit = 1.0 - exp(-alpha * lai * par / 1000.0);
    
    // 温度限制因子
    double topt = 298.15; // 最适温度
    double beta = 0.002;
    double tempLimit = exp(-beta * pow(temperature - topt, 2));
    
    // 水汽压差限制
    double e = _calculateSaturationVaporPressure(temperature);
    double ea = e * (humidity * 287.0 / (e * 461.5));
    double vpd = max(0, e - ea) / 1000.0; // kPa
    double vpdLimit = exp(-vpd / 40.0);
    
    // 最大蒸腾速率
    double tmax = 0.0005; // kg/m²/s
    
    double transpiration = tmax * vegFraction * lightLimit * tempLimit * vpdLimit;
    
    return transpiration * 86400.0; // 转换为mm/day
  }
  
  /// 云微物理过程
  static void _calculateCloudMicrophysics(
    int k, int i, int j,
    List<List<List<double>>> temperature,
    List<List<List<double>>> humidity,
    List<List<List<double>>> cloudWater,
    List<List<List<double>>> cloudIce,
    List<List<List<double>>> rainWater,
    List<List<List<double>>> pressure,
    double dt
  ) {
    double T = temperature[k][i][j];
    double q = humidity[k][i][j];
    double p = pressure[k][i][j];
    
    // 饱和水汽压
    double es = _calculateSaturationVaporPressure(T);
    double qs = 0.622 * es / (p - es);
    
    // 过饱和度
    double S = q / qs - 1.0;
    
    if (S > 0) {
      // 凝结增长
      double condensationRate = min(S * 0.001, 0.0001);
      cloudWater[k][i][j] += condensationRate * dt;
      humidity[k][i][j] -= condensationRate * dt;
      
      // Bergeron过程（冰晶增长）
      if (T < 273.15 && T > 233.15) {
        double bergeronRate = 0.00001 * (273.15 - T) / 40.0;
        if (cloudWater[k][i][j] > bergeronRate) {
          cloudWater[k][i][j] -= bergeronRate * dt;
          cloudIce[k][i][j] += bergeronRate * dt;
        }
      }
    }
    
    // 碰并过程（雨滴形成）
    if (cloudWater[k][i][j] > 0.002) {
      double autoconversionRate = 0.001 * (cloudWater[k][i][j] - 0.002);
      rainWater[k][i][j] += autoconversionRate * dt;
      cloudWater[k][i][j] -= autoconversionRate * dt;
    }
    
    // 冰晶下落
    if (cloudIce[k][i][j] > 0.0001 && k > 0) {
      double fallSpeed = 1.0; // m/s
      double iceFall = cloudIce[k][i][j] * fallSpeed * dt / 1000.0;
      
      if (T > 273.15) {
        // 融化
        rainWater[k][i][j] += iceFall;
      } else {
        // 继续下落
        cloudIce[k-1][i][j] += iceFall;
      }
      cloudIce[k][i][j] -= iceFall;
    }
  }
  
  /// 计算总水汽含量
  static double _calculateTotalWaterVapor(
    List<List<List<double>>> humidity,
    List<List<List<double>>> pressure
  ) {
    double total = 0.0;
    int nz = humidity.length;
    int ny = humidity[0].length;
    int nx = humidity[0][0].length;
    
    for (int k = 0; k < nz; k++) {
      for (int i = 0; i < ny; i++) {
        for (int j = 0; j < nx; j++) {
          total += humidity[k][i][j] * pressure[k][i][j];
        }
      }
    }
    
    return total / (nx * ny * nz * 1000.0); // 平均值
  }
  
  /// 计算总云水含量
  static double _calculateTotalCloudWater(
    List<List<List<double>>> cloudWater,
    List<List<List<double>>> cloudIce
  ) {
    double total = 0.0;
    int nz = cloudWater.length;
    int ny = cloudWater[0].length;
    int nx = cloudWater[0][0].length;
    
    for (int k = 0; k < nz; k++) {
      for (int i = 0; i < ny; i++) {
        for (int j = 0; j < nx; j++) {
          total += cloudWater[k][i][j] + cloudIce[k][i][j];
        }
      }
    }
    
    return total / (nx * ny * nz);
  }
  
  /// 计算可降水量
  static double _calculatePrecipitableWater(
    List<List<List<double>>> humidity,
    List<List<List<double>>> pressure
  ) {
    double pw = 0.0;
    int nz = humidity.length;
    int ny = humidity[0].length;
    int nx = humidity[0][0].length;
    
    for (int k = 0; k < nz - 1; k++) {
      double dp = (pressure[k][0][0] - pressure[k+1][0][0]) / 1000.0; // hPa
      double q_mean = (humidity[k][0][0] + humidity[k+1][0][0]) / 2.0;
      pw += q_mean * dp / 9.81; // mm
    }
    
    return pw / (nx * ny);
  }
  
  /// 计算平均相对湿度
  static double _calculateMeanRelativeHumidity(
    List<List<List<double>>> humidity,
    List<List<List<double>>> temperature,
    List<List<List<double>>> pressure
  ) {
    double totalRH = 0.0;
    int count = 0;
    
    for (int k = 0; k < humidity.length; k++) {
      for (int i = 0; i < humidity[0].length; i += 5) {
        for (int j = 0; j < humidity[0][0].length; j += 5) {
          double T = temperature[k][i][j];
          double q = humidity[k][i][j];
          double p = pressure[k][i][j];
          
          double es = _calculateSaturationVaporPressure(T);
          double qs = 0.622 * es / (p - es);
          double RH = q / qs;
          
          totalRH += RH;
          count++;
        }
      }
    }
    
    return (totalRH / count) * 100.0; // 百分比
  }
  
  /// 标准WRF值计算 (保持向后兼容)
  static double _getStandardWRFValue(
    String variable,
    int k, int i, int j,
    int nx, int ny, int nz,
    int timeStep,
    Map<String, double> surface
  ) {
    // 调用水汽精确系统
    Map<String, dynamic> waterVaporSystem = _calculatePreciseWaterVaporSystem(timeStep, nx, ny, nz);
    
    switch (variable) {
      case 'temperature':
        return waterVaporSystem['temperature'][k][i][j];
      case 'humidity':
        return waterVaporSystem['humidity'][k][i][j];
      case 'u_wind':
        double baseWind = 10.0 * exp(-k * 1000.0 / 10000.0);
        double surfaceRoughnessEffect = -surface['roughness']! * 5.0 * 
                                       exp(-k * 1000.0 / 500.0);
        return baseWind + surfaceRoughnessEffect;
      case 'v_wind':
        return 5.0 * sin(j * 0.1 + timeStep * 0.05) * exp(-k * 1000.0 / 8000.0);
      case 'cloud_water':
        return waterVaporSystem['cloud_water'][k][i][j];
      case 'cloud_ice':
        return waterVaporSystem['cloud_ice'][k][i][j];
      case 'rain_water':
        return waterVaporSystem['rain_water'][k][i][j];
      case 'vertical_velocity':
        return waterVaporSystem['vertical_velocity'][k][i][j];
      default:
        return 0.0;
    }
  }
  
  /// 获取系统状态（备用方案）
  static Map<String, dynamic> _getFallbackStatus() {
    return {
      'server': 'Fallback Mode',
      'status': 'running',
      'radar_files': 5,
      'wrf_available': true,
      'timestamp': DateTime.now().toIso8601String(),
      'message': 'Linux backend not available, using fallback mode'
    };
  }
}