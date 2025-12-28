import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 高级可视化组件库
class AdvancedVisualization {
  
  /// 3D气象可视化组件
  static Widget build3DWeatherVisualization({
    required Map<String, dynamic> weatherData,
    required double width,
    required double height,
    bool enableRotation = true,
    bool enableZoom = true,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0A0E27),
            const Color(0xFF1A237E),
            const Color(0xFF283593),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: CustomPaint(
        painter: Weather3DPainter(
          weatherData: weatherData,
          enableRotation: enableRotation,
          enableZoom: enableZoom,
        ),
        child: Container(),
      ),
    );
  }
  
  /// 高级雷达组件
  static Widget buildAdvancedRadar({
    required List<RadarScan> scanData,
    required double size,
    bool enableDoppler = true,
    bool enableElevation = true,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E27),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.cyan.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          // 雷达背景
          CustomPaint(
            painter: RadarBackgroundPainter(),
            child: Container(),
          ),
          
          // 扫描线
          ...scanData.map((scan) => _buildScanLine(scan, size)),
          
          // 数据点
          ...scanData.map((scan) => _buildRadarDataPoint(scan, size)),
          
          // 高程显示
          if (enableElevation)
            Positioned(
              bottom: 20,
              right: 20,
              child: _buildElevationDisplay(scanData),
            ),
          
          // 多普勒显示
          if (enableDoppler)
            Positioned(
              top: 20,
              right: 20,
              child: _buildDopplerDisplay(scanData),
            ),
        ],
      ),
    );
  }
  
  /// 构建扫描线
  static Widget _buildScanLine(RadarScan scan, double size) {
    return AnimatedBuilder(
      animation: scan.animationController,
      builder: (context, child) {
        double angle = scan.animationController.value * 2 * math.pi;
        
        return Transform.rotate(
          angle: angle,
          child: Container(
            width: size,
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.cyan.withOpacity(0.8),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  /// 构建雷达数据点
  static Widget _buildRadarDataPoint(RadarScan scan, double size) {
    return Positioned(
      left: size / 2 + scan.x - 5,
      top: size / 2 + scan.y - 5,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _getReflectivityColor(scan.reflectivity),
          boxShadow: [
            BoxShadow(
              color: _getReflectivityColor(scan.reflectivity).withOpacity(0.5),
              blurRadius: 5,
            ),
          ],
        ),
      ),
    );
  }
  
  /// 构建高程显示
  static Widget _buildElevationDisplay(List<RadarScan> scanData) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '高程',
            style: TextStyle(
              color: Colors.cyan[300],
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${scanData.map((s) => s.elevation).reduce(math.max).toStringAsFixed(1)} km',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建多普勒显示
  static Widget _buildDopplerDisplay(List<RadarScan> scanData) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '径向速度',
            style: TextStyle(
              color: Colors.orange[300],
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${scanData.map((s) => s.velocity).reduce(math.max).toStringAsFixed(1)} m/s',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  /// 获取反射率颜色
  static Color _getReflectivityColor(double reflectivity) {
    if (reflectivity > 60) return Colors.red[400]!;
    if (reflectivity > 40) return Colors.orange[400]!;
    if (reflectivity > 20) return Colors.yellow[400]!;
    return Colors.green[400]!;
  }
  
  /// 气象粒子系统
  static Widget buildWeatherParticleSystem({
    required ParticleConfig config,
    required double width,
    required double height,
  }) {
    return WeatherParticleSystem(
      config: config,
      width: width,
      height: height,
    );
  }
  
  /// 等值线组件
  static Widget buildIsolineMap({
    required List<IsolineData> isolines,
    required double width,
    required double height,
    IsolineType type = IsolineType.temperature,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: CustomPaint(
        painter: IsolinePainter(
          isolines: isolines,
          type: type,
        ),
        child: Container(),
      ),
    );
  }
  
  /// 风场可视化
  static Widget buildWindField({
    required List<WindVector> windVectors,
    required double width,
    required double height,
    WindFieldType type = WindFieldType.streamline,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: CustomPaint(
        painter: WindFieldPainter(
          windVectors: windVectors,
          type: type,
        ),
        child: Container(),
      ),
    );
  }
  
  /// 热力图组件
  static Widget buildHeatmap({
    required List<HeatmapData> data,
    required double width,
    required double height,
    ColorGradient gradient = const LinearGradient(
      colors: [Colors.blue, Colors.green, Colors.yellow, Colors.red],
    ),
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: CustomPaint(
        painter: HeatmapPainter(
          data: data,
          gradient: gradient,
        ),
        child: Container(),
      ),
    );
  }
  
  /// 立体云图组件
  static Widget build3DCloudMap({
    required List<CloudData> clouds,
    required double width,
    required double height,
    double cameraAngle = 30.0,
    double cameraHeight = 1000.0,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF87CEEB).withOpacity(0.3),
            const Color(0xFF4682B4).withOpacity(0.1),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: CustomPaint(
        painter: Cloud3DPainter(
          clouds: clouds,
          cameraAngle: cameraAngle,
          cameraHeight: cameraHeight,
        ),
        child: Container(),
      ),
    );
  }
  
  /// 雷电追踪组件
  static Widget buildLightningTracker({
    required List<LightningStrike> strikes,
    required double width,
    required double height,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: strikes.map((strike) => _buildLightningStrike(strike, width, height)).toList(),
      ),
    );
  }
  
  /// 构建闪电
  static Widget _buildLightningStrike(LightningStrike strike, double width, double height) {
    return AnimatedBuilder(
      animation: strike.animationController,
      builder: (context, child) {
        double progress = strike.animationController.value;
        
        return CustomPaint(
          painter: LightningPainter(
            strike: strike,
            progress: progress,
          ),
          child: Container(),
        );
      },
    );
  }
}

/// 3D气象绘制器
class Weather3DPainter extends CustomPainter {
  final Map<String, dynamic> weatherData;
  final bool enableRotation;
  final bool enableZoom;
  double _rotation = 0.0;
  double _zoom = 1.0;
  
  Weather3DPainter({
    required this.weatherData,
    required this.enableRotation,
    required this.enableZoom,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // 绘制3D地形
    _draw3DTerrain(canvas, center, size);
    
    // 绘制3D云层
    _draw3DClouds(canvas, center, size);
    
    // 绘制3D降水
    _draw3DPrecipitation(canvas, center, size);
    
    // 绘制3D风场
    _draw3DWindField(canvas, center, size);
  }
  
  void _draw3DTerrain(Canvas canvas, Offset center, Size size) {
    // 简化的3D地形绘制
    final terrainPaint = Paint()
      ..color = Colors.brown[700]!.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    
    // 绘制地形网格
    int gridSize = 20;
    double cellWidth = size.width / gridSize;
    double cellHeight = size.height / gridSize;
    
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        double x = center.x - size.width / 2 + j * cellWidth;
        double y = center.y - size.height / 2 + i * cellHeight;
        
        // 模拟地形高度
        double elevation = math.sin(i * 0.3) * math.cos(j * 0.3) * 20;
        double size = 8 + elevation * 0.2;
        
        // 绘制地形块
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(x, y - elevation),
            width: cellWidth - 2,
            height: cellHeight - 2,
          ),
          terrainPaint,
        );
      }
    }
  }
  
  void _draw3DClouds(Canvas canvas, Offset center, Size size) {
    final cloudPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    
    // 模拟3D云层
    List<Map<String, dynamic>> clouds = [
      {'x': -100, 'y': -50, 'z': 100, 'size': 60},
      {'x': 80, 'y': 30, 'z': 120, 'size': 80},
      {'x': -30, 'y': 80, 'z': 110, 'size': 50},
    ];
    
    for (var cloud in clouds) {
      // 3D透视投影
      double scale = 1.0 / (1.0 + cloud['z'] / 200.0);
      double size = cloud['size'] * scale;
      
      double x = center.x + cloud['x'] * scale;
      double y = center.y + cloud['y'] * scale - cloud['z'] * 0.5;
      
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: size,
          height: size * 0.6,
        ),
        cloudPaint,
      );
    }
  }
  
  void _draw3DPrecipitation(Canvas canvas, Offset center, Size size) {
    final rainPaint = Paint()
      ..color = Colors.blue[300]!.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2;
    
    // 模拟3D降水
    for (int i = 0; i < 100; i++) {
      double x = center.x + (math.Random().nextDouble() - 0.5) * size.width * 0.8;
      double y = center.y + (math.Random().nextDouble() - 0.5) * size.height * 0.8;
      double length = 10 + math.Random().nextDouble() * 20;
      
      canvas.drawLine(
        Offset(x, y),
        Offset(x, y + length),
        rainPaint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// 雷达背景绘制器
class RadarBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    
    // 背景渐变
    final backgroundPaint = Paint()
      ..shader = RadialGradient(
        center: center,
        radius: radius,
        colors: [
          const Color(0xFF0D47A1).withOpacity(0.9),
          const Color(0xFF0A0E27),
        ],
      ).createShader(Rect.fromCircle(center: radius));
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);
    
    // 雷达圆圈
    _drawRadarCircles(canvas, center, radius);
    
    // 雷达十字线
    _drawRadarCrossLines(canvas, center, radius);
  }
  
  void _drawRadarCircles(Canvas canvas, Offset center, double radius) {
    final circlePaint = Paint()
      ..color = Colors.cyan.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    for (int i = 1; i <= 5; i++) {
      canvas.drawCircle(center, radius * i / 5, circlePaint);
    }
  }
  
  void _drawRadarCrossLines(Canvas canvas, Offset center, double radius) {
    final linePaint = Paint()
      ..color = Colors.cyan.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    // 水平线
    canvas.drawLine(
      Offset(center.x - radius, center.y),
      Offset(center.x + radius, center.y),
      linePaint,
    );
    
    // 垂直线
    canvas.drawLine(
      Offset(center.x, center.y - radius),
      Offset(center.x, center.y + radius),
      linePaint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// 等高线绘制器
class IsolinePainter extends CustomPainter {
  final List<IsolineData> isolines;
  final IsolineType type;
  
  IsolinePainter({
    required this.isolines,
    required this.type,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    Color lineColor = _getIsolineColor(type);
    
    for (IsolineData isolate in isolines) {
      _drawIsoline(canvas, isolate, lineColor);
    }
  }
  
  void _drawIsoline(Canvas canvas, IsolineData isolate, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    
    for (int i = 0; i < isolate.points.length - 1; i++) {
      canvas.drawLine(
        isolate.points[i],
        isolate.points[i + 1],
        paint,
      );
    }
    
    // 绘制标签
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    textPainter.text = TextSpan(
      text: '${isolate.value}';
      style: TextStyle(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, isolate.labelPosition);
  }
  
  Color _getIsolineColor(IsolineType type) {
    switch (type) {
      case IsolineType.temperature:
        return Colors.red[300]!;
      case IsolineType.pressure:
        return Colors.blue[300]!;
      case IsolineType.humidity:
        return Colors.green[300]!;
      case IsolineType.wind:
        return Colors.purple[300]!;
      default:
        return Colors.grey[300]!;
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// 风场绘制器
class WindFieldPainter extends CustomPainter {
  final List<WindVector> windVectors;
  final WindFieldType type;
  
  WindFieldPainter({
    required this.windVectors,
    required this.type,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    switch (type) {
      case WindFieldType.streamline:
        _drawStreamlines(canvas, size);
      case WindFieldType.barb:
        _drawBarbs(canvas, size);
      case WindFieldType.arrow:
        _drawArrows(canvas, size);
    }
  }
  
  void _drawStreamlines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyan[300]!.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    
    for (WindVector vector in windVectors) {
      _drawStreamline(canvas, vector, paint);
    }
  }
  
  void _drawStreamline(Canvas canvas, WindVector vector, Paint paint) {
    List<Offset> points = _calculateStreamline(vector, size);
    
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }
  
  List<Offset> _calculateStreamline(WindVector vector, Size size) {
    List<Offset> points = [];
    const int steps = 20;
    
    double x = vector.x;
    double y = vector.y;
    double u = vector.u;
    double v = vector.v;
    
    for (int i = 0; i < steps; i++) {
      points.add(Offset(x, y));
      
      // 使用风场矢量计算流线
      x += u * 2;
      y += v * 2;
      
      // 边界检查
      if (x < 0 || x > size.width || y < 0 || y > size.height) break;
    }
    
    return points;
  }
  
  void _drawBarbs(Canvas canvas, Size size) {
    final barbPaint = Paint()
      ..color = Colors.cyan[300]!.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    for (WindVector vector in windVectors) {
      _drawBarb(canvas, vector, barbPaint);
    }
  }
  
  void _drawBarb(Canvas canvas, WindVector vector, Paint paint) {
    double angle = math.atan2(vector.v, vector.u);
    double speed = math.sqrt(vector.u * vector.u + vector.v * vector.v);
    
    // 绘制风向杆
    double barbLength = 15 + speed * 2;
    double endX = vector.x + barbLength * math.cos(angle);
    double endY = vector.y + barbLength * math.sin(angle);
    
    // 绘制风向杆主线
    canvas.drawLine(
      Offset(vector.x, vector.y),
      Offset(endX, endY),
      paint,
    );
    
    // 绘制风向杆短横线
    double barbAngle = angle + math.pi / 6;
    for (int i = 0; i < 3; i++) {
      double barbX = endX - 5 * math.cos(barbAngle + i * math.pi / 6);
      double barbY = endY - 5 * math.sin(barbAngle + i * math.pi / 6);
      
      canvas.drawLine(
        Offset(barbX, barbY),
        Offset(endX, endY),
        paint,
      );
    }
  }
  
  void _drawArrows(Canvas canvas, Size size) {
    final arrowPaint = Paint()
      ..color = Colors.cyan[300]!.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    
    for (WindVector vector in windVectors) {
      _drawArrow(canvas, vector, arrowPaint);
    }
  }
  
  void _drawArrow(Canvas canvas, WindVector vector, Paint paint) {
    double angle = math.atan2(vector.v, vector.u);
    double speed = math.sqrt(vector.u * vector.u + vector.v * vector.v);
    double arrowLength = 20 + speed;
    
    // 计算箭头终点
    double endX = vector.x + arrowLength * math.cos(angle);
    double endY = vector.y + arrowLength * math.sin(angle);
    
    // 绘制箭头主体
    canvas.drawLine(
      Offset(vector.x, vector.y),
      Offset(endX, endY),
      paint,
    );
    
    // 绘制箭头头部
    double headLength = 8;
    double headAngle = angle + math.pi;
    
    Offset headLeft = Offset(
      endX + headLength * math.cos(headAngle - math.pi / 6),
      endY + headLength * math.sin(headAngle - math.pi / 6),
    );
    
    Offset headRight = Offset(
      endX + headLength * math.cos(headAngle + math.pi / 6),
      endY + headLength * math.sin(headAngle + math.pi / 6),
    );
    
    Path headPath = Path();
    headPath.moveTo(endX, endY);
    headPath.lineTo(headLeft.dx, headLeft.dy);
    headPath.moveTo(endX, endY);
    headPath.lineTo(headRight.dx, headRight.dy);
    headPath.close();
    
    canvas.drawPath(headPath, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// 热力图绘制器
class HeatmapPainter extends CustomPainter {
  final List<HeatmapData> data;
  final ColorGradient gradient;
  
  HeatmapPainter({
    required this.data,
    required this.gradient,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // 创建热力图
    final heatPaint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), heatPaint);
    
    // 绘制数据点
    for (HeatmapData point in data) {
      _drawHeatmapPoint(canvas, point);
    }
  }
  
  void _drawHeatmapPoint(Canvas canvas, HeatmapData point) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    canvas.drawCircle(
      Offset(point.x, point.y),
      point.size,
      paint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// 3D云层绘制器
class Cloud3DPainter extends CustomPainter {
  final List<CloudData> clouds;
  final double cameraAngle;
  final double cameraHeight;
  
  Cloud3DPainter({
    required this.clouds,
    required this.cameraAngle,
    required this.cameraHeight,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // 按z坐标排序云层（远到近）
    clouds.sort((a, b) => b.z.compareTo(a.z));
    
    for (CloudData cloud in clouds) {
      _draw3DCloud(canvas, cloud, size);
    }
  }
  
  void _draw3DCloud(Canvas canvas, CloudData cloud, Size size) {
    // 计算透视投影
    double scale = 1.0 / (1.0 + cloud.z / cameraHeight);
    double size = cloud.size * scale;
    
    // 计算位置
    double x = size.width / 2 + cloud.x * scale;
    double y = size.height / 2 + cloud.y * scale - cloud.z * 0.5;
    
    // 绘制云朵
    final paint = Paint()
      ..color = Colors.white.withOpacity(cloud.opacity)
      ..style = PaintingStyle.fill;
    
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x, y),
        width: size,
        height: size * 0.6,
      ),
      paint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// 闪电绘制器
class LightningPainter extends CustomPainter {
  final LightningStrike strike;
  final double progress;
  
  LightningPainter({
    required this.strike,
    required this.progress,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    
    // 绘制主闪电
    _drawLightningBolt(canvas, strike, paint, progress);
    
    // 绘制分支
    if (progress > 0.3) {
      for (LightningBranch branch in strike.branches) {
        _drawLightningBranch(canvas, branch, paint, progress);
      }
    }
  }
  
  void _drawLightningBolt(Canvas canvas, LightningStrike strike, Paint paint, double progress) {
    List<Offset> points = strike.points;
    
    // 绘制主闪电路径
    for (int i = 0; i < points.length - 1 && i < points.length * progress; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }
  
  void _drawLightningBranch(Canvas canvas, LightningBranch branch, Paint paint, double progress) {
    List<Offset> points = branch.points;
    
    for (int i = 0; i < points.length - 1 && i < points.length * progress; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// 粒子系统
class WeatherParticleSystem extends StatefulWidget {
  final ParticleConfig config;
  final double width;
  final double height;
  
  const WeatherParticleSystem({
    Key? key,
    required this.config,
    required this.width,
    required this.height,
  }) : super(key: key);
  
  @override
  _WeatherParticleSystemState createState() => _WeatherParticleSystemState();
}

class _WeatherParticleSystemState extends State<WeatherParticleSystem>
    with TickerProviderStateMixin {
  List<Particle> _particles = [];
  
  @override
  void initState() {
    super.initState();
    _initializeParticles();
    _startAnimation();
  }
  
  void _initializeParticles() {
    for (int i = 0; i < config.particleCount; i++) {
      _particles.add(Particle(
        x: math.Random().nextDouble() * width,
        y: math.Random().nextDouble() * height,
        vx: (math.Random().nextDouble() - 0.5) * config.windSpeed,
        vy: (math.Random().nextDouble() - 0.5) * config.windSpeed,
        size: config.minSize + math.Random().nextDouble() * (config.maxSize - config.minSize),
        opacity: config.minOpacity + math.Random().nextDouble() * (config.maxOpacity - config.minOpacity),
        color: config.colors[math.Random().nextInt(config.colors.length)],
      ));
    }
  }
  
  void _startAnimation() {
    controller.repeat(period: Duration(milliseconds: 16));
  }
  
  @override
  void tick() {
    setState(() {
      _updateParticles();
      _removeDeadParticles();
      
      if (_particles.length < config.particleCount) {
        _addNewParticle();
      }
    });
  }
  
  void _updateParticles() {
    for (Particle particle in _particles) {
      particle.x += particle.vx;
      particle.y += particle.vy;
      particle.life -= 1;
      
      // 添加物理效果
      particle.vy += config.gravity;
      
      // 添加风力影响
      particle.vx += config.windForce;
      particle.vy += config.windForce * 0.5;
    }
  }
  
  void _removeDeadParticles() {
    _particles.removeWhere((particle) => particle.life <= 0);
  }
  
  void _addNewParticle() {
    _particles.add(Particle(
      x: math.Random().nextDouble() * width,
      y: -20, // 从顶部开始
      vx: (math.Random().nextDouble() - 0.5) * config.windSpeed,
      vy: math.Random().nextDouble() * 2 + 1,
      size: config.minSize + math.Random().nextDouble() * (config.maxSize - config.minSize),
      opacity: config.maxOpacity,
      color: config.colors[math.Random().nextInt(config.colors.length)],
      life: config.maxLife,
    ));
  }
  
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ParticlePainter(particles: _particles),
      child: Container(),
    );
  }
  
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

/// 粒子绘制器
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  
  ParticlePainter({required this.particles});
  
  @override
  void paint(Canvas canvas, Size size) {
    for (Particle particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.size,
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// 数据模型类
class RadarScan {
  final double x;
  final double y;
  final double reflectivity;
  final double velocity;
  final double elevation;
  final AnimationController animationController;
  
  RadarScan({
    required this.x,
    required this.y,
    required this.reflectivity,
    required this.velocity,
    required this.elevation,
    required TickerProvider vsync,
  }) : animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: vsync,
    )..repeat();
}

class LightningStrike {
  final List<Offset> points;
  final List<LightningBranch> branches;
  final AnimationController animationController;
  
  LightningStrike({
    required this.points,
    required this.branches,
    required TickerProvider vsync,
  }) : animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: vsync,
    )..forward();
}

class LightningBranch {
  final List<Offset> points;
  final AnimationController animationController;
  
  LightningBranch({
    required this.points,
    required TickerProvider vsync,
  }) : animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: vsync,
    )..forward();
}

class CloudData {
  final double x;
  final double y;
  final double z;
  final double size;
  final double opacity;
  
  CloudData({
    required this.x,
    required this.y,
    required this.z,
    required this.size,
    required this.opacity,
  });
}

class IsolineData {
  final double value;
  final List<Offset> points;
  final Offset labelPosition;
  
  IsolineData({
    required this.value,
    required this.points,
    required this.labelPosition,
  });
}

enum IsolineType {
  temperature,
  pressure,
  humidity,
  wind,
}

class WindVector {
  final double x;
  final double y;
  final double u;
  final double v;
  
  WindVector({
    required this.x,
    required this.y,
    required this.u,
    required this.v,
  });
}

enum WindFieldType {
  streamline,
  barb,
  arrow,
}

class HeatmapData {
  final double x;
  final double y;
  final double value;
  final double size;
  
  HeatmapData({
    required this.x,
    required this.y,
    required this.value,
    required this.size,
  });
}

class Particle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double opacity;
  Color color;
  double life;
  
  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.opacity,
    required this.color,
    this.life = 100,
  });
}

class ParticleConfig {
  final int particleCount;
  final double windSpeed;
  final double windForce;
  final double gravity;
  final double minSize;
  final double maxSize;
  final double minOpacity;
  final double maxOpacity;
  final double maxLife;
  final List<Color> colors;
  
  ParticleConfig({
    required this.particleCount,
    required this.windSpeed,
    required this.windForce,
    required this.gravity,
    required this.minSize,
    required this.maxSize,
    required this.minOpacity,
    required this.maxOpacity,
    required this.maxLife,
    required this.colors,
  });
}