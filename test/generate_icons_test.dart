import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mirage/core/theme/app_theme.dart';
import 'package:mirage/widgets/mirage_logo.dart';

/// 把品牌方块渲染成 PNG，输出到 web/ 供 favicon 与 manifest 使用。
/// 用 `flutter test test/generate_icons_test.dart` 重新生成。
void main() {
  testWidgets('generate favicon and web app icons', (WidgetTester tester) async {
    await tester.runAsync(() async {
      const files = [
        ('web/favicon.png', 128, false),
        ('web/icons/Icon-192.png', 192, false),
        ('web/icons/Icon-512.png', 512, false),
        ('web/icons/Icon-maskable-192.png', 192, true),
        ('web/icons/Icon-maskable-512.png', 512, true),
      ];
      for (final (path, size, maskable) in files) {
        final bytes = await _renderBadge(tester, size, maskable);
        File(path).writeAsBytesSync(bytes);
      }
      // 校验 favicon：中心应是白色图形、靠近角落处应是品牌青底色。
      final favicon = File('web/favicon.png').readAsBytesSync();
      final image = await _decode(favicon);
      final center = await _pixelAt(image, 64, 64);
      expect(
        center.r > 0.9 && center.g > 0.9 && center.b > 0.9,
        isTrue,
        reason: 'favicon 中心应为白色图形（实际 $center）',
      );
      final corner = await _pixelAt(image, 20, 20);
      expect(
        corner.r < 0.3 && corner.g > 0.35 && corner.b > 0.35,
        isTrue,
        reason: 'favicon 圆角内应为品牌青（实际 $corner）',
      );
    });
  });
}

Future<Uint8List> _renderBadge(
  WidgetTester tester,
  int size,
  bool maskable,
) async {
  await tester.pumpWidget(
    Center(
      child: RepaintBoundary(
        child: MirageBadge(
          size: size.toDouble(),
          background: kSeedColor,
          foreground: Colors.white,
          maskable: maskable,
        ),
      ),
    ),
  );
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byType(RepaintBoundary));
  final image = await boundary.toImage(pixelRatio: 1.0);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

Future<ui.Image> _decode(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return frame.image;
}

Future<Color> _pixelAt(ui.Image image, int x, int y) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final offset = (y * image.width + x) * 4;
  return Color.fromARGB(
    data!.getUint8(offset + 3),
    data.getUint8(offset),
    data.getUint8(offset + 1),
    data.getUint8(offset + 2),
  );
}
