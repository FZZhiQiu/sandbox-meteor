import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/meteorology_state.dart';
import '../../core/app_config.dart';

/// 增强控制面板 - 支持响应式布局和动画效果
class ControlPanel extends StatefulWidget {
  final MeteorologyVariable selectedVariable;
  final double scaleFactor;
  final bool isSimulating;
  final ValueChanged<MeteorologyVariable> onVariableChanged;
  final ValueChanged<double> onScaleChanged;
  final VoidCallback onStartSimulation;
  final VoidCallback onStopSimulation;
  final VoidCallback onReset;
  
  const ControlPanel({
    super.key,
    required this.selectedVariable,
    required this.scaleFactor,
    required this.isSimulating,
    required this.onVariableChanged,
    required this.onScaleChanged,
    required this.onStartSimulation,
    required this.onStopSimulation,
    required this.onReset,
  });
  
  @override
  State<ControlPanel> createState() => _ControlPanelState();
}

class _ControlPanelState extends State<ControlPanel> 
    with TickerProviderStateMixin, SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _scaleAnimationController;
  late Animation<double> _scaleAnimation;
  
  bool _isExpanded = false;
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation.easeInOut(_animationController),
    );
    
    _scaleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation.elasticOut(_scaleAnimationController),
    );
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _scaleAnimationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            padding: EdgeInsets.all(_getResponsivePadding(context)),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 0.5,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题栏
                _buildTitleBar(context),
                
                const SizedBox(height: 16),
                
                // 主要控制区域
                _isExpanded ? _buildExpandedControls(context) : _buildCompactControls(context),
                
                // 展开/收起按钮
                _buildExpandButton(context),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildVariableSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '显示变量',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: MeteorologyVariable.values.map((variable) {
            final isSelected = selectedVariable == variable;
            return FilterChip(
              label: Text(_getVariableDisplayName(variable)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onVariableChanged(variable);
                }
              },
              backgroundColor: Colors.white,
              selectedColor: Colors.blue.shade100,
              checkmarkColor: Colors.blue.shade800,
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildSimulationControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          '模拟控制',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isSimulating) ...[
              ElevatedButton.icon(
                onPressed: onStartSimulation,
                icon: const Icon(Icons.play_arrow),
                label: const Text('开始'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: onStopSimulation,
                icon: const Icon(Icons.stop),
                label: const Text('停止'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.refresh),
              label: const Text('重置'),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildScaleControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '缩放比例',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${scaleFactor.toStringAsFixed(1)}x',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: scaleFactor > 0.5 
                  ? () => onScaleChanged(scaleFactor - 0.1)
                  : null,
              icon: const Icon(Icons.zoom_out),
              tooltip: '缩小',
            ),
            Expanded(
              child: Slider(
                value: scaleFactor,
                min: 0.5,
                max: 3.0,
                divisions: 25,
                onChanged: onScaleChanged,
              ),
            ),
            IconButton(
              onPressed: scaleFactor < 3.0
                  ? () => onScaleChanged(scaleFactor + 0.1)
                  : null,
              icon: const Icon(Icons.zoom_in),
              tooltip: '放大',
            ),
          ],
        ),
      ],
    );
  }
  
  /// 响应式内边距
  double _getResponsivePadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200) {
      return 24.0; // 桌面
    } else if (screenWidth > 800) {
      return 20.0; // 平板
    } else if (screenWidth > 600) {
      return 16.0; // 大手机
    } else {
      return 12.0; // 小手机
    }
  }
  
  /// 构建标题栏
  Widget _buildTitleBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '控制面板',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        
        // 快捷操作按钮
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildQuickActionButton(
              icon: Icons.save,
              tooltip: '保存状态',
              onPressed: () => _showSaveDialog(context),
            ),
            const SizedBox(width: 8),
            _buildQuickActionButton(
              icon: Icons.settings,
              tooltip: '设置',
              onPressed: () => _showSettingsDialog(context),
            ),
          ],
        ),
      ],
    );
  }
  
  /// 构建紧凑模式控制
  Widget _buildCompactControls(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildVariableSelector()),
            const SizedBox(width: 16),
            _buildSimulationControls(),
          ],
        ),
        const SizedBox(height: 16),
        _buildScaleControls(),
      ],
    );
  }
  
  /// 构建展开模式控制
  Widget _buildExpandedControls(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 变量选择区域
        _buildExpandedVariableSelector(context),
        
        const SizedBox(height: 20),
        
        // 模拟控制区域
        _buildExpandedSimulationControls(context),
        
        const SizedBox(height: 20),
        
        // 高级控制区域
        _buildAdvancedControls(context),
        
        const SizedBox(height: 16),
        
        // 缩放控制区域
        _buildScaleControls(),
      ],
    );
  }
  
  /// 构建展开的变量选择器
  Widget _buildExpandedVariableSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.tune,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              '显示变量',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8.0,
          runSpacing: 6.0,
          children: MeteorologyVariable.values.map((variable) {
            final isSelected = widget.selectedVariable == variable;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: _buildVariableChip(
                variable: variable,
                isSelected: isSelected,
                onTap: () => widget.onVariableChanged(variable),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  /// 构建展开的模拟控制
  Widget _buildExpandedSimulationControls(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              widget.isSimulating ? Icons.pause_circle : Icons.play_circle,
              size: 20,
              color: widget.isSimulating ? Colors.orange : Colors.green,
            ),
            const SizedBox(width: 8),
            Text(
              '模拟控制',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _buildEnhancedControlButton(
                icon: widget.isSimulating ? Icons.pause : Icons.play_arrow,
                label: widget.isSimulating ? '暂停' : '开始',
                color: widget.isSimulating ? Colors.orange : Colors.green,
                onPressed: widget.isSimulating 
                    ? widget.onStopSimulation 
                    : widget.onStartSimulation,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildEnhancedControlButton(
                icon: Icons.refresh,
                label: '重置',
                color: Colors.blue,
                onPressed: widget.onReset,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildEnhancedControlButton(
                icon: Icons.save,
                label: '保存',
                color: Colors.purple,
                onPressed: () => _showSaveDialog(context),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  /// 构建高级控制区域
  Widget _buildAdvancedControls(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.tune,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              '高级选项',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        Wrap(
          spacing: 8.0,
          runSpacing: 6.0,
          children: [
            _buildAdvancedOption(
              icon: Icons.speed,
              label: '速度',
              value: '${widget.scaleFactor.toStringAsFixed(1)}x',
              onTap: () => _showSpeedDialog(context),
            ),
            _buildAdvancedOption(
              icon: Icons.grid_on,
              label: '网格',
              value: '${AppConfig.gridNX}×${AppConfig.gridNY}',
              onTap: () => _showGridDialog(context),
            ),
            _buildAdvancedOption(
              icon: Icons.timer,
              label: '时间步长',
              value: '${AppConfig.timeStep}s',
              onTap: () => _showTimeStepDialog(context),
            ),
          ],
        ),
      ],
    );
  }
  
  /// 构建变量选择芯片
  Widget _buildVariableChip({
    required MeteorologyVariable variable,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getVariableIcon(variable),
              size: 16,
              color: isSelected 
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            Text(
              _getVariableDisplayName(variable),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSelected 
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 构建增强控制按钮
  Widget _buildEnhancedControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              onPressed();
            },
            icon: Icon(icon, size: 18),
            label: Text(label),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        );
      },
    );
  }
  
  /// 构建高级选项
  Widget _buildAdvancedOption({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// 构建快捷操作按钮
  Widget _buildQuickActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        style: IconButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          shape: const CircleBorder(),
        ),
      ),
    );
  }
  
  /// 构建展开/收起按钮
  Widget _buildExpandButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
        HapticFeedback.lightImpact();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isExpanded ? '收起控制面板' : '展开高级选项',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 20,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 获取变量图标
  IconData _getVariableIcon(MeteorologyVariable variable) {
    switch (variable) {
      case MeteorologyVariable.temperature:
        return Icons.thermostat;
      case MeteorologyVariable.pressure:
        return Icons.speed;
      case MeteorologyVariable.qvapor:
        return Icons.water_drop;
      case MeteorologyVariable.uWind:
        return Icons.east;
      case MeteorologyVariable.vWind:
        return Icons.south;
      case MeteorologyVariable.wWind:
        return Icons.vertical_align_center;
      case MeteorologyVariable.precipitation:
        return Icons.grain;
      case MeteorologyVariable.cloud:
        return Icons.cloud;
      case MeteorologyVariable.humidity:
        return Icons.water;
    }
  }
  
  /// 显示保存对话框
  void _showSaveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('保存状态'),
        content: const Text('是否保存当前模拟状态？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 实际保存逻辑
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('状态已保存')),
              );
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
  
  /// 显示设置对话框
  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置'),
        content: const Text('设置功能开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
  
  /// 显示速度对话框
  void _showSpeedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('模拟速度'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('当前速度: ${widget.scaleFactor.toStringAsFixed(1)}x'),
            const SizedBox(height: 16),
            Slider(
              value: widget.scaleFactor,
              min: 0.1,
              max: 10.0,
              divisions: 99,
              onChanged: widget.onScaleChanged,
            ),
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
  
  /// 显示网格对话框
  void _showGridDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('网格设置'),
        content: const Text('网格设置功能开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
  
  /// 显示时间步长对话框
  void _showTimeStepDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('时间步长'),
        content: const Text('时间步长设置功能开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
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