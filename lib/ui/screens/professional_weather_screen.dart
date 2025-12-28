import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/compact_weather_system.dart';
import '../widgets/professional_weather_widgets.dart';
import '../widgets/advanced_visualization.dart';

/// 专业气象屏幕 - 600MB项目的专业UI界面
class ProfessionalWeatherScreen extends StatefulWidget {
  const ProfessionalWeatherScreen({Key? key}) : super(key: key);

  @override
  _ProfessionalWeatherScreenState createState() => _ProfessionalWeatherScreenState();
}

class _ProfessionalWeatherScreenState extends State<ProfessionalWeatherScreen>
    with TickerProviderStateMixin {
  
  // 核心系统
  late CompactWeatherSystem _weatherSystem;
  
  // 动画控制器
  late AnimationController _mainAnimationController;
  late AnimationController _radarAnimationController;
  late AnimationController _dataAnimationController;
  
  // UI状态
  int _selectedTabIndex = 0;
  bool _isSimulationRunning = false;
  bool _isDataLoading = false;
  String _selectedViewMode = 'radar';
  
  // 数据状态
  Map<String, dynamic> _currentWeatherData = {};
  Map<String, dynamic> _simulationResults = {};
  List<String> _availableLayers = [];
  
  // 性能监控
  Map<String, dynamic> _performanceMetrics = {};
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeWeatherSystem();
    _loadInitialData();
  }
  
  void _initializeAnimations() {
    // 主动画控制器
    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // 雷达动画控制器
    _radarAnimationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    
    // 数据动画控制器
    _dataAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }
  
  void _initializeWeatherSystem() async {
    _weatherSystem = CompactWeatherSystem();
    await _weatherSystem.initialize();
    
    // 获取初始状态
    var status = _weatherSystem.getProjectStatus();
    setState(() {
      _performanceMetrics = {
        'project_size_mb': status['current_size_mb'],
        'memory_efficiency': status['memory_efficiency'],
        'grid_dimensions': status['grid_dimensions'],
      };
    });
  }
  
  void _loadInitialData() async {
    setState(() {
      _isDataLoading = true;
    });
    
    // 模拟数据加载
    await Future.delayed(const Duration(milliseconds: 1500));
    
    setState(() {
      _isDataLoading = false;
      _availableLayers = [
        'temperature', 'humidity', 'pressure', 'wind',
        'cloud_cover', 'precipitation', 'visibility'
      ];
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: SafeArea(
        child: Column(
          children: [
            // 专业顶部栏
            _buildProfessionalHeader(),
            
            // 主要内容区域
            Expanded(
              child: Row(
                children: [
                  // 左侧控制面板
                  _buildLeftControlPanel(),
                  
                  // 中央显示区域
                  Expanded(
                    flex: 3,
                    child: _buildCentralDisplayArea(),
                  ),
                  
                  // 右侧信息面板
                  _buildRightInfoPanel(),
                ],
              ),
            ),
            
            // 底部状态栏
            _buildProfessionalStatusBar(),
          ],
        ),
      ),
    );
  }
  
  /// 构建专业顶部栏
  Widget _buildProfessionalHeader() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A237E),
            const Color(0xFF283593),
            const Color(0xFF3949AB),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo和标题
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Row(
                children: [
                  // 专业Logo
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.cyan[400]!, Colors.blue[600]!],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyan.withOpacity(0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.cloud,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  
                  const SizedBox(width: 15),
                  
                  // 系统标题
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '气象沙盘模拟系统',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        'Professional Meteorological Sandbox',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // 中央控制区
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildHeaderButton(
                  icon: Icons.play_arrow,
                  label: '运行模拟',
                  isActive: _isSimulationRunning,
                  onTap: _toggleSimulation,
                ),
                const SizedBox(width: 10),
                _buildHeaderButton(
                  icon: Icons.refresh,
                  label: '刷新数据',
                  isActive: false,
                  onTap: _refreshData,
                ),
                const SizedBox(width: 10),
                _buildHeaderButton(
                  icon: Icons.settings,
                  label: '设置',
                  isActive: false,
                  onTap: _openSettings,
                ),
              ],
            ),
          ),
          
          // 系统状态
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // 内存指示器
                  _buildMemoryIndicator(),
                  
                  const SizedBox(width: 15),
                  
                  // 状态指示器
                  _buildStatusIndicator(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建顶部按钮
  Widget _buildHeaderButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive 
              ? Colors.white.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive 
                ? Colors.white.withOpacity(0.5)
                : Colors.white.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 构建内存指示器
  Widget _buildMemoryIndicator() {
    double memoryUsage = _performanceMetrics['project_size_mb'] ?? 0.0;
    double memoryPercent = (memoryUsage / 600.0) * 100;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${memoryUsage.toStringAsFixed(1)}MB',
          style: TextStyle(
            color: memoryPercent > 80 ? Colors.red[400] : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '/ 600MB',
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
  
  /// 构建状态指示器
  Widget _buildStatusIndicator() {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isSimulationRunning ? Colors.green[400] : Colors.orange[400],
            boxShadow: [
              BoxShadow(
                color: (_isSimulationRunning ? Colors.green : Colors.orange).withOpacity(0.5),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          _isSimulationRunning ? '运行中' : '就绪',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  /// 构建左侧控制面板
  Widget _buildLeftControlPanel() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0D47A1).withOpacity(0.9),
            const Color(0xFF1565C0).withOpacity(0.9),
          ],
        ),
        border: Border(
          right: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // 视图模式选择
          _buildViewModeSelector(),
          
          const Divider(color: Colors.white24, height: 1),
          
          // 图层控制
          _buildLayerControl(),
          
          const Divider(color: Colors.white24, height: 1),
          
          // 时间控制
          _buildTimeControl(),
          
          const Divider(color: Colors.white24, height: 1),
          
          // 参数调节
          _buildParameterControl(),
          
          const Spacer(),
          
          // 快捷操作
          _buildQuickActions(),
        ],
      ),
    );
  }
  
  /// 构建视图模式选择器
  Widget _buildViewModeSelector() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '视图模式',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // 视图选项
          ...['radar', 'satellite', 'temperature', 'wind', '3d', 'particles', 'isolines', 'clouds', 'lightning'].map((mode) {
            return _buildViewModeOption(mode);
          }).toList(),
        ],
      ),
    );
  }
  
  /// 构建视图模式选项
  Widget _buildViewModeOption(String mode) {
    bool isSelected = _selectedViewMode == mode;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedViewMode = mode;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.white.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? Colors.cyan.withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _getViewModeIcon(mode),
              color: isSelected ? Colors.cyan[300] : Colors.white70,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              _getViewModeName(mode),
              style: TextStyle(
                color: isSelected ? Colors.cyan[300] : Colors.white,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Colors.cyan[300],
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
  
  /// 获取视图模式图标
  IconData _getViewModeIcon(String mode) {
    switch (mode) {
      case 'radar': return Icons.radar;
      case 'satellite': return Icons.satellite;
      case 'temperature': return Icons.thermostat;
      case 'wind': return Icons.air;
      default: return Icons.dashboard;
    }
  }
  
  /// 获取视图模式名称
  String _getViewModeName(String mode) {
    switch (mode) {
      case 'radar': return '雷达视图';
      case 'satellite': return '卫星视图';
      case 'temperature': return '温度视图';
      case 'wind': return '风场视图';
      case '3d': return '3D视图';
      case 'particles': return '粒子系统';
      case 'isolines': return '等值线';
      case 'clouds': return '3D云图';
      case 'lightning': return '雷电追踪';
      default: return '未知视图';
    }
  }
  
  /// 构建图层控制
  Widget _buildLayerControl() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '图层控制',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // 图层列表
          ..._availableLayers.map((layer) {
            return _buildLayerToggle(layer);
          }).toList(),
        ],
      ),
    );
  }
  
  /// 构建图层开关
  Widget _buildLayerToggle(String layer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // 开关按钮
          GestureDetector(
            onTap: () {
              // 切换图层显示状态
            },
            child: Container(
              width: 40,
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white.withOpacity(0.2),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.cyan[400],
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 图层名称
          Expanded(
            child: Text(
              _getLayerDisplayName(layer),
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
          
          // 透明度控制
          Icon(
            Icons.tune,
            color: Colors.white54,
            size: 16,
          ),
        ],
      ),
    );
  }
  
  /// 获取图层显示名称
  String _getLayerDisplayName(String layer) {
    switch (layer) {
      case 'temperature': return '温度';
      case 'humidity': return '湿度';
      case 'pressure': return '气压';
      case 'wind': return '风场';
      case 'cloud_cover': return '云量';
      case 'precipitation': return '降水';
      case 'visibility': return '能见度';
      default: return layer;
    }
  }
  
  /// 构建时间控制
  Widget _buildTimeControl() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '时间控制',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // 当前时间显示
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  '模拟时间',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '2024-12-28 14:30',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // 时间控制按钮
          Row(
            children: [
              Expanded(
                child: _buildTimeControlButton(
                  icon: Icons.fast_rewind,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTimeControlButton(
                  icon: Icons.pause,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTimeControlButton(
                  icon: Icons.play_arrow,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTimeControlButton(
                  icon: Icons.fast_forward,
                  onTap: () {},
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 时间轴
          Container(
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: Colors.white.withOpacity(0.2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    colors: [Colors.cyan[400]!, Colors.blue[600]!],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建时间控制按钮
  Widget _buildTimeControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
  
  /// 构建参数调节
  Widget _buildParameterControl() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '参数调节',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // 模拟速度
          _buildParameterSlider(
            label: '模拟速度',
            value: 1.0,
            min: 0.1,
            max: 5.0,
            unit: 'x',
          ),
          
          const SizedBox(height: 16),
          
          // 网格分辨率
          _buildParameterSlider(
            label: '网格分辨率',
            value: 40,
            min: 20,
            max: 80,
            unit: 'px',
          ),
          
          const SizedBox(height: 16),
          
          // 数据精度
          _buildParameterSlider(
            label: '数据精度',
            value: 85,
            min: 50,
            max: 100,
            unit: '%',
          ),
        ],
      ),
    );
  }
  
  /// 构建参数滑块
  Widget _buildParameterSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String unit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
            Text(
              '${value.toStringAsFixed(1)}$unit',
              style: TextStyle(
                color: Colors.cyan[300],
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: Colors.white.withOpacity(0.2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (value - min) / (max - min),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(
                  colors: [Colors.cyan[400]!, Colors.blue[600]!],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  /// 构建快捷操作
  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '快捷操作',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // 操作按钮
          _buildQuickActionButton(
            icon: Icons.save,
            label: '保存场景',
            color: Colors.green[400],
          ),
          
          const SizedBox(height: 8),
          
          _buildQuickActionButton(
            icon: Icons.share,
            label: '分享结果',
            color: Colors.blue[400],
          ),
          
          const SizedBox(width: 8),
          
          _buildQuickActionButton(
            icon: Icons.download,
            label: '导出数据',
            color: Colors.orange[400],
          ),
        ],
      ),
    );
  }
  
  /// 构建快捷操作按钮
  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color? color,
  }) {
    return GestureDetector(
      onTap: () {
        // 执行快捷操作
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color?.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color?.withOpacity(0.5) ?? Colors.white.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color ?? Colors.white,
              size: 16,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: color ?? Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 构建中央显示区域
  Widget _buildCentralDisplayArea() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E27),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          // 顶部工具栏
          _buildCentralToolbar(),
          
          // 主显示区域
          Expanded(
            child: _buildMainDisplay(),
          ),
          
          // 底部信息栏
          _buildCentralInfoBar(),
        ],
      ),
    );
  }
  
  /// 构建中央工具栏
  Widget _buildCentralToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          // 视图标题
          Expanded(
            child: Text(
              '${_getViewModeName(_selectedViewMode)} - 实时显示',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // 工具按钮
          Row(
            children: [
              _buildToolbarButton(Icons.zoom_in, '放大'),
              _buildToolbarButton(Icons.zoom_out, '缩小'),
              _buildToolbarButton(Icons.center_focus_strong, '居中'),
              _buildToolbarButton(Icons.fullscreen, '全屏'),
            ],
          ),
        ],
      ),
    );
  }
  
  /// 构建工具栏按钮
  Widget _buildToolbarButton(IconData icon, String tooltip) {
    return GestureDetector(
      onTap: () {
        // 执行工具操作
      },
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Colors.white70,
          size: 18,
        ),
      ),
    );
  }
  
  /// 构建主显示区域
  Widget _buildMainDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: _isDataLoading
          ? _buildLoadingDisplay()
          : _buildAdvancedWeatherDisplay(),
    );
  }
  
  /// 构建加载显示
  Widget _buildLoadingDisplay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 加载动画
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.cyan[400]!,
                width: 3,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan[400]!),
                strokeWidth: 3,
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          Text(
            '正在加载气象数据...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            '请稍候',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  /// 生成雷达扫描数据
  List<RadarScan> _generateRadarScanData() {
    List<RadarScan> scans = [];
    
    for (int i = 0; i < 50; i++) {
      double angle = (i / 50) * 2 * math.pi;
      double distance = 50 + math.Random().nextDouble() * 150;
      double x = distance * math.cos(angle);
      double y = distance * math.sin(angle);
      double reflectivity = 20 + math.Random().nextDouble() * 60;
      double velocity = -30 + math.Random().nextDouble() * 60;
      double elevation = 0.5 + math.Random().nextDouble() * 4.5;
      
      scans.add(RadarScan(
        x: x,
        y: y,
        reflectivity: reflectivity,
        velocity: velocity,
        elevation: elevation,
        vsync: this,
      ));
    }
    
    return scans;
  }
  
  /// 生成热力图数据
  List<HeatmapData> _generateHeatmapData() {
    List<HeatmapData> data = [];
    
    for (int i = 0; i < 100; i++) {
      double x = math.Random().nextDouble() * 600;
      double y = math.Random().nextDouble() * 400;
      double value = 15 + math.Random().nextDouble() * 25; // 15-40°C
      double size = 10 + math.Random().nextDouble() * 20;
      
      data.add(HeatmapData(
        x: x,
        y: y,
        value: value,
        size: size,
      ));
    }
    
    return data;
  }
  
  /// 生成风场矢量
  List<WindVector> _generateWindVectors() {
    List<WindVector> vectors = [];
    
    for (int i = 0; i < 20; i++) {
      for (int j = 0; j < 15; j++) {
        double x = i * 30 + 15;
        double y = j * 30 + 15;
        double u = -10 + math.Random().nextDouble() * 20;
        double v = -10 + math.Random().nextDouble() * 20;
        
        vectors.add(WindVector(
          x: x,
          y: y,
          u: u,
          v: v,
        ));
      }
    }
    
    return vectors;
  }
  
  /// 生成等值线数据
  List<IsolineData> _generateIsolineData() {
    List<IsolineData> isolines = [];
    
    // 生成温度等值线
    List<double> temperatureValues = [15, 20, 25, 30, 35];
    
    for (double value in temperatureValues) {
      List<Offset> points = [];
      
      // 生成简单的椭圆等值线
      for (double angle = 0; angle < 2 * math.pi; angle += 0.1) {
        double rx = 100 + value * 5;
        double ry = 80 + value * 4;
        double x = 300 + rx * math.cos(angle);
        double y = 200 + ry * math.sin(angle);
        points.add(Offset(x, y));
      }
      
      isolines.add(IsolineData(
        value: value,
        points: points,
        labelPosition: Offset(300 + value * 5, 200),
      ));
    }
    
    return isolines;
  }
  
  /// 生成云层数据
  List<CloudData> _generateCloudData() {
    List<CloudData> clouds = [];
    
    for (int i = 0; i < 15; i++) {
      clouds.add(CloudData(
        x: -200 + math.Random().nextDouble() * 400,
        y: -150 + math.Random().nextDouble() * 300,
        z: 50 + math.Random().nextDouble() * 200,
        size: 30 + math.Random().nextDouble() * 60,
        opacity: 0.4 + math.Random().nextDouble() * 0.5,
      ));
    }
    
    return clouds;
  }
  
  /// 生成雷电数据
  List<LightningStrike> _generateLightningStrikes() {
    List<LightningStrike> strikes = [];
    
    for (int i = 0; i < 3; i++) {
      List<Offset> points = [];
      double startX = 200 + math.Random().nextDouble() * 200;
      double startY = 50;
      
      // 生成主闪电路径
      double x = startX;
      double y = startY;
      
      for (int j = 0; j < 10; j++) {
        x += (math.Random().nextDouble() - 0.5) * 40;
        y += 35;
        points.add(Offset(x, y));
      }
      
      // 生成分支
      List<LightningBranch> branches = [];
      for (int k = 0; k < 2; k++) {
        List<Offset> branchPoints = [];
        int branchIndex = 3 + math.Random().nextInt(5);
        double branchX = points[branchIndex].dx;
        double branchY = points[branchIndex].dy;
        
        for (int l = 0; l < 5; l++) {
          branchX += (math.Random().nextDouble() - 0.5) * 30;
          branchY += 20;
          branchPoints.add(Offset(branchX, branchY));
        }
        
        branches.add(LightningBranch(
          points: branchPoints,
          vsync: this,
        ));
      }
      
      strikes.add(LightningStrike(
        points: points,
        branches: branches,
        vsync: this,
      ));
    }
    
    return strikes;
  }
  
  /// 构建高级天气显示
  Widget _buildAdvancedWeatherDisplay() {
    switch (_selectedViewMode) {
      case 'radar':
        return _buildAdvancedRadarDisplay();
      case 'satellite':
        return _build3DWeatherVisualization();
      case 'temperature':
        return _buildTemperatureHeatmap();
      case 'wind':
        return _buildWindFieldVisualization();
      case '3d':
        return _build3DWeatherVisualization();
      case 'particles':
        return _buildParticleSystem();
      case 'isolines':
        return _buildIsolineMap();
      case 'clouds':
        return _build3DCloudMap();
      case 'lightning':
        return _buildLightningTracker();
      default:
        return _buildAdvancedRadarDisplay();
    }
  }
  
  /// 构建高级雷达显示
  Widget _buildAdvancedRadarDisplay() {
    // 生成雷达扫描数据
    List<RadarScan> scanData = _generateRadarScanData();
    
    return AdvancedVisualization.buildAdvancedRadar(
      scanData: scanData,
      size: 400,
      enableDoppler: true,
      enableElevation: true,
    );
  }
  
  /// 构建3D天气可视化
  Widget _build3DWeatherVisualization() {
    return AdvancedVisualization.build3DWeatherVisualization(
      weatherData: _currentWeatherData,
      width: 600,
      height: 400,
      enableRotation: true,
      enableZoom: true,
    );
  }
  
  /// 构建温度热力图
  Widget _buildTemperatureHeatmap() {
    List<HeatmapData> heatmapData = _generateHeatmapData();
    
    return AdvancedVisualization.buildHeatmap(
      data: heatmapData,
      width: 600,
      height: 400,
      gradient: LinearGradient(
        colors: [
          Colors.blue[300]!,
          Colors.green[300]!,
          Colors.yellow[300]!,
          Colors.orange[300]!,
          Colors.red[300]!,
        ],
      ),
    );
  }
  
  /// 构建风场可视化
  Widget _buildWindFieldVisualization() {
    List<WindVector> windVectors = _generateWindVectors();
    
    return AdvancedVisualization.buildWindField(
      windVectors: windVectors,
      width: 600,
      height: 400,
      type: WindFieldType.streamline,
    );
  }
  
  /// 构建粒子系统
  Widget _buildParticleSystem() {
    ParticleConfig config = ParticleConfig(
      particleCount: 200,
      windSpeed: 2.0,
      windForce: 0.1,
      gravity: 0.05,
      minSize: 2.0,
      maxSize: 6.0,
      minOpacity: 0.3,
      maxOpacity: 0.8,
      maxLife: 100,
      colors: [
        Colors.white,
        Colors.blue[200]!,
        Colors.cyan[200]!,
        Colors.lightBlue[200]!,
      ],
    );
    
    return AdvancedVisualization.buildWeatherParticleSystem(
      config: config,
      width: 600,
      height: 400,
    );
  }
  
  /// 构建等值线图
  Widget _buildIsolineMap() {
    List<IsolineData> isolines = _generateIsolineData();
    
    return AdvancedVisualization.buildIsolineMap(
      isolines: isolines,
      width: 600,
      height: 400,
      type: IsolineType.temperature,
    );
  }
  
  /// 构建3D云图
  Widget _build3DCloudMap() {
    List<CloudData> clouds = _generateCloudData();
    
    return AdvancedVisualization.build3DCloudMap(
      clouds: clouds,
      width: 600,
      height: 400,
      cameraAngle: 30.0,
      cameraHeight: 1000.0,
    );
  }
  
  /// 构建雷电追踪
  Widget _buildLightningTracker() {
    List<LightningStrike> strikes = _generateLightningStrikes();
    
    return AdvancedVisualization.buildLightningTracker(
      strikes: strikes,
      width: 600,
      height: 400,
    );
  }
  
  /// 构建卫星显示
  Widget _buildSatelliteDisplay() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            Colors.blue[900]!.withOpacity(0.3),
            Colors.blue[700]!.withOpacity(0.2),
          ],
        ),
      ),
      child: Center(
        child: Text(
          '卫星视图',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  /// 构建温度显示
  Widget _buildTemperatureDisplay() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            Colors.red[900]!.withOpacity(0.3),
            Colors.orange[700]!.withOpacity(0.2),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.thermostat,
              color: Colors.orange[400],
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              '25.3°C',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '平均温度',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 构建风场显示
  Widget _buildWindDisplay() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            Colors.green[900]!.withOpacity(0.3),
            Colors.teal[700]!.withOpacity(0.2),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.air,
              color: Colors.teal[400],
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              '12.5 m/s',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '西北风 5级',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 构建默认显示
  Widget _buildDefaultDisplay() {
    return Center(
      child: Text(
        '选择视图模式',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  /// 构建中央信息栏
  Widget _buildCentralInfoBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          // 坐标信息
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.cyan[400],
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '经度: 116.407°  纬度: 39.904°',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // 数据信息
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.data_usage,
                  color: Colors.green[400],
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '数据点: 19,200',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // 更新时间
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.update,
                  color: Colors.orange[400],
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '更新: 14:30:15',
                  style: TextStyle(
                    color: Colors.white70,
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
  
  /// 构建右侧信息面板
  Widget _buildRightInfoPanel() {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF263238).withOpacity(0.9),
            const Color(0xFF37474F).withOpacity(0.9),
          ],
        ),
        border: Border(
          left: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // 系统性能监控
          _buildPerformanceMonitor(),
          
          const Divider(color: Colors.white24, height: 1),
          
          // 实时数据面板
          _buildRealtimeDataPanel(),
          
          const Divider(color: Colors.white24, height: 1),
          
          // 预报信息
          _buildForecastPanel(),
          
          const Divider(color: Colors.white24, height: 1),
          
          // 警报信息
          _buildAlertPanel(),
          
          const Spacer(),
          
          // 系统日志
          _buildSystemLog(),
        ],
      ),
    );
  }
  
  /// 构建性能监控
  Widget _buildPerformanceMonitor() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '系统性能',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // 性能指标
          _buildPerformanceMetric('CPU使用率', '45%', Colors.green[400]),
          _buildPerformanceMetric('内存使用', '${_performanceMetrics['project_size_mb']?.toStringAsFixed(1) ?? '0'}MB', Colors.blue[400]),
          _buildPerformanceMetric('计算速度', '50ms/步', Colors.orange[400]),
          _buildPerformanceMetric('渲染帧率', '30 FPS', Colors.purple[400]),
        ],
      ),
    );
  }
  
  /// 构建性能指标
  Widget _buildPerformanceMetric(String label, String value, Color? color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建实时数据面板
  Widget _buildRealtimeDataPanel() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '实时数据',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // 数据卡片
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildDataRow('温度', '25.3°C', '↑ 0.5°C'),
                _buildDataRow('湿度', '65%', '↓ 2%'),
                _buildDataRow('气压', '1013.2 hPa', '→ 0.0'),
                _buildDataRow('风速', '12.5 m/s', '↑ 1.2 m/s'),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建数据行
  Widget _buildDataRow(String label, String value, String trend) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                trend,
                style: TextStyle(
                  color: trend.startsWith('↑') ? Colors.red[400] :
                         trend.startsWith('↓') ? Colors.blue[400] : Colors.green[400],
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// 构建预报面板
  Widget _buildForecastPanel() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '天气预报',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // 预报卡片
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.wb_sunny,
                      color: Colors.yellow[400],
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '今天',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '晴 28°/18°',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.cloud,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '明天',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '多云 26°/17°',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建警报面板
  Widget _buildAlertPanel() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '预警信息',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // 预警卡片
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.orange.withOpacity(0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning,
                  color: Colors.orange[400],
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '大风蓝色预警',
                        style: TextStyle(
                          color: Colors.orange[300],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '预计今日有6-7级大风',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建系统日志
  Widget _buildSystemLog() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '系统日志',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // 日志内容
          Container(
            height: 120,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLogEntry('14:30:15', 'INFO', '系统初始化完成'),
                  _buildLogEntry('14:30:12', 'INFO', '加载气象数据'),
                  _buildLogEntry('14:30:08', 'WARN', '内存使用 580MB'),
                  _buildLogEntry('14:30:05', 'INFO', '启动模拟引擎'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建日志条目
  Widget _buildLogEntry(String time, String level, String message) {
    Color levelColor = level == 'INFO' ? Colors.green[400] :
                       level == 'WARN' ? Colors.orange[400] : Colors.red[400];
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            time,
            style: TextStyle(
              color: Colors.white60,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 8),
          Text(
            level,
            style: TextStyle(
              color: levelColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建专业状态栏
  Widget _buildProfessionalStatusBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A237E),
            const Color(0xFF283593),
          ],
        ),
      ),
      child: Row(
        children: [
          // 左侧状态信息
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.cyan[300],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '气象沙盘模拟系统 v1.0.0 - 600MB专业版',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 中央状态
          Expanded(
            flex: 2,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud,
                    color: Colors.white70,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '数据源: 本地模拟',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 右侧时间信息
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.access_time,
                    color: Colors.white70,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateTime.now().toString().substring(11, 19),
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 切换模拟状态
  void _toggleSimulation() {
    setState(() {
      _isSimulationRunning = !_isSimulationRunning;
    });
    
    if (_isSimulationRunning) {
      _startSimulation();
    } else {
      _stopSimulation();
    }
  }
  
  /// 开始模拟
  void _startSimulation() async {
    print('🚀 启动专业气象模拟...');
    
    try {
      var results = await _weatherSystem.runCompactSimulation(
        durationHours: 24,
        timeStepMinutes: 15,
      );
      
      setState(() {
        _simulationResults = results;
      });
      
      print('✅ 模拟完成');
    } catch (e) {
      print('❌ 模拟失败: $e');
    }
  }
  
  /// 停止模拟
  void _stopSimulation() {
    print('⏸️ 停止模拟');
  }
  
  /// 刷新数据
  void _refreshData() {
    print('🔄 刷新数据');
    setState(() {
      _isDataLoading = true;
    });
    
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isDataLoading = false;
      });
    });
  }
  
  /// 打开设置
  void _openSettings() {
    print('⚙️ 打开设置');
  }
  
  @override
  void dispose() {
    _mainAnimationController.dispose();
    _radarAnimationController.dispose();
    _dataAnimationController.dispose();
    super.dispose();
  }
}

/// 专业雷达绘制器
class ProfessionalRadarPainter extends CustomPainter {
  final double animation;
  final Map<String, dynamic> data;
  
  ProfessionalRadarPainter({
    required this.animation,
    required this.data,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 20;
    
    // 背景渐变
    final backgroundPaint = Paint()
      ..shader = RadialGradient(
        center: center,
        radius: radius,
        colors: [
          const Color(0xFF1A237E).withOpacity(0.8),
          const Color(0xFF0D47A1).withOpacity(0.9),
        ],
      ).createShader(Rect.fromCircle(center: center, radius));
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);
    
    // 绘制雷达圆圈
    _drawRadarCircles(canvas, center, radius);
    
    // 绘制雷达扫描线
    _drawRadarScan(canvas, center, radius, animation);
    
    // 绘制雷达数据
    _drawRadarData(canvas, center, radius);
    
    // 绘制方位标记
    _drawRadarBearings(canvas, center, radius);
  }
  
  void _drawRadarCircles(Canvas canvas, Offset center, double radius) {
    final circlePaint = Paint()
      ..color = Colors.cyan.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    for (int i = 1; i <= 5; i++) {
      canvas.drawCircle(center, radius * i / 5, circlePaint);
    }
  }
  
  void _drawRadarScan(Canvas canvas, Offset center, double radius, double animation) {
    final scanPaint = Paint()
      ..shader = LinearGradient(
        begin: center,
        end: Offset(
          center.dx + radius * math.cos(animation * 2 * math.pi),
          center.dy + radius * math.sin(animation * 2 * math.pi),
        ),
        colors: [
          Colors.cyan.withOpacity(0.8),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius));
    
    canvas.drawCircle(center, radius, scanPaint);
  }
  
  void _drawRadarData(Canvas canvas, Offset center, double radius) {
    // 模拟雷达回波数据
    final dataPaint = Paint()
      ..color = Colors.green.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    
    // 绘制一些示例回波
    for (int i = 0; i < 5; i++) {
      final angle = (i * 72 + animation * 360) * math.pi / 180;
      final distance = radius * (0.3 + i * 0.1);
      final x = center.dx + distance * math.cos(angle);
      final y = center.dy + distance * math.sin(angle);
      
      canvas.drawCircle(Offset(x, y), 8, dataPaint);
    }
  }
  
  void _drawRadarBearings(Canvas canvas, Offset center, double radius) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    const bearings = ['N', 'E', 'S', 'W'];
    const angles = [0, 90, 180, 270];
    
    for (int i = 0; i < bearings.length; i++) {
      final angle = angles[i] * math.pi / 180;
      final x = center.dx + (radius + 15) * math.sin(angle);
      final y = center.dy - (radius + 15) * math.cos(angle);
      
      textPainter.text = TextSpan(
        text: bearings[i],
        style: TextStyle(
          color: Colors.white.withOpacity(0.8),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}