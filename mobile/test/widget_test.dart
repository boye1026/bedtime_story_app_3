import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bedtime_story_app/main.dart';

void main() {
  testWidgets('App smoke test - 首页正常启动', (WidgetTester tester) async {
    await tester.pumpWidget(const BedtimeStoryApp());

    expect(find.text('🌙 睡前故事'), findsOneWidget);

    expect(find.text('晚安，小宝贝'), findsOneWidget);

    expect(find.byIcon(Icons.auto_awesome), findsWidgets);
    expect(find.byIcon(Icons.library_books), findsOneWidget);
  });

  testWidgets('App smoke test - 导航按钮存在', (WidgetTester tester) async {
    await tester.pumpWidget(const BedtimeStoryApp());

    expect(find.byIcon(Icons.history), findsOneWidget);
    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(find.byIcon(Icons.workspace_premium), findsOneWidget);
  });
}
