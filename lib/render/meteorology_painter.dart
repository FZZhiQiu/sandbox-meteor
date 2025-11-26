import 'dart:ui';
import 'package:flutter/painting.dart';
import 'package:vector_math/vector_math.dart';

import '../core/app_config.dart';
import '../models/meteorology_state.dart';

class MeteorologyPainter extends CustomPainter {
  final MeteorologyState state;
  final MeteorologyVariable selectedVariable;
  final double scaleFactor;
  
  MeteorologyPainter({
    required this.state,
    required this.selectedVariable,
    this.scaleFactor = 1.0,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final grid = state.grid;
    final cellWidth = size.width / grid.nx;
    final cellHeight = size.height / grid.ny;
    
    // 绘制底层地图
    _drawBaseMap(canvas, size);
    
    // 绘制气象数据
    _drawMeteorologyData(canvas, size, grid, cellWidth, cellHeight);
    
    // 绘制风场矢量
    if (selectedVariable == MeteorologyVariable.uWind ||
        selectedVariable == MeteorologyVariable.vWind) {
      _drawWindVectors(canvas, size, grid, cellWidth, cellHeight);
    }
    
    // 绘制图例
    _drawLegend(canvas, size);
  }
  
  // 绘制底图
  void _drawBaseMap(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF5F5DC) // 米色背景
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    
    // 绘制网格线
    final gridPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    
    final grid = state.grid;
    final cellWidth = size.width / grid.nx;
    final cellHeight = size.height / grid.ny;
    
    for (int i = 0; i <= grid.nx; i++) {
      final x = i * cellWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    
    for (int j = 0; j <= grid.ny; j++) {
      final y = j * cellHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }
  
  // 绘制气象数据
  void _drawMeteorologyData(Canvas canvas, Size size, dynamic grid, 
                           double cellWidth, double cellHeight) {
    // 选择要绘制的层级（通常是地面层）
    final k = 0;
    
    for (int j = 0; j < grid.ny; j++) {
      for (int i = 0; i < grid.nx; i++) {
        final value = grid.getValue(selectedVariable, i, j, k);
        final color = _valueToColor(value, selectedVariable);
        
        final paint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;
        
        final rect = Rect.fromLTWH(
          i * cellWidth,
          j * cellHeight,
          cellWidth,
          cellHeight,
        );
        
        canvas.drawRect(rect, paint);
      }
    }
  }
  
  // 绘制风场矢量
  void _drawWindVectors(Canvas canvas, Size size, dynamic grid,
                       double cellWidth, double cellHeight) {
    final k = 0; // 地面层
    final vectorPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    // 每隔几个网格点绘制一个矢量，避免过于密集
    const skip = 5;
    
    for (int j = 0; j < grid.ny; j += skip) {
      for (int i = 0; i < grid.nx; i += skip) {
        final uWind = grid.getValue(MeteorologyVariable.uWind, i, j, k);
        final vWind = grid.getValue(MeteorologyVariable.vWind, i, j, k);
        
        // 计算矢量的起点和终点
        final startX = i * cellWidth + cellWidth / 2;
        final startY = j * cellHeight + cellHeight / 2;
        
        // 缩放矢量长度
        final scale = 10.0 * scaleFactor;
        final endX = startX + uWind * scale;
        final endY = startY + vWind * scale;
        
        // 绘制矢量线
        canvas.drawLine(
          Offset(startX, startY),
          Offset(endX, endY),
          vectorPaint,
        );
        
        // 绘制箭头
        _drawArrow(canvas, startX, startY, endX, endY, vectorPaint);
      }
    }
  }
  
  // 绘制箭头
  void _drawArrow(Canvas canvas, double startX, double startY, 
                 double endX, double endY, Paint paint) {
    const arrowLength = 5.0;
    const arrowAngle = pi / 6;
    
    // 计算箭头角度
    final angle = atan2(endY - startY, endX - startX);
    
    // 绘制箭头的两条线
    final arrow1X = endX - arrowLength * cos(angle - arrowAngle);
    final arrow1Y = endY - arrowLength * sin(angle - arrowAngle);
    
    final arrow2X = endX - arrowLength * cos(angle + arrowAngle);
    final arrow2Y = endY - arrowLength * sin(angle + arrowAngle);
    
    canvas.drawLine(Offset(endX, endY), Offset(arrow1X, arrow1Y), paint);
    canvas.drawLine(Offset(endX, endY), Offset(arrow2X, arrow2Y), paint);
  }
  
  // 将数值转换为颜色
  Color _valueToColor(double value, MeteorologyVariable variable) {
    Color startColor, endColor;
    double minValue, maxValue;
    
    switch (variable) {
      case MeteorologyVariable.temperature:
        minValue = 200.0; // -73°C
        maxValue = 320.0; // 47°C
        startColor = Colors.blue;
        endColor = Colors.red;
        break;
        
      case MeteorologyVariable.pressure:
        minValue = 95000.0; // 950 hPa
        maxValue = 105000.0; // 1050 hPa
        startColor = Colors.purple;
        endColor = Colors.orange;
        break;
        
      case MeteorologyVariable.humidity:
        minValue = 0.0;
        maxValue = 100.0;
        startColor = Colors.white;
        endColor = Colors.blue;
        break;
        
      case MeteorologyVariable.precipitation:
        minValue = 0.0;
        maxValue = 10.0; // mm/h
        startColor = Colors.transparent;
        endColor = Colors.blue.shade700;
        break;
        
      case MeteorologyVariable.uWind:
      case MeteorologyVariable.vWind:
        minValue = -20.0; // m/s
        maxValue = 20.0;  // m/s
        startColor = Colors.green;
        endColor = Colors.red;
        break;
        
      default:
        minValue = 0.0;
        maxValue = 1.0;
        startColor = Colors.grey;
        endColor = Colors.black;
    }
    
    // 归一化数值
    final normalized = (value - minValue) / (maxValue - minValue);
    final clamped = normalized.clamp(0.0, 1.0);
    
    // 线性插值颜色
    return Color.lerp(startColor, endColor, clamped)!;
  }
  
  // 绘制图例
  void _drawLegend(Canvas canvas, Size size) {
    const legendWidth = 20.0;
    const legendHeight = 200.0;
    const legendX = 20.0;
    const legendY = 20.0;
    
    // 绘制颜色条
    for (int i = 0; i < legendHeight; i++) {
      final value = 1.0 - (i / legendHeight);
      final color = _valueToColor(value, selectedVariable);
      
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      
      canvas.drawRect(
        Rect.fromLTWH(legendX, legendY + i, legendWidth, 1.0),
        paint,
      );
    }
    
    // 绘制边框
    final borderPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    canvas.drawRect(
      Rect.fromLTWH(legendX, legendY, legendWidth, legendHeight),
      borderPaint,
    );
    
    // 绘制标签
    _drawLegendLabels(canvas, legendX, legendY, legendWidth, legendHeight);
  }
  
  // 绘制图例标签
  void _drawLegendLabels(Canvas canvas, double x, double y, 
                        double width, double height) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    // 根据变量类型绘制不同的标签
    String unit, minLabel, maxLabel;
    
    switch (selectedVariable) {
      case MeteorologyVariable.temperature:
        unit = '°C';
        minLabel = '-73';
        maxLabel = '47';
        break;
      case MeteorologyVariable.pressure:
        unit = 'hPa';
        minLabel = '950';
        maxLabel = '1050';
        break;
      case MeteorologyVariable.humidity:
        unit = '%';
        minLabel = '0';
        maxLabel = '100';
        break;
      case MeteorologyVariable.precipitation:
        unit = 'mm/h';
        minLabel = '0';
        maxLabel = '10';
        break;
      case MeteorologyVariable.uWind:
      case MeteorologyVariable.vWind:
        unit = 'm/s';
        minLabel = '-20';
        maxLabel = '20';
        break;
      default:
        unit = '';
        minLabel = '0';
        maxLabel = '1';
    }
    
    // 绘制最大值标签
    textPainter.text = TextSpan(
      text: '$maxLabel $unit',
      style: const TextStyle(
        color: Colors.black,
        fontSize: 12,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x + width + 5, y));
    
    // 绘制最小值标签
    textPainter.text = TextSpan(
      text: '$minLabel $unit',
      style: const TextStyle(
        color: Colors.black,
        fontSize: 12,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x + width + 5, y + height - 12));
  }
  
  @override
  bool shouldRepaint(MeteorologyPainter oldDelegate) {
    return oldDelegate.state != state ||
           oldDelegate.selectedVariable != selectedVariable ||
           oldDelegate.scaleFactor != scaleFactor;
  }
}