import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';

import 'package:mirage/app.dart';

void main() {
  testWidgets('App renders navigation shell', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    expect(find.text('Mirage'), findsWidgets);
    expect(find.text('主页'), findsWidgets);
    expect(find.text('博客'), findsWidgets);
    expect(find.text('项目'), findsWidgets);
    expect(find.text('技艺'), findsWidgets);
  });

  testWidgets('App renders top nav bar on wide screens', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    expect(find.text('Mirage'), findsWidgets);
    expect(find.text('主页'), findsWidgets);
    expect(find.text('博客'), findsWidgets);
    expect(find.text('项目'), findsWidgets);
    expect(find.text('技艺'), findsWidgets);
  });
}