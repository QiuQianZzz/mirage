import 'package:flutter/material.dart';

/// Mirage 站点 logo 组件。
///
/// 图形是一个极简的「M / 山峦 + 朝阳」符号：两座山峰勾勒出字母 M，
/// 右上角是一轮朝阳，呼应站名 Mirage（海市蜃楼）。
/// 使用矢量绘制，可在任意尺寸下保持清晰。
class MirageLogo extends StatelessWidget {
  /// 逻辑尺寸（正方形边长）。
  final double size;

  /// 图形颜色（通常取自主题色）。
  final Color color;

  const MirageLogo({
    super.key,
    this.size = 24,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MirageMarkPainter(color: color),
      ),
    );
  }
}

/// 品牌图标方块（圆角底色 + 白色标记），用于 favicon / App 图标。
class MirageBadge extends StatelessWidget {
  final double size;
  final Color background;
  final Color foreground;

  /// 是否为 maskable 图标：铺满整块（无圆角）、图形收缩到中间安全区内。
  final bool maskable;

  const MirageBadge({
    super.key,
    this.size = 192,
    required this.background,
    required this.foreground,
    this.maskable = false,
  });

  @override
  Widget build(BuildContext context) {
    final inset = maskable ? size * 0.10 : size * 0.22;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: maskable
            ? BorderRadius.zero
            : BorderRadius.circular(size * 0.22),
      ),
      alignment: Alignment.center,
      child: MirageLogo(size: size - inset * 2, color: foreground),
    );
  }
}

/// 动态版 logo：页面加载时播放一次「描线画出 M + 朝阳弹出」。
///
/// 尊重系统的 `disableAnimations`（减弱动态效果）设置，开启时直接显示静态完整图形。
/// 静态场景请使用 [MirageLogo]（favicon / App 图标等）。
class AnimatedMirageLogo extends StatefulWidget {
  /// 逻辑尺寸（正方形边长）。
  final double size;

  /// 图形颜色（通常取自主题色）。
  final Color color;

  /// 动画总时长。
  final Duration duration;

  const AnimatedMirageLogo({
    super.key,
    this.size = 24,
    required this.color,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<AnimatedMirageLogo> createState() => _AnimatedMirageLogoState();
}

class _AnimatedMirageLogoState extends State<AnimatedMirageLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _controller.value = 1.0;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _progress,
        builder: (context, child) => CustomPaint(
          painter: _MirageMarkPainter(
            color: widget.color,
            progress: _progress.value,
          ),
        ),
      ),
    );
  }
}

/// 以 24×24 虚拟坐标绘制「M / 山峦 + 朝阳」标记。
///
/// [progress] 为 0..1 的绘制进度：按比例描出 M 的路径（圆头笔帽，
/// 模拟笔尖书写），M 画到 [progress] 达到 [_sunStart] 后朝阳弹出。
/// 为 null 时始终绘制完整图形（静态场景）。
class _MirageMarkPainter extends CustomPainter {
  final Color color;
  final double? progress;

  /// 朝阳开始出现的进度。
  static const double _sunStart = 0.85;

  _MirageMarkPainter({required this.color, this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    final p = (progress ?? 1.0).clamp(0.0, 1.0);

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final mPath = Path()
      ..moveTo(3 * scale, 19 * scale)
      ..lineTo(8.5 * scale, 5.5 * scale)
      ..lineTo(12 * scale, 12 * scale)
      ..lineTo(15.5 * scale, 5.5 * scale)
      ..lineTo(21 * scale, 19 * scale);

    if (p >= 1.0) {
      canvas.drawPath(mPath, stroke);
    } else if (p > 0.0) {
      final metric = mPath.computeMetrics().first;
      canvas.drawPath(metric.extractPath(0, metric.length * p), stroke);
    }

    final sunProgress =
        ((p - _sunStart) / (1 - _sunStart)).clamp(0.0, 1.0);
    if (sunProgress > 0.0) {
      final pop = Curves.easeOutBack.transform(sunProgress);
      final radius = 2.0 * scale * (0.3 + 0.7 * pop);
      final alpha = (255 * Curves.easeOut.transform(sunProgress)).round();
      canvas.drawCircle(
        Offset(18.2 * scale, 4.8 * scale),
        radius,
        Paint()..color = color.withAlpha(alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_MirageMarkPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.progress != progress;
}
