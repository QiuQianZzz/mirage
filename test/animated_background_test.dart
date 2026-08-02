import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mirage/widgets/animated_background.dart';

void main() {
  testWidgets('动态背景渲染与鼠标移动不报错', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimatedBackground(
            child: const SizedBox.expand(child: Center(child: Text('内容'))),
          ),
        ),
      ),
    );

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(20, 20));
    await tester.pump();
    await gesture.moveTo(const Offset(300, 300));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
  });

  testWidgets('减弱动态效果时隐藏辉光层', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: Scaffold(
            body: AnimatedBackground(
              child: const SizedBox.expand(child: Text('内容')),
            ),
          ),
        ),
      ),
    );
    expect(
      tester.widget<Stack>(
        find.descendant(
          of: find.byType(AnimatedBackground),
          matching: find.byType(Stack),
        ),
      ).children,
      hasLength(1),
      reason: '减弱动态效果时背景栈应只保留内容层，不添加辉光层',
    );
  });

  testWidgets('减弱动态效果恢复后，辉光层回归且鼠标动画可继续', (tester) async {
    Widget build(bool disable) => MediaQuery(
          data: MediaQueryData(disableAnimations: disable),
          child: MaterialApp(
            home: Scaffold(
              body: AnimatedBackground(
                child: const SizedBox.expand(child: Text('内容')),
              ),
            ),
          ),
        );

    await tester.pumpWidget(build(true));
    expect(
      tester
          .widget<Stack>(
            find.descendant(
              of: find.byType(AnimatedBackground),
              matching: find.byType(Stack),
            ),
          )
          .children,
      hasLength(1),
      reason: '减弱动态效果时背景栈应只保留内容层',
    );

    await tester.pumpWidget(build(false));
    await tester.pump();
    expect(
      tester
          .widget<Stack>(
            find.descendant(
              of: find.byType(AnimatedBackground),
              matching: find.byType(Stack),
            ),
          )
          .children,
      hasLength(2),
      reason: '恢复后应重新添加辉光层',
    );

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(20, 20));
    await tester.pump();
    await gesture.moveTo(const Offset(300, 300));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull, reason: '恢复后鼠标动画应正常执行');
  });
}
