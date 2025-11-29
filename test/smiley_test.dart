import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smiley_app/smiley_app.dart';

void main() {
  group('SmileyFacePage Widget Tests', () {
    testWidgets('should display smiley face with initial expression', (tester) async {
      await tester.pumpWidget(const SmileyApp());
      
      // 检查是否显示初始表情
      expect(find.text('😊'), findsOneWidget);
      expect(find.text(':-)'), findsOneWidget);
      expect(find.text('开心'), findsOneWidget);
    });

    testWidgets('should switch expression when FAB is pressed', (tester) async {
      await tester.pumpWidget(const SmileyApp());
      
      // 点击切换按钮
      await tester.tap(find.byIcon(Icons.sentiment_very_satisfied));
      await tester.pump();
      
      // 检查表情是否切换
      expect(find.text('😎'), findsOneWidget);
      expect(find.text('B-)'), findsOneWidget);
      expect(find.text('酷炫'), findsOneWidget);
    });

    testWidgets('should random switch expression when shuffle FAB is pressed', (tester) async {
      await tester.pumpWidget(const SmileyApp());
      
      // 点击随机切换按钮
      await tester.tap(find.byIcon(Icons.shuffle));
      await tester.pump();
      
      // 检查是否切换到第4个表情（困倦）
      expect(find.text('😴'), findsOneWidget);
      expect(find.text('-_-'), findsOneWidget);
      expect(find.text('困倦'), findsOneWidget);
    });

    testWidgets('should cycle through all expressions', (tester) async {
      await tester.pumpWidget(const SmileyApp());
      
      final expressions = ['😊', '😎', '🥰', '😴', '🤗', '😋'];
      final names = ['开心', '酷炫', '爱心', '困倦', '拥抱', '美味'];
      
      for (int i = 0; i < expressions.length; i++) {
        // 点击切换按钮
        await tester.tap(find.byIcon(Icons.sentiment_very_satisfied));
        await tester.pump();
        
        // 检查当前表情
        expect(find.text(expressions[(i + 1) % expressions.length]), findsOneWidget);
        expect(find.text(names[(i + 1) % names.length]), findsOneWidget);
      }
    });

    testWidgets('should display app bar with correct title', (tester) async {
      await tester.pumpWidget(const SmileyApp());
      
      expect(find.text('动态笑脸'), findsOneWidget);
    });

    testWidgets('should have two floating action buttons', (tester) async {
      await tester.pumpWidget(const SmileyApp());
      
      expect(find.byIcon(Icons.sentiment_very_satisfied), findsOneWidget);
      expect(find.byIcon(Icons.shuffle), findsOneWidget);
    });

    testWidgets('should display emoji in circular container', (tester) async {
      await tester.pumpWidget(const SmileyApp());
      
      // 查找圆形容器（通过查找Container并验证其shape属性）
      final container = tester.widget(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration?;
      
      expect(decoration?.shape, equals(BoxShape.circle));
    });
  });

  group('Animation Tests', () {
    testWidgets('should have blink animation working', (tester) async {
      await tester.pumpWidget(const SmileyApp());
      
      // 等待眨眼动画
      await tester.pump(const Duration(seconds: 3));
      
      // 验证眼睛容器存在（对于开心表情）
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('should have color animation working', (tester) async {
      await tester.pumpWidget(const SmileyApp());
      
      // 获取初始颜色
      await tester.pump();
      final initialContainer = tester.widget(find.byType(Container).first);
      final initialDecoration = initialContainer.decoration as BoxDecoration?;
      final initialColor = initialDecoration?.color;
      
      // 等待颜色动画
      await tester.pump(const Duration(seconds: 2));
      
      // 验证颜色已改变
      final animatedContainer = tester.widget(find.byType(Container).first);
      final animatedDecoration = animatedContainer.decoration as BoxDecoration?;
      final animatedColor = animatedDecoration?.color;
      
      expect(initialColor, isNot(equals(animatedColor)));
    });
  });

  group('UI Component Tests', () {
    testWidgets('should display text expressions below emoji', (tester) async {
      await tester.pumpWidget(const SmileyApp());
      
      // 验证文字表情在表情下方
      final emojiFinder = find.text('😊');
      final textFinder = find.text(':-)');
      
      expect(emojiFinder, findsOneWidget);
      expect(textFinder, findsOneWidget);
      
      // 验证文字表情在表情下方
      final emojiPosition = tester.getCenter(emojiFinder);
      final textPosition = tester.getCenter(textFinder);
      
      expect(textPosition.dy, greaterThan(emojiPosition.dy));
    });

    testWidgets('should have proper spacing between elements', (tester) async {
      await tester.pumpWidget(const SmileyApp());
      
      // 验证SizedBox创建的间距
      expect(find.byType(SizedBox), findsWidgets);
    });
  });
}