import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mirage/widgets/mirage_logo.dart';

Future<int> _countOpaque(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  var count = 0;
  for (var i = 3; i < data!.lengthInBytes; i += 4) {
    if (data.getUint8(i) > 0) count++;
  }
  return count;
}

Future<ui.Image> _capture(WidgetTester tester) async {
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byType(RepaintBoundary));
  final image = await boundary.toImage(pixelRatio: 1.0);
  return image;
}

void main() {
  testWidgets('动画未开始时画布为空', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        RepaintBoundary(
          child: AnimatedMirageLogo(size: 48, color: Colors.black),
        ),
      );
      final opaque = await _countOpaque(await _capture(tester));
      expect(opaque, 0);
    });
  });

  testWidgets('动画结束后绘制完整图形', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        RepaintBoundary(
          child: AnimatedMirageLogo(size: 48, color: Colors.black),
        ),
      );
      await tester.pump(const Duration(seconds: 3));
      final opaque = await _countOpaque(await _capture(tester));
      expect(opaque, greaterThan(50));
    });
  });

  testWidgets('系统减弱动态效果时直接显示完整图形', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: RepaintBoundary(
            child: AnimatedMirageLogo(size: 48, color: Colors.black),
          ),
        ),
      );
      final opaque = await _countOpaque(await _capture(tester));
      expect(opaque, greaterThan(50));
    });
  });
}
