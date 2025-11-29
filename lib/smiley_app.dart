import 'package:flutter/material.dart';

void main() {
  runApp(const SmileyApp());
}

class SmileyApp extends StatelessWidget {
  const SmileyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '动态笑脸',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const SmileyFacePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SmileyFacePage extends StatefulWidget {
  const SmileyFacePage({Key? key}) : super(key: key);

  @override
  State<SmileyFacePage> createState() => _SmileyFacePageState();
}

class _SmileyFacePageState extends State<SmileyFacePage>
    with TickerProviderStateMixin {
  late AnimationController _blinkController;
  late AnimationController _colorController;
  late AnimationController _expressionController;
  
  late Animation<double> _blinkAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _expressionAnimation;
  
  int _currentExpression = 0;
  
  final List<String> _expressions = ['😊', '😎', '🥰', '😴', '🤗', '😋'];
  final List<String> _textExpressions = [':-)', 'B-)', '<3', '-_-', '(>_<<)', ':-P'];
  
  @override
  void initState() {
    super.initState();
    
    // 眨眼动画控制器
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // 颜色变化动画控制器
    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    
    // 表情切换动画控制器
    _expressionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    // 眨眼动画
    _blinkAnimation = Tween<double>(
      begin: 1.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _blinkController,
      curve: Curves.easeInOut,
    ));
    
    // 颜色动画
    _colorAnimation = ColorTween(
      begin: Colors.yellow[300],
      end: Colors.orange[300],
    ).animate(CurvedAnimation(
      parent: _colorController,
      curve: Curves.easeInOut,
    ));
    
    // 表情切换动画
    _expressionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _expressionController,
      curve: Curves.elasticOut,
    ));
    
    // 启动动画
    _startBlinking();
    _startColorAnimation();
  }
  
  void _startBlinking() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _blinkController.forward().then((_) {
          _blinkController.reverse();
        });
        _startBlinking();
      }
    });
  }
  
  void _startColorAnimation() {
    _colorController.repeat(reverse: true);
  }
  
  void _switchExpression() {
    setState(() {
      _currentExpression = (_currentExpression + 1) % _expressions.length;
    });
    _expressionController.forward();
  }
  
  @override
  void dispose() {
    _blinkController.dispose();
    _colorController.dispose();
    _expressionController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('动态笑脸'),
        backgroundColor: Colors.blue[300],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 笑脸容器
            AnimatedBuilder(
              animation: Listenable.merge([_colorAnimation, _expressionAnimation]),
              builder: (context, child) {
                return Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: _colorAnimation.value,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // 笑脸主体
                      Center(
                        child: Transform.scale(
                          scale: 0.8 + (_expressionAnimation.value * 0.2),
                          child: Text(
                            _expressions[_currentExpression],
                            style: const TextStyle(
                              fontSize: 80,
                            ),
                          ),
                        ),
                      ),
                      // 眨眼效果（仅对特定表情）
                      if (_currentExpression == 0 || _currentExpression == 3)
                        Positioned(
                          top: 60,
                          left: 70,
                          child: AnimatedBuilder(
                            animation: _blinkAnimation,
                            builder: (context, child) {
                              return Container(
                                width: 15,
                                height: 15 * _blinkAnimation.value,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  shape: BoxShape.circle,
                                ),
                              );
                            },
                          ),
                        ),
                      if (_currentExpression == 0 || _currentExpression == 3)
                        Positioned(
                          top: 60,
                          right: 70,
                          child: AnimatedBuilder(
                            animation: _blinkAnimation,
                            builder: (context, child) {
                              return Container(
                                width: 15,
                                height: 15 * _blinkAnimation.value,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  shape: BoxShape.circle,
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            // 文字表情
            AnimatedBuilder(
              animation: _expressionAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.8 + (_expressionAnimation.value * 0.2),
                  child: Text(
                    _textExpressions[_currentExpression],
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            // 表情名称
            Text(
              _getExpressionName(),
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "switch",
            onPressed: _switchExpression,
            backgroundColor: Colors.blue[300],
            child: const Icon(Icons.sentiment_very_satisfied),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "random",
            onPressed: () {
              setState(() {
                _currentExpression = 
                    (_currentExpression + 3) % _expressions.length;
              });
              _expressionController.forward();
            },
            backgroundColor: Colors.green[300],
            child: const Icon(Icons.shuffle),
          ),
        ],
      ),
    );
  }
  
  String _getExpressionName() {
    final names = ['开心', '酷炫', '爱心', '困倦', '拥抱', '美味'];
    return names[_currentExpression];
  }
}