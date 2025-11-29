import 'dart:math';
import 'package:flutter/material.dart';
import '../models/meteorology_state.dart';

/// 天气图表绘制器
class WeatherChartPainter extends CustomPainter {
  final List<ChartDataPoint> data;
  final MeteorologyVariable selectedVariable;
  
  WeatherChartPainter({
    required this.data,
    required this.selectedVariable,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    final backgroundPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    // 绘制背景
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);
    
    // 绘制网格
    _drawGrid(canvas, size, gridPaint);
    
    // 绘制数据
    if (data.isNotEmpty) {
      _drawDataLine(canvas, size, paint);
      _drawDataPoints(canvas, size);
    }
    
    // 绘制坐标轴标签
    _drawAxisLabels(canvas, size);
  }
  
  void _drawGrid(Canvas canvas, Size size, Paint paint) {
    const gridLines = 10;
    
    // 垂直网格线
    for (int i = 0; i <= gridLines; i++) {
      final x = (size.width / gridLines) * i;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    
    // 水平网格线
    for (int i = 0; i <= gridLines; i++) {
      final y = (size.height / gridLines) * i;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }
  
  void _drawDataLine(Canvas canvas, Size size, Paint paint) {
    if (data.length < 2) return;
    
    final path = Path();
    
    for (int i = 0; i < data.length; i++) {
      final point = data[i];
      final x = (point.x / data.length) * size.width;
      final y = size.height - (point.value / _getMaxValue()) * size.height;
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        // 使用贝塞尔曲线平滑连接
        final prevPoint = data[i - 1];
        final prevX = (prevPoint.x / data.length) * size.width;
        final prevY = size.height - (prevPoint.value / _getMaxValue()) * size.height;
        
        final controlX = (prevX + x) / 2;
        path.quadraticBezierTo(controlX, prevY, x, y);
      }
    }
    
    canvas.drawPath(path, paint);
  }
  
  void _drawDataPoints(Canvas canvas, Size size) {
    final pointPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < data.length; i++) {
      final point = data[i];
      final x = (point.x / data.length) * size.width;
      final y = size.height - (point.value / _getMaxValue()) * size.height;
      
      canvas.drawCircle(Offset(x, y), 4.0, pointPaint);
    }
  }
  
  void _drawAxisLabels(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: _getVariableUnit(),
        style: const TextStyle(
          color: Colors.black,
          fontSize: 12,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    
    // 绘制Y轴标签
    canvas.save();
    canvas.translate(10, size.height / 2);
    canvas.rotate(-pi / 2);
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
    
    // 绘制X轴标签
    textPainter.text = const TextSpan(
      text: '时间',
      style: TextStyle(
        color: Colors.black,
        fontSize: 12,
      ),
    );
    textPainter.layout();
    
    canvas.save();
    canvas.translate(size.width / 2, size.height - 10);
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }
  
  double _getMaxValue() {
    if (data.isEmpty) return 1.0;
    return data.map((p) => p.value).reduce((a, b) => a > b ? a : b);
  }
  
  String _getVariableUnit() {
    switch (selectedVariable) {
      case MeteorologyVariable.temperature:
        return '温度 (°C)';
      case MeteorologyVariable.pressure:
        return '气压 (hPa)';
      case MeteorologyVariable.humidity:
        return '湿度 (%)';
      case MeteorologyVariable.uWind:
      case MeteorologyVariable.vWind:
        return '风速 (m/s)';
      case MeteorologyVariable.precipitation:
        return '降水 (mm/h)';
      default:
        return '数值';
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

/// 图表数据点
class ChartDataPoint {
  final double x;
  final double value;
  
  ChartDataPoint({required this.x, required this.value});
}

/// 扩展高级可视化组件
extension AdvancedVisualizationExtension on AdvancedVisualization {
  List<ChartDataPoint> _generateChartData() {
    final random = Random();
    final data = <ChartDataPoint>[];
    
    for (int i = 0; i < 50; i++) {
      data.add(ChartDataPoint(
        x: i.toDouble(),
        value: 20 + random.nextDouble() * 30,
      ));
    }
    
    return data;
  }
}