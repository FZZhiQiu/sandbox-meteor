import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 专业气象UI组件库
class ProfessionalWeatherWidgets {
  
  /// 专业数据卡片
  static Widget buildDataCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    double? trend,
    String? trendDirection,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.2),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          value,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (unit.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Text(
                            unit,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (trend != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  trendDirection == 'up' ? Icons.trending_up : 
                  trendDirection == 'down' ? Icons.trending_down : 
                  Icons.trending_flat,
                  color: trendDirection == 'up' ? Colors.red[400] :
                           trendDirection == 'down' ? Colors.blue[400] :
                           Colors.grey[400],
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${trend!.abs().toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: trendDirection == 'up' ? Colors.red[400] :
                           trendDirection == 'down' ? Colors.blue[400] :
                           Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '较昨日',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
  
  /// 专业图表容器
  static Widget buildChartContainer({
    required String title,
    required Widget child,
    List<Widget>? actions,
    Color? borderColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E27),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ?? Colors.white.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (actions != null) ...actions,
              ],
            ),
          ),
          // 图表内容
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
  
  /// 专业趋势图
  static Widget buildTrendChart({
    required List<double> data,
    required List<String> labels,
    Color lineColor = Colors.cyan,
    Color gradientColor = Colors.cyan,
  }) {
    return CustomPaint(
      painter: TrendChartPainter(
        data: data,
        labels: labels,
        lineColor: lineColor,
        gradientColor: gradientColor,
      ),
      child: Container(),
    );
  }
  
  /// 专业仪表盘
  static Widget buildGauge({
    required double value,
    required double min,
    required double max,
    required String title,
    required String unit,
    List<Color>? colors,
  }) {
    return CustomPaint(
      painter: GaugePainter(
        value: value,
        min: min,
        max: max,
        title: title,
        unit: unit,
        colors: colors ?? [Colors.green, Colors.yellow, Colors.red],
      ),
      child: Container(),
    );
  }
  
  /// 专业地图组件
  static Widget buildProfessionalMap({
    required Widget child,
    List<Widget>? overlays,
    bool showScale = true,
    bool showCompass = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Stack(
        children: [
          // 地图内容
          child,
          
          // 叠加层
          if (overlays != null) ...overlays,
          
          // 比例尺
          if (showScale)
            Positioned(
              bottom: 16,
              left: 16,
              child: _buildScaleBar(),
            ),
          
          // 指南针
          if (showCompass)
            Positioned(
              top: 16,
              right: 16,
              child: _buildCompass(),
            ),
        ],
      ),
    );
  }
  
  /// 构建比例尺
  static Widget _buildScaleBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '10 km',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建指南针
  static Widget _buildCompass() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withOpacity(0.7),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
        ),
      ),
      child: Stack(
        children: [
          // 北方标记
          Positioned(
            top: 8,
            left: 26,
            child: Text(
              'N',
              style: TextStyle(
                color: Colors.red[400],
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // 指南针图标
          Center(
            child: Icon(
              Icons.navigation,
              color: Colors.white70,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
  
  /// 专业警告横幅
  static Widget buildWarningBanner({
    required String title,
    required String message,
    required IconData icon,
    required WarningLevel level,
    VoidCallback? onDismiss,
  }) {
    Color backgroundColor;
    Color iconColor;
    Color borderColor;
    
    switch (level) {
      case WarningLevel.low:
        backgroundColor = Colors.blue.withOpacity(0.2);
        iconColor = Colors.blue[400]!;
        borderColor = Colors.blue[400]!;
        break;
      case WarningLevel.medium:
        backgroundColor = Colors.orange.withOpacity(0.2);
        iconColor = Colors.orange[400]!;
        borderColor = Colors.orange[400]!;
        break;
      case WarningLevel.high:
        backgroundColor = Colors.red.withOpacity(0.2);
        iconColor = Colors.red[400]!;
        borderColor = Colors.red[400]!;
        break;
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: Icon(
                Icons.close,
                color: Colors.white.withOpacity(0.6),
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
  
  /// 专业时间轴
  static Widget buildTimeline({
    required List<TimelineItem> items,
    required Function(int) onItemTap,
  }) {
    return Container(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          return _buildTimelineItem(items[index], index, onItemTap);
        },
      ),
    );
  }
  
  /// 构建时间轴项
  static Widget _buildTimelineItem(
    TimelineItem item, 
    int index, 
    Function(int) onTap
  ) {
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        width: 100,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: item.isSelected 
              ? Colors.cyan.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: item.isSelected 
                ? Colors.cyan[400]!
                : Colors.white.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Text(
              item.time,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),
            Icon(
              item.icon,
              color: item.color,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 专业数据网格
  static Widget buildDataGrid({
    required List<String> headers,
    required List<List<String>> data,
    required Function(int, int) onCellTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          // 表头
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: headers.map((header) {
                return Expanded(
                  child: Text(
                    header,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.cyan[400],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          // 数据行
          Expanded(
            child: ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, rowIndex) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  child: Row(
                    children: data[rowIndex].map((cell) {
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => onCellTap(rowIndex, data[rowIndex].indexOf(cell)),
                          child: Text(
                            cell,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  /// 专业状态指示器
  static Widget buildStatusIndicator({
    required String label,
    required String value,
    required StatusStatus status,
    double? progress,
  }) {
    Color statusColor;
    IconData statusIcon;
    
    switch (status) {
      case StatusStatus.good:
        statusColor = Colors.green[400]!;
        statusIcon = Icons.check_circle;
        break;
      case StatusStatus.warning:
        statusColor = Colors.orange[400]!;
        statusIcon = Icons.warning;
        break;
      case StatusStatus.error:
        statusColor = Colors.red[400]!;
        statusIcon = Icons.error;
        break;
      case StatusStatus.unknown:
        statusColor = Colors.grey[400]!;
        statusIcon = Icons.help;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                statusIcon,
                color: statusColor,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 8),
            Container(
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: Colors.white.withOpacity(0.2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress!,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: statusColor,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 趋势图绘制器
class TrendChartPainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;
  final Color lineColor;
  final Color gradientColor;
  
  TrendChartPainter({
    required this.data,
    required this.labels,
    required this.lineColor,
    required this.gradientColor,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    
    final padding = 40.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;
    
    // 绘制网格
    _drawGrid(canvas, padding, chartWidth, chartHeight);
    
    // 绘制坐标轴
    _drawAxes(canvas, padding, chartWidth, chartHeight);
    
    // 绘制数据线
    _drawDataLine(canvas, padding, chartWidth, chartHeight);
    
    // 绘制数据点
    _drawDataPoints(canvas, padding, chartWidth, chartHeight);
    
    // 绘制标签
    _drawLabels(canvas, padding, chartWidth, chartHeight);
  }
  
  void _drawGrid(Canvas canvas, double padding, double width, double height) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    
    // 水平网格线
    for (int i = 0; i <= 5; i++) {
      double y = padding + (height / 5) * i;
      canvas.drawLine(
        Offset(padding, y),
        Offset(padding + width, y),
        gridPaint,
      );
    }
    
    // 垂直网格线
    for (int i = 0; i < data.length; i++) {
      double x = padding + (width / (data.length - 1)) * i;
      canvas.drawLine(
        Offset(x, padding),
        Offset(x, padding + height),
        gridPaint,
      );
    }
  }
  
  void _drawAxes(Canvas canvas, double padding, double width, double height) {
    final axisPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    // X轴
    canvas.drawLine(
      Offset(padding, padding + height),
      Offset(padding + width, padding + height),
      axisPaint,
    );
    
    // Y轴
    canvas.drawLine(
      Offset(padding, padding),
      Offset(padding, padding + height),
      axisPaint,
    );
  }
  
  void _drawDataLine(Canvas canvas, double padding, double width, double height) {
    if (data.length < 2) return;
    
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          gradientColor.withOpacity(0.3),
          gradientColor.withOpacity(0.1),
        ],
      ).createShader(Rect.fromLTWH(padding, padding, width, height));
    
    double minValue = data.reduce(math.min);
    double maxValue = data.reduce(math.max);
    double range = maxValue - minValue;
    
    Path path = Path();
    
    for (int i = 0; i < data.length; i++) {
      double x = padding + (width / (data.length - 1)) * i;
      double y = padding + height - ((data[i] - minValue) / range) * height;
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    // 绘制渐变填充区域
    Path fillPath = Path.from(path);
    fillPath.lineTo(padding + width, padding + height);
    fillPath.lineTo(padding, padding + height);
    fillPath.close();
    
    canvas.drawPath(fillPath, gradientPaint);
    
    // 绘制线条
    canvas.drawPath(path, linePaint);
  }
  
  void _drawDataPoints(Canvas canvas, double padding, double width, double height) {
    final pointPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    
    double minValue = data.reduce(math.min);
    double maxValue = data.reduce(math.max);
    double range = maxValue - minValue;
    
    for (int i = 0; i < data.length; i++) {
      double x = padding + (width / (data.length - 1)) * i;
      double y = padding + height - ((data[i] - minValue) / range) * height;
      
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }
  }
  
  void _drawLabels(Canvas canvas, double padding, double width, double height) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    // X轴标签
    for (int i = 0; i < labels.length && i < data.length; i++) {
      double x = padding + (width / (data.length - 1)) * i;
      
      textPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 10,
        ),
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          x - textPainter.width / 2,
          padding + height + 5,
        ),
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// 仪表盘绘制器
class GaugePainter extends CustomPainter {
  final double value;
  final double min;
  final double max;
  final String title;
  final String unit;
  final List<Color> colors;
  
  GaugePainter({
    required this.value,
    required this.min,
    required this.max,
    required this.title,
    required this.unit,
    required this.colors,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 40;
    
    // 绘制背景弧
    _drawBackgroundArc(canvas, center, radius);
    
    // 绘制数值弧
    _drawValueArc(canvas, center, radius);
    
    // 绘制刻度
    _drawScale(canvas, center, radius);
    
    // 绘制指针
    _drawPointer(canvas, center, radius);
    
    // 绘制中心圆
    _drawCenterCircle(canvas, center);
    
    // 绘制数值文本
    _drawValueText(canvas, center, radius);
  }
  
  void _drawBackgroundArc(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius),
      math.pi * 0.75,
      math.pi * 1.5,
      false,
      paint,
    );
  }
  
  void _drawValueArc(Canvas canvas, Offset center, double radius) {
    double percentage = (value - min) / (max - min);
    double sweepAngle = math.pi * 1.5 * percentage;
    
    final paint = Paint()
      ..shader = SweepGradient(
        startAngle: math.pi * 0.75,
        endAngle: math.pi * 2.25,
        colors: colors,
      ).createShader(Rect.fromCircle(center: center, radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius),
      math.pi * 0.75,
      sweepAngle,
      false,
      paint,
    );
  }
  
  void _drawScale(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    for (int i = 0; i <= 10; i++) {
      double angle = math.pi * 0.75 + (math.pi * 1.5 / 10) * i;
      double startRadius = radius - 25;
      double endRadius = radius - 30;
      
      double x1 = center.dx + startRadius * math.cos(angle);
      double y1 = center.dy + startRadius * math.sin(angle);
      double x2 = center.dx + endRadius * math.cos(angle);
      double y2 = center.dy + endRadius * math.sin(angle);
      
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }
  
  void _drawPointer(Canvas canvas, Offset center, double radius) {
    double percentage = (value - min) / (max - min);
    double angle = math.pi * 0.75 + math.pi * 1.5 * percentage;
    
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    
    double pointerLength = radius - 35;
    double x = center.dx + pointerLength * math.cos(angle);
    double y = center.dy + pointerLength * math.sin(angle);
    
    canvas.drawLine(center, Offset(x, y), paint);
  }
  
  void _drawCenterCircle(Canvas canvas, Offset center) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, 8, paint);
  }
  
  void _drawValueText(Canvas canvas, Offset center, double radius) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    // 数值
    textPainter.text = TextSpan(
      text: value.toStringAsFixed(1),
      style: TextStyle(
        color: Colors.white,
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy + 20,
      ),
    );
    
    // 单位
    textPainter.text = TextSpan(
      text: unit,
      style: TextStyle(
        color: Colors.white.withOpacity(0.7),
        fontSize: 14,
      ),
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy + 55,
      ),
    );
    
    // 标题
    textPainter.text = TextSpan(
      text: title,
      style: TextStyle(
        color: Colors.white.withOpacity(0.5),
        fontSize: 12,
      ),
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy + 75,
      ),
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// 时间轴项
class TimelineItem {
  final String time;
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  
  TimelineItem({
    required this.time,
    required this.label,
    required this.icon,
    required this.color,
    this.isSelected = false,
  });
}

/// 警告级别
enum WarningLevel {
  low,
  medium,
  high,
}

/// 状态状态
enum StatusStatus {
  good,
  warning,
  error,
  unknown,
}