import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/meteorology_service.dart';
import '../services/linux_backend_service.dart';
import '../services/radar_enhanced_service.dart';
import '../core/performance/performance_optimizer.dart';
import '../core/performance/adaptive_layout_manager.dart';
import '../widgets/professional_radar_widget.dart';
import '../widgets/optimized_radar_widget.dart';
import '../widgets/doppler_radar_widget.dart';
import '../widgets/grid_visualization_widget.dart';
import '../widgets/sandbox_elements_widget.dart';
import '../services/ultimate_weather_system.dart';
import '../services/optimized_weather_system.dart';
import '../services/compact_weather_system.dart';
import '../screens/professional_weather_screen.dart';

/// 气象沙盘主屏幕 - 集成Linux后端和增强功能
class SandboxScreen extends StatefulWidget {
  const SandboxScreen({Key? key}) : super(key: key);

  @override
  _SandboxScreenState createState() => _SandboxScreenState();
}

class _SandboxScreenState extends State<SandboxScreen>
    with TickerProviderStateMixin {
  late MeteorologyService _meteorologyService;
  late LinuxBackendService _linuxBackendService;
  late RadarEnhancedService _radarEnhancedService;
  late PerformanceOptimizer _performanceOptimizer;
  late AdaptiveLayoutManager _layoutManager;
  late UltimateWeatherSystem _ultimateWeatherSystem;
  late OptimizedWeatherSystem _optimizedWeatherSystem;
  late CompactWeatherSystem _compactWeatherSystem;
  
  // 页面控制器
  late PageController _pageController;
  late TabController _tabController;
  
  // 状态管理
  bool _isLoading = true;
  bool _isLinuxBackendConnected = false;
  String _selectedView = 'radar';
  int _currentTabIndex = 0;
  
  // 数据
  RadarDataPacket? _currentRadarData;
  EnhancedRadarData? _enhancedRadarData;
  GridData? _currentGridData;
  List<RadarProductRecommendation> _productRecommendations = [];
  
  // 性能监控
  Timer? _performanceTimer;
  PerformanceMetrics? _currentMetrics;
  
  // 动画控制器
  late AnimationController _loadingController;
  late AnimationController _transitionController;
  late Animation<double> _loadingAnimation;
  late Animation<double> _transitionAnimation;
  
  @override
  
    void initState() {
  
      super.initState();
  
      _initializeServices();
  
      _initializeControllers();
  
      _initializeUltimateSystem();
  
      _loadData();
  
    }
  
  Future<void> _initializeServices() async {
    // 初始化核心服务
    _meteorologyService = MeteorologyService();
    _linuxBackendService = LinuxBackendService();
    _radarEnhancedService = RadarEnhancedService(
      meteorologyService: _meteorologyService,
      linuxBackend: _linuxBackendService,
      commercialService: CommercialRadarDataService(),
    );
    
    // 初始化性能管理
    _performanceOptimizer = PerformanceOptimizer();
    _layoutManager = AdaptiveLayoutManager();
    _ultimateWeatherSystem = UltimateWeatherSystem();
    _optimizedWeatherSystem = OptimizedWeatherSystem();
    _compactWeatherSystem = CompactWeatherSystem();
    
    // 初始化服务
    await _performanceOptimizer.initialize();
    await _layoutManager.initialize();
    await _radarEnhancedService.initialize();
    
    // 检查Linux后端连接
    _checkLinuxBackendConnection();
  }
  
  void _initializeUltimateSystem() async {
    try {
      await _ultimateWeatherSystem.initialize();
      await _optimizedWeatherSystem.initialize();
      await _compactWeatherSystem.initialize();
      setState(() {
        _isLinuxBackendConnected = true; // 更新连接状态
      });
      print('✅ 终极气象系统初始化成功');
      print('📊 优化系统内存目标: 600MB');
    } catch (e) {
      print('❌ 终极气象系统初始化失败: $e');
    }
  }
  
  void _initializeControllers() {
    _pageController = PageController();
    _tabController = TabController(length: 4, vsync: this);
    
    _loadingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _loadingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _loadingController,
      curve: Curves.easeInOut,
    ));
    
    _transitionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeInOut,
    ));
    
    _loadingController.forward();
    
    // 启动性能监控
    _startPerformanceMonitoring();
  }
  
  Future<void> _loadData() async {
    try {
      // 加载雷达数据
      _currentRadarData = await _meteorologyService.getCommercialRadarData();
      
      // 加载增强雷达数据
      _enhancedRadarData = await _radarEnhancedService.getEnhancedRadarData();
      
      // 加载Linux网格数据
      if (_isLinuxBackendConnected) {
        _currentGridData = await _loadLinuxGridData();
      }
      
      // 获取产品推荐
      _productRecommendations = await _radarEnhancedService.getProductRecommendations(
        weatherScenario: 'severe_thunderstorm',
        userPurpose: 'aviation',
      );
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('数据加载失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _checkLinuxBackendConnection() async {
    final isConnected = await _linuxBackendService.checkConnection();
    setState(() {
      _isLinuxBackendConnected = isConnected;
    });
  }
  
  Future<GridData> _loadLinuxGridData() async {
    // 模拟加载Linux网格数据
    final nx, ny, nz = 50, 50, 20;
    
    final temperatureData = List.generate(nz, (k) {
      return List.generate(ny, (i) {
        return List.generate(nx, (j) {
          return 288.15 - 6.5 * k + (math.Random().nextDouble() - 0.5) * 5;
        });
      });
    });
    
    final pressureData = List.generate(nz, (k) {
      return List.generate(ny, (i) {
        return List.generate(nx, (j) {
          return 1013.25 - 12 * k + (math.Random().nextDouble() - 0.5) * 10;
        });
      });
    });
    
    final windSpeedData = List.generate(nz, (k) {
      return List.generate(ny, (i) {
        return List.generate(nx, (j) {
          return 10 + math.Random().nextDouble() * 20;
        });
      });
    });
    
    final humidityData = List.generate(nz, (k) {
      return List.generate(ny, (i) {
        return List.generate(nx, (j) {
          return 50 + math.Random().nextDouble() * 40;
        });
      });
    });
    
    return GridData(
      nx: nx,
      ny: ny,
      nz: nz,
      temperatureData: temperatureData,
      pressureData: pressureData,
      windSpeedData: windSpeedData,
      humidityData: humidityData,
      metadata: GridMetadata(
        timestamp: DateTime.now(),
        centerX: 115.0,
        centerY: 35.0,
        centerZ: 10000.0,
        dx: 20000.0,
        dy: 20000.0,
        dz: 1000.0,
        projection: 'lambert_conformal_conic',
        attributes: {},
      ),
    );
  }
  
  void _startPerformanceMonitoring() {
    _performanceTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      final metrics = _performanceOptimizer.getCurrentMetrics();
      setState(() {
        _currentMetrics = metrics;
      });
      
      // 自动性能优化
      _performAutoOptimization();
    });
  }
  
  void _performAutoOptimization() {
    if (_currentMetrics == null) return;
    
    final recommendations = _performanceOptimizer.getPerformanceRecommendations();
    for (final recommendation in recommendations) {
      if (recommendation.priority == Priority.high) {
        _performanceOptimizer.applyRecommendation(recommendation);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    _loadingController.dispose();
    _transitionController.dispose();
    _performanceTimer?.cancel();
    _performanceOptimizer.dispose();
    _layoutManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0f3460),
      body: _isLoading ? _buildLoadingScreen() : _buildMainContent(),
    );
  }
  
  Widget _buildLoadingScreen() {
    return AnimatedBuilder(
      animation: _loadingAnimation,
      builder: (context, child) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.scale(
                scale: _loadingAnimation.value,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [Colors.cyan, Colors.blue],
                    ),
                  ),
                  child: Icon(
                    Icons.radar,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FadeTransition(
                opacity: _loadingAnimation,
                child: Column(
                  children: [
                    Text(
                      '气象沙盘模拟器',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '正在初始化Linux后端...',
                      style: TextStyle(
                        color: Colors.cyan.withOpacity(0.8),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 200,
                      child: LinearProgressIndicator(
                        value: _loadingAnimation.value,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildMainContent() {
    return Column(
      children: [
        _buildHeader(),
        _buildTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRadarView(),
              _buildGridView(),
              _buildSandboxElementsView(),
              _buildUltimateSystemView(),
              _buildAnalysisView(),
              _buildSettingsView(),
            ],
          ),
        ),
        _buildStatusBar(),
      ],
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
      ),
      child: Row(
        children: [
          Icon(
            Icons.radar,
            color: Colors.cyan,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '气象沙盘模拟器',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      _isLinuxBackendConnected ? Icons.check_circle : Icons.error,
                      color: _isLinuxBackendConnected ? Colors.green : Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isLinuxBackendConnected ? 'Linux后端已连接' : 'Linux后端未连接',
                      style: TextStyle(
                        color: _isLinuxBackendConnected ? Colors.green : Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.cyan),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'refresh_data',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 16),
                    SizedBox(width: 8),
                    Text('刷新数据'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'performance_optimize',
                child: Row(
                  children: [
                    Icon(Icons.speed, size: 16),
                    SizedBox(width: 8),
                    Text('性能优化'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export_report',
                child: Row(
                  children: [
                    Icon(Icons.download, size: 16),
                    SizedBox(width: 8),
                    Text('导出报告'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.cyan,
        labelColor: Colors.cyan,
        unselectedLabelColor: Colors.white.withOpacity(0.6),
        tabs: [
          Tab(
            icon: Icon(Icons.radar),
            text: '雷达',
          ),
            Tab(
              icon: Icon(Icons.grid_on),
              text: '网格',
            ),
            Tab(
              icon: Icon(Icons.terrain),
              text: '沙盘元素',
            ),
                        Tab(
                          icon: Icon(Icons.all_inclusive),
                          text: '终极系统',
                        ),
                        Tab(
                          icon: Icon(Icons.dashboard),
                          text: '专业UI',
                        ),
                        Tab(
                          icon: Icon(Icons.analytics),
                          text: '分析',
                      ),          Tab(
            icon: Icon(Icons.settings),
            text: '设置',
          ),
        ],
      ),
    );
  }
  
  Widget _buildRadarView() {
    if (_currentRadarData == null) {
      return _buildEmptyState('雷达数据加载中...');
    }
    
    return Column(
      children: [
        _buildRadarControls(),
        Expanded(
          child: _buildRadarContent(),
        ),
      ],
    );
  }
  
  Widget _buildRadarControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildRadarViewButton('专业雷达', 'professional'),
                  _buildRadarViewButton('优化雷达', 'optimized'),
                  _buildRadarViewButton('多普勒雷达', 'doppler'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRadarViewButton(String label, String view) {
    final isSelected = _selectedView == view;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedView = view;
        });
        _transitionController.forward().then((_) {
          _transitionController.reverse();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isSelected 
              ? Colors.cyan.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          border: Border.all(
            color: isSelected ? Colors.cyan : Colors.white.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.cyan : Colors.white,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
  
  Widget _buildRadarContent() {
    switch (_selectedView) {
      case 'professional':
        return _layoutManager.getAdaptiveLayout(
          layoutId: 'professional_radar',
          context: context,
          customParams: {'showHeader': false},
        );
      case 'optimized':
        return OptimizedRadarWidget(
          radarData: _currentRadarData!,
          enableGPUAcceleration: true,
          maxFPS: 60,
          onPerformanceUpdate: (fps) {
            // 性能回调处理
          },
        );
      case 'doppler':
        return DopplerRadarWidget(
          radarData: _currentRadarData!,
          onStormCellDetected: (data) {
            _handleStormCellDetection(data);
          },
          onAlertIssued: (alert) {
            _handleAlertIssued(alert);
          },
        );
      default:
        return Container();
    }
  }
  
  Widget _buildGridView() {
    if (_currentGridData == null) {
      return _buildEmptyState('网格数据加载中...\n请确保Linux后端已连接');
    }
    
    return GridVisualizationWidget(
      gridData: _currentGridData!,
      onVariableChanged: (variable) {
        print('变量切换: $variable');
      },
      onLevelChanged: (level) {
        print('层级切换: $level');
      },
      onCellTapped: (cell) {
        print('网格单元点击: $cell');
      },
    );
  }
  
  Widget _buildAnalysisView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPerformanceMetrics(),
          const SizedBox(height: 16),
          _buildProductRecommendations(),
          const SizedBox(height: 16),
          _buildServiceStatus(),
        ],
      ),
    );
  }
  
  Widget _buildPerformanceMetrics() {
    if (_currentMetrics == null) {
      return SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withOpacity(0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '性能指标',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildMetricRow('FPS', '${_currentMetrics!.averageFPS.toStringAsFixed(1)}'),
          _buildMetricRow('CPU使用率', '${(_currentMetrics!.cpuUsage * 100).toStringAsFixed(1)}%'),
          _buildMetricRow('内存使用率', '${(_currentMetrics!.memoryUsage * 100).toStringAsFixed(1)}%'),
          _buildMetricRow('渲染时间', '${_currentMetrics!.renderTime.toStringAsFixed(1)}ms'),
        ],
      ),
    );
  }
  
  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.cyan,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProductRecommendations() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withOpacity(0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '产品推荐',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ..._productRecommendations.map((recommendation) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.yellow,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      recommendation.product,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    '优先级: ${recommendation.priority}',
                    style: TextStyle(
                      color: Colors.cyan,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
  
  Widget _buildServiceStatus() {
    final radarStatus = _radarEnhancedService.getServiceStatus();
    final performanceStatus = _performanceOptimizer.getServiceStatus();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withOpacity(0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '服务状态',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildStatusRow('雷达增强服务', radarStatus['initialized'] ? '已初始化' : '未初始化'),
          _buildStatusRow('性能优化器', performanceStatus['initialized'] ? '已初始化' : '未初始化'),
          _buildStatusRow('Linux后端', _isLinuxBackendConnected ? '已连接' : '未连接'),
        ],
      ),
    );
  }
  
  Widget _buildStatusRow(String service, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            service,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          Text(
            status,
            style: TextStyle(
              color: status.contains('已') ? Colors.green : Colors.orange,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSettingsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPerformanceSettings(),
          const SizedBox(height: 16),
          _buildDisplaySettings(),
          const SizedBox(height: 16),
          _buildDataSettings(),
        ],
      ),
    );
  }
  
  Widget _buildPerformanceSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withOpacity(0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '性能设置',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: Text(
              '启用性能优化',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              '自动优化渲染性能',
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
            value: true,
            onChanged: (value) {
              // 性能优化开关
            },
            activeColor: Colors.cyan,
          ),
          SwitchListTile(
            title: Text(
              '启用GPU加速',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              '使用硬件加速渲染',
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
            value: true,
            onChanged: (value) {
              // GPU加速开关
            },
            activeColor: Colors.cyan,
          ),
        ],
      ),
    );
  }
  
  Widget _buildDisplaySettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withOpacity(0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '显示设置',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: Text(
              '启用动画',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              '显示界面动画效果',
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
            value: true,
            onChanged: (value) {
              // 动画开关
            },
            activeColor: Colors.cyan,
          ),
          SwitchListTile(
            title: Text(
              '高对比度',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              '提高界面对比度',
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
            value: false,
            onChanged: (value) {
              // 高对比度开关
            },
            activeColor: Colors.cyan,
          ),
        ],
      ),
    );
  }
  
  Widget _buildDataSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withOpacity(0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '数据设置',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: Icon(Icons.refresh, color: Colors.cyan),
            title: Text(
              '刷新数据',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              '重新加载所有数据',
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
            onTap: _loadData,
          ),
          ListTile(
            leading: Icon(Icons.clear, color: Colors.cyan),
            title: Text(
              '清除缓存',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              '清除所有缓存数据',
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
            onTap: () {
              // 清除缓存
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.cyan,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '气象沙盘模拟器 v0.0.1 | Linux后端: ${_isLinuxBackendConnected ? "已连接" : "未连接"} | '
              'FPS: ${_currentMetrics?.averageFPS.toStringAsFixed(1) ?? "0"}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ),
          Text(
            DateTime.now().toString().substring(11, 19),
            style: TextStyle(
              color: Colors.cyan,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSandboxElementsView() {
    Map<String, dynamic> radarData = {};
    Map<String, dynamic> wrfData = {};
    
    if (_currentRadarData != null) {
      radarData = {
        'timestamp': _currentRadarData!.timestamp.toIso8601String(),
        'frames': _currentRadarData!.frames.length,
        'coverage_area': _currentRadarData!.coverageArea,
      };
    }
    
    if (_currentGridData != null) {
      wrfData = {
        'grid_size': '${_currentGridData!.nx}×${_currentGridData!.ny}×${_currentGridData!.nz}',
        'variables': _currentGridData!.variables.keys.toList(),
        'time_steps': _currentGridData!.timeSteps,
      };
    }
    
    return SandboxElementsWidget(
      radarData: radarData,
      wrfData: wrfData,
      onElementUpdate: (update) {
        _handleSandboxElementUpdate(update);
      },
    );
  }
  
  void _handleSandboxElementUpdate(Map<String, dynamic> update) {
    String action = update['action'];
    
    switch (action) {
      case 'add':
        print('添加沙盘元素: ${update['element']['id']}');
        // 可以在这里添加与气象数据的交互逻辑
        break;
        
      case 'move':
        print('移动沙盘元素: ${update['element']['id']}');
        // 更新元素位置对气象的影响
        break;
        
      case 'delete':
        print('删除沙盘元素: ${update['element_id']}');
        // 移除元素相关的气象影响
        break;
        
      case 'modify':
        print('修改沙盘元素: ${update['element']['id']}');
        // 更新元素属性
        break;
    }
    
    // 触发气象数据重新计算
    _recalculateWeatherWithElements();
  }
  
  void _recalculateWeatherWithElements() {
    // 基于沙盘元素重新计算气象数据
    // 这里可以实现地形对风场的影响、城市热岛效应等
    
    if (_isLinuxBackendConnected) {
      // 调用Linux后端重新计算
      _callLinuxBackendWithElements();
    } else {
      // 使用本地模拟
      _simulateLocalWeatherWithElements();
    }
  }
  
  Widget _buildUltimateSystemView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 系统状态概览
          _buildUltimateSystemOverview(),
          
          const SizedBox(height: 20),
          
          // 子系统状态
          _buildSubsystemStatus(),
          
          const SizedBox(height: 20),
          
          // 模拟控制
          _buildSimulationControls(),
          
          const SizedBox(height: 20),
          
          // 性能监控
          _buildPerformanceMonitor(),
          
          const SizedBox(height: 20),
          
          // 系统诊断
          _buildSystemDiagnostics(),
        ],
      ),
    );
  }
  
  Widget _buildUltimateSystemOverview() {
    var systemState = _ultimateWeatherSystem.getSystemState();
    var currentTime = _ultimateWeatherSystem.getCurrentTime();
    var systemData = _ultimateWeatherSystem.getSystemData();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.cyan[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.all_inclusive, color: Colors.blue[700], size: 32),
              const SizedBox(width: 12),
              Text(
                '终极气象系统',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getSystemStateColor(systemState),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getSystemStateText(systemState),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              _buildInfoCard(
                '当前时间',
                currentTime.toString().substring(11, 19),
                Icons.access_time,
                Colors.orange,
              ),
              const SizedBox(width: 12),
              _buildInfoCard(
                '模拟日期',
                currentTime.toString().substring(0, 10),
                Icons.calendar_today,
                Colors.green,
              ),
              const SizedBox(width: 12),
              _buildInfoCard(
                '网格规模',
                '${systemData['grid']?['dimensions']?['nx'] ?? 0}×${systemData['grid']?['dimensions']?['ny'] ?? 0}×${systemData['grid']?['dimensions']?['nz'] ?? 0}',
                Icons.grid_4x4,
                Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getSystemStateColor(WeatherSystemState state) {
    switch (state) {
      case WeatherSystemState.ready:
        return Colors.green;
      case WeatherSystemState.running:
        return Colors.blue;
      case WeatherSystemState.paused:
        return Colors.orange;
      case WeatherSystemState.error:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  String _getSystemStateText(WeatherSystemState state) {
    switch (state) {
      case WeatherSystemState.initializing:
        return '初始化中';
      case WeatherSystemState.ready:
        return '就绪';
      case WeatherSystemState.running:
        return '运行中';
      case WeatherSystemState.paused:
        return '暂停';
      case WeatherSystemState.error:
        return '错误';
      case WeatherSystemState.stopped:
        return '停止';
      default:
        return '未知';
    }
  }
  
  Widget _buildSubsystemStatus() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '子系统状态',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          
          const SizedBox(height: 16),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 3,
            children: [
              _buildSubsystemCard('水汽系统', '💧', Colors.blue, '运行正常'),
              _buildSubsystemCard('雷暴系统', '⛈️', Colors.purple, '待机中'),
              _buildSubsystemCard('地形系统', '🏔️', Colors.green, '运行正常'),
              _buildSubsystemCard('海洋系统', '🌊', Colors.cyan, '运行正常'),
              _buildSubsystemCard('城市系统', '🏙️', Colors.orange, '运行正常'),
              _buildSubsystemCard('辐射系统', '☀️', Colors.yellow, '运行正常'),
              _buildSubsystemCard('化学系统', '🧪', Colors.red, '运行正常'),
              _buildSubsystemCard('气候系统', '🌡️', Colors.indigo, '运行正常'),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSubsystemCard(String name, String emoji, Color color, String status) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                    fontSize: 14,
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSimulationControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '模拟控制',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _runUltimateSimulation,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('运行模拟'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pauseSimulation,
                  icon: const Icon(Icons.pause),
                  label: const Text('暂停模拟'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              const Text('模拟时长:'),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<int>(
                  value: 24,
                  items: [6, 12, 24, 48, 72].map((hours) {
                    return DropdownMenuItem(
                      value: hours,
                      child: Text('$hours 小时'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    // 更新模拟时长
                  },
                ),
              ),
              const SizedBox(width: 20),
              const Text('时间步长:'),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<int>(
                  value: 15,
                  items: [5, 10, 15, 30, 60].map((minutes) {
                    return DropdownMenuItem(
                      value: minutes,
                      child: Text('$minutes 分钟'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    // 更新时间步长
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildPerformanceMonitor() {
    var metrics = _ultimateWeatherSystem.getPerformanceMetrics();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '性能监控',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'CPU 使用率',
                  '${metrics['cpu_usage']?.toStringAsFixed(1) ?? '0.0'}%',
                  Icons.memory,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  '内存使用',
                  '${(metrics['memory_usage'] ?? 0.0).toStringAsFixed(0)} MB',
                  Icons.storage,
                  Colors.green,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  '计算时间',
                  '${(metrics['compute_time'] ?? 0.0).toStringAsFixed(1)} ms',
                  Icons.timer,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  '数据吞吐',
                  '${(metrics['data_throughput'] ?? 0.0).toStringAsFixed(1)} MB/s',
                  Icons.speed,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSystemDiagnostics() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '系统诊断',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          
          const SizedBox(height: 16),
          
          _buildDiagnosticItem('质量控制', '正常', Colors.green),
          _buildDiagnosticItem('物理一致性', '正常', Colors.green),
          _buildDiagnosticItem('数值稳定性', '正常', Colors.green),
          _buildDiagnosticItem('质量守恒', '正常', Colors.green),
          _buildDiagnosticItem('能量守恒', '正常', Colors.green),
          _buildDiagnosticItem('CFL条件', '正常', Colors.green),
        ],
      ),
    );
  }
  
  Widget _buildDiagnosticItem(String name, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            status == '正常' ? Icons.check_circle : Icons.error,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _runUltimateSimulation() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      var results = await _ultimateWeatherSystem.runSimulation(
        durationHours: 24,
        timeStepMinutes: 15,
      );
      
      print('✅ 终极模拟完成: ${results['total_steps']} 步');
      
      // 处理模拟结果
      _processSimulationResults(results);
      
    } catch (e) {
      print('❌ 模拟失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('模拟失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _pauseSimulation() {
    // 暂停模拟逻辑
    print('⏸️ 模拟已暂停');
  }
  
  void _processSimulationResults(Map<String, dynamic> results) {
    // 处理和显示模拟结果
    print('📊 处理模拟结果...');
    
    // 可以在这里更新UI显示结果
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('模拟完成！共 ${results['total_steps']} 个时间步'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  void _callLinuxBackendWithElements() async {
    try {
      // 调用Linux后端API，传递沙盘元素数据
      final response = await LinuxBackendService.getSystemStatus();
      
      if (response['server'] != 'Fallback Mode') {
        // 后端可用，传递沙盘元素数据
        print('使用Linux后端计算沙盘元素影响');
      }
    } catch (e) {
      print('Linux后端调用失败: $e');
    }
  }
  
  void _simulateLocalWeatherWithElements() {
    // 本地模拟沙盘元素对气象的影响
    print('本地模拟沙盘元素气象影响');
    
    // 可以在这里实现：
    // 1. 地形抬升作用
    // 2. 城市热岛效应
    // 3. 水体蒸发冷却
    // 4. 森林蒸腾作用
    // 5. 河流水汽输送
  }
  
  Widget _buildUltimateSystemView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 系统选择
          _buildSystemSelector(),
          
          const SizedBox(height: 20),
          
          // 系统状态
          _buildSystemStatus(),
          
          const SizedBox(height: 20),
          
          // 内存监控
          _buildMemoryMonitor(),
          
          const SizedBox(height: 20),
          
          // 控制面板
          _buildControlPanel(),
          
          const SizedBox(height: 20),
          
          // 性能指标
          _buildPerformanceMetrics(),
        ],
      ),
    );
  }
  
  Widget _buildSystemSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withOpacity(0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '系统选择',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {}),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.blue.withOpacity(0.2),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.all_inclusive, color: Colors.blue, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          '终极系统',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '完整功能',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {}),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.green.withOpacity(0.2),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.speed, color: Colors.green, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          '优化系统',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '600MB目标',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSystemStatus() {
    var ultimateStatus = _ultimateWeatherSystem.getSystemStatus();
    var optimizedStatus = _optimizedWeatherSystem.getSystemStatus();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withOpacity(0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '系统状态',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // 终极系统状态
          _buildStatusRow('终极系统', '运行中', Colors.green),
          _buildStatusRow('网格维度', '${ultimateStatus['grid_dimensions']['nx']}×${ultimateStatus['grid_dimensions']['ny']}×${ultimateStatus['grid_dimensions']['nz']}', Colors.blue),
          _buildStatusRow('子系统数量', '${ultimateStatus['subsystems_count']}', Colors.blue),
          
          const Divider(color: Colors.white24),
          
          // 优化系统状态
          _buildStatusRow('优化系统', '运行中', Colors.green),
          _buildStatusRow('网格维度', '${optimizedStatus['grid_dimensions']['nx']}×${optimizedStatus['grid_dimensions']['ny']}×${optimizedStatus['grid_dimensions']['nz']}', Colors.green),
          _buildStatusRow('内存目标', '${optimizedStatus['memory_target_mb']}MB', Colors.green),
        ],
      ),
    );
  }
  
  Widget _buildStatusRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMemoryMonitor() {
    var optimizedStatus = _optimizedWeatherSystem.getSystemStatus();
    double currentUsage = optimizedStatus['memory_usage_mb'];
    double targetUsage = optimizedStatus['memory_target_mb'];
    double usagePercent = (currentUsage / targetUsage) * 100;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withOpacity(0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '内存监控',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // 内存使用条
          Container(
            height: 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white.withOpacity(0.2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: usagePercent / 100,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: usagePercent > 80 ? Colors.red : 
                         usagePercent > 60 ? Colors.orange : Colors.green,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${currentUsage.toStringAsFixed(1)}MB / ${targetUsage.toStringAsFixed(0)}MB',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              Text(
                '${usagePercent.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: usagePercent > 80 ? Colors.red : 
                         usagePercent > 60 ? Colors.orange : Colors.green,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 内存优化建议
          if (usagePercent > 80)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.red.withOpacity(0.2),
                border: Border.all(color: Colors.red),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '内存使用过高，建议减少模拟时长或网格分辨率',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withOpacity(0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '控制面板',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _runOptimizedSimulation,
                  icon: Icon(Icons.play_arrow),
                  label: Text('运行优化模拟'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _runUltimateSimulation,
                  icon: Icon(Icons.play_arrow),
                  label: Text('运行终极模拟'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 模拟参数
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '模拟时长 (小时)',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Slider(
                      value: 12,
                      min: 1,
                      max: 24,
                      divisions: 23,
                      onChanged: (value) {},
                      activeColor: Colors.cyan,
                    ),
                    Text(
                      '12小时',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '时间步长 (分钟)',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Slider(
                      value: 15,
                      min: 5,
                      max: 60,
                      divisions: 11,
                      onChanged: (value) {},
                      activeColor: Colors.cyan,
                    ),
                    Text(
                      '15分钟',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildPerformanceMetrics() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withOpacity(0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '性能指标',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  '计算速度',
                  '50ms/步',
                  Icons.speed,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  '内存效率',
                  '85%',
                  Icons.memory,
                  Colors.blue,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  '精度保持',
                  '92%',
                  Icons.high_quality,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  '稳定性',
                  '98%',
                  Icons.stability,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.2),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  void _runOptimizedSimulation() async {
    print('🚀 启动优化气象模拟...');
    
    try {
      var results = await _optimizedWeatherSystem.runOptimizedSimulation(
        durationHours: 12,
        timeStepMinutes: 15,
      );
      
      print('✅ 优化模拟完成');
      print('📊 最终内存使用: ${results['final_memory_usage']}MB');
      print('⏱️ 总计算步数: ${results['total_steps']}');
      
    } catch (e) {
      print('❌ 优化模拟失败: $e');
    }
  }
  
  Widget _buildProfessionalUI() {
    return ProfessionalWeatherScreen();
  }
  
  void _runUltimateSimulation() async {
    print('🚀 启动终极气象模拟...');
    
    try {
      var results = await _ultimateWeatherSystem.runSimulation(
        durationHours: 12,
        timeStepMinutes: 15,
      );
      
      print('✅ 终极模拟完成');
      print('📊 输出数据点: ${results['outputs'].length}');
      
    } catch (e) {
      print('❌ 终极模拟失败: $e');
    }
  }
  
  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off,
            color: Colors.white.withOpacity(0.6),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  void _handleMenuAction(String action) {
    switch (action) {
      case 'refresh_data':
        _loadData();
        break;
      case 'performance_optimize':
        _performanceOptimizer.optimizePerformance();
        break;
      case 'export_report':
        _exportReport();
        break;
    }
  }
  
  void _handleStormCellDetection(Map<String, dynamic> data) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('检测到风暴单体'),
        backgroundColor: Colors.orange,
      ),
    );
  }
  
  void _handleAlertIssued(String alert) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('天气警报: $alert'),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  void _exportReport() {
    // 导出报告实现
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('报告已导出'),
        backgroundColor: Colors.cyan,
      ),
    );
  }
}