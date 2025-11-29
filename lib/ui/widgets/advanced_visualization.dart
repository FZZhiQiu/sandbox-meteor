import 'dart:math';
import 'package:flutter/material.dart';
import '../models/meteorology_state.dart';
import '../core/app_config.dart';
import 'weather_chart_painter.dart';

/// 高级可视化和分析组件
/// 提供专业的气象数据可视化和分析功能
class AdvancedVisualization extends StatefulWidget {
  final MeteorologyState state;
  final MeteorologyVariable selectedVariable;
  final VoidCallback? onAnalysisComplete;
  
  const AdvancedVisualization({
    super.key,
    required this.state,
    required this.selectedVariable,
    this.onAnalysisComplete,
  });
  
  @override
  State<AdvancedVisualization> createState() => _AdvancedVisualizationState();
}

class _AdvancedVisualizationState extends State<AdvancedVisualization>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  List<AnalysisResult> _analysisResults = [];
  bool _isAnalyzing = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // 初始分析
    _performInitialAnalysis();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 标题栏
          _buildHeader(context),
          
          // 标签页
          _buildTabBar(),
          
          // 内容区域
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDataAnalysisTab(),
                _buildVisualizationTab(),
                _buildStatisticsTab(),
                _buildExportTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.analytics,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '高级分析',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '当前变量: ${_getVariableDisplayName(widget.selectedVariable)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          
          // 分析按钮
          if (!_isAnalyzing)
            ElevatedButton.icon(
              onPressed: _performAnalysis,
              icon: const Icon(Icons.refresh),
              label: const Text('重新分析'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '分析中...',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: const [
        Tab(text: '数据分析', icon: Icon(Icons.data_usage)),
        Tab(text: '可视化', icon: Icon(Icons.visibility)),
        Tab(text: '统计信息', icon: Icon(Icons.bar_chart)),
        Tab(text: '导出', icon: Icon(Icons.download)),
      ],
    );
  }
  
  Widget _buildDataAnalysisTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 分析结果概览
          _buildAnalysisOverview(),
          
          const SizedBox(height: 16),
          
          // 详细分析结果
          Expanded(
            child: _buildDetailedAnalysis(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildVisualizationTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 可视化选项
          _buildVisualizationOptions(),
          
          const SizedBox(height: 16),
          
          // 图表区域
          Expanded(
            child: _buildChartArea(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatisticsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 基本统计
            _buildBasicStatistics(),
            
            const SizedBox(height: 20),
            
            // 高级统计
            _buildAdvancedStatistics(),
            
            const SizedBox(height: 20),
            
            // 趋势分析
            _buildTrendAnalysis(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildExportTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 导出选项
          _buildExportOptions(),
          
          const SizedBox(height: 20),
          
          // 预览区域
          Expanded(
            child: _buildExportPreview(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAnalysisOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '分析概览',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            if (_analysisResults.isEmpty)
              const Text('暂无分析数据')
            else
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: _analysisResults.map((result) {
                  return _buildAnalysisChip(result);
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAnalysisChip(AnalysisResult result) {
    Color color;
    IconData icon;
    
    switch (result.status) {
      case AnalysisStatus.success:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case AnalysisStatus.warning:
        color = Colors.orange;
        icon = Icons.warning;
        break;
      case AnalysisStatus.error:
        color = Colors.red;
        icon = Icons.error;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            result.title,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailedAnalysis() {
    return ListView.builder(
      itemCount: _analysisResults.length,
      itemBuilder: (context, index) {
        final result = _analysisResults[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            title: Text(result.title),
            subtitle: Text(result.description),
            leading: Icon(
              _getAnalysisIcon(result.type),
              color: _getAnalysisColor(result.status),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (result.details != null) ...[
                      Text(
                        '详细信息',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(result.details!),
                    ],
                    
                    if (result.recommendations.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        '建议',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      ...result.recommendations.map((rec) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• '),
                            Expanded(child: Text(rec)),
                          ],
                        ),
                      )),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildVisualizationOptions() {
    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          label: const Text('等值线'),
          selected: true,
          onSelected: (selected) {},
        ),
        ChoiceChip(
          label: const Text('矢量场'),
          selected: false,
          onSelected: (selected) {},
        ),
        ChoiceChip(
          label: const Text('剖面图'),
          selected: false,
          onSelected: (selected) {},
        ),
        ChoiceChip(
          label: const Text('时间序列'),
          selected: false,
          onSelected: (selected) {},
        ),
      ],
    );
  }
  
  Widget _buildChartArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomPaint(
        painter: WeatherChartPainter(
          data: _generateChartData(),
          selectedVariable: widget.selectedVariable,
        ),
        child: Container(),
      ),
    );
  }
  
  Widget _buildBasicStatistics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '基本统计',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildStatRow('最小值', '${_calculateMinValue().toStringAsFixed(2)}'),
            _buildStatRow('最大值', '${_calculateMaxValue().toStringAsFixed(2)}'),
            _buildStatRow('平均值', '${_calculateMeanValue().toStringAsFixed(2)}'),
            _buildStatRow('标准差', '${_calculateStdDev().toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAdvancedStatistics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '高级统计',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildStatRow('偏度', '${_calculateSkewness().toStringAsFixed(3)}'),
            _buildStatRow('峰度', '${_calculateKurtosis().toStringAsFixed(3)}'),
            _buildStatRow('变异系数', '${_calculateCV().toStringAsFixed(3)}'),
            _buildStatRow('数据范围', '${_calculateRange().toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTrendAnalysis() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '趋势分析',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            Text(
              '时间序列趋势分析功能开发中...',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildExportOptions() {
    return Wrap(
      spacing: 8,
      children: [
        ElevatedButton.icon(
          onPressed: () => _exportData('json'),
          icon: const Icon(Icons.code),
          label: const Text('JSON'),
        ),
        ElevatedButton.icon(
          onPressed: () => _exportData('csv'),
          icon: const Icon(Icons.table_chart),
          label: const Text('CSV'),
        ),
        ElevatedButton.icon(
          onPressed: () => _exportData('report'),
          icon: const Icon(Icons.description),
          label: const Text('报告'),
        ),
      ],
    );
  }
  
  Widget _buildExportPreview() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.preview,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 8),
            Text(
              '导出预览',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
  
  void _performInitialAnalysis() {
    setState(() {
      _isAnalyzing = true;
    });
    
    // 模拟分析过程
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _analysisResults = _generateAnalysisResults();
        _isAnalyzing = false;
      });
      
      _animationController.forward();
      
      if (widget.onAnalysisComplete != null) {
        widget.onAnalysisComplete!();
      }
    });
  }
  
  void _performAnalysis() {
    _performInitialAnalysis();
  }
  
  List<AnalysisResult> _generateAnalysisResults() {
    return [
      AnalysisResult(
        type: AnalysisType.dataQuality,
        title: '数据质量检查',
        description: '检查数据完整性和异常值',
        status: AnalysisStatus.success,
        details: '数据质量良好，未发现异常值',
        recommendations: [
          '建议定期检查数据质量',
          '保持传感器校准',
        ],
      ),
      AnalysisResult(
        type: AnalysisType.numericalStability,
        title: '数值稳定性',
        description: '检查数值计算的稳定性',
        status: AnalysisStatus.warning,
        details: '在某些区域发现数值不稳定性',
        recommendations: [
          '建议减小时间步长',
          '考虑使用更高阶的数值格式',
        ],
      ),
      AnalysisResult(
        type: AnalysisType.physicalConsistency,
        title: '物理一致性',
        description: '检查物理量的合理性',
        status: AnalysisStatus.success,
        details: '物理量在合理范围内',
        recommendations: [],
      ),
    ];
  }
  
  double _calculateMinValue() {
    // 模拟计算最小值
    return Random().nextDouble() * 100;
  }
  
  double _calculateMaxValue() {
    // 模拟计算最大值
    return 100 + Random().nextDouble() * 200;
  }
  
  double _calculateMeanValue() {
    // 模拟计算平均值
    return 150 + Random().nextDouble() * 50;
  }
  
  double _calculateStdDev() {
    // 模拟计算标准差
    return 20 + Random().nextDouble() * 30;
  }
  
  double _calculateSkewness() {
    // 模拟计算偏度
    return Random().nextDouble() * 2 - 1;
  }
  
  double _calculateKurtosis() {
    // 模拟计算峰度
    return Random().nextDouble() * 3;
  }
  
  double _calculateCV() {
    // 模拟计算变异系数
    return Random().nextDouble() * 0.5;
  }
  
  double _calculateRange() {
    // 模拟计算数据范围
    return _calculateMaxValue() - _calculateMinValue();
  }
  
  IconData _getAnalysisIcon(AnalysisType type) {
    switch (type) {
      case AnalysisType.dataQuality:
        return Icons.verified;
      case AnalysisType.numericalStability:
        return Icons.stacked_line_chart;
      case AnalysisType.physicalConsistency:
        return Icons.science;
    }
  }
  
  Color _getAnalysisColor(AnalysisStatus status) {
    switch (status) {
      case AnalysisStatus.success:
        return Colors.green;
      case AnalysisStatus.warning:
        return Colors.orange;
      case AnalysisStatus.error:
        return Colors.red;
    }
  }
  
  void _exportData(String format) {
    // 实现数据导出逻辑
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('导出为 $format 格式')),
    );
  }
  
  List<ChartDataPoint> _generateChartData() {
    final random = Random();
    final data = <ChartDataPoint>[];
    
    // 基于实际气象数据生成图表数据
    final gridData = widget.state.grid.getVariableData(widget.selectedVariable);
    if (gridData != null) {
      // 提取中心剖面的数据
      final centerX = widget.state.grid.nx ~/ 2;
      final centerY = widget.state.grid.ny ~/ 2;
      
      for (int k = 0; k < widget.state.grid.nz; k++) {
        final value = gridData[k][centerY][centerX];
        data.add(ChartDataPoint(
          x: k.toDouble(),
          value: value,
        ));
      }
    } else {
      // 如果没有实际数据，生成模拟数据
      for (int i = 0; i < 20; i++) {
        data.add(ChartDataPoint(
          x: i.toDouble(),
          value: _getSimulatedValue(i),
        ));
      }
    }
    
    return data;
  }
  
  double _getSimulatedValue(int index) {
    switch (widget.selectedVariable) {
      case MeteorologyVariable.temperature:
        return 25.0 - index * 0.5 + Random().nextDouble() * 2;
      case MeteorologyVariable.pressure:
        return 1013.0 - index * 10 + Random().nextDouble() * 5;
      case MeteorologyVariable.humidity:
        return 60.0 + Random().nextDouble() * 30;
      case MeteorologyVariable.uWind:
        return 5.0 + Random().nextDouble() * 10;
      case MeteorologyVariable.vWind:
        return 2.0 + Random().nextDouble() * 5;
      case MeteorologyVariable.wWind:
        return Random().nextDouble() * 2 - 1;
      case MeteorologyVariable.precipitation:
        return Random().nextDouble() * 5;
      default:
        return Random().nextDouble() * 100;
    }
  }
  
  String _getVariableDisplayName(MeteorologyVariable variable) {
    switch (variable) {
      case MeteorologyVariable.temperature:
        return '温度';
      case MeteorologyVariable.pressure:
        return '气压';
      case MeteorologyVariable.qvapor:
        return '水汽';
      case MeteorologyVariable.uWind:
        return '东西风';
      case MeteorologyVariable.vWind:
        return '南北风';
      case MeteorologyVariable.wWind:
        return '垂直风';
      case MeteorologyVariable.precipitation:
        return '降水';
      case MeteorologyVariable.cloud:
        return '云量';
      case MeteorologyVariable.humidity:
        return '湿度';
    }
  }
}

/// 分析结果
class AnalysisResult {
  final AnalysisType type;
  final String title;
  final String description;
  final AnalysisStatus status;
  final String? details;
  final List<String> recommendations;
  
  AnalysisResult({
    required this.type,
    required this.title,
    required this.description,
    required this.status,
    this.details,
    this.recommendations = const [],
  });
}

/// 分析类型
enum AnalysisType {
  dataQuality,
  numericalStability,
  physicalConsistency,
}

/// 分析状态
enum AnalysisStatus {
  success,
  warning,
  error,
}