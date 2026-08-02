import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'window_pointer_watcher_stub.dart'
    if (dart.library.js_interop) 'window_pointer_watcher_web.dart';

/// 极简动态背景。
///
/// 内容之上铺一层栅格线条（屏幕中心清晰、向四边渐隐），
/// 鼠标位置叠加一圈主题色辉光：移入时淡入并平滑跟随，
/// 移出时原地淡出（不飞回中心）。不拦截任何指针事件，
/// 系统开启「减弱动态效果」时整层隐藏。
class AnimatedBackground extends StatefulWidget {
  final Widget child;

  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<Offset> _glow = ValueNotifier(Offset.zero);
  final ValueNotifier<double> _glowAlpha = ValueNotifier(0.0);

  Offset _target = Offset.zero;
  double _targetAlpha = 0.0;
  bool _hasSize = false;
  Duration _lastElapsed = Duration.zero;
  void Function()? _disposeWindowWatcher;

  @override
  void initState() {
    super.initState();
    _ticker = Ticker(_onTick);
    _disposeWindowWatcher = watchWindowPointerExit(onExit: _onWindowLeave);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _ticker.stop();
    } else if (!_ticker.isActive && _hasPendingAnimation()) {
      // 减弱动态效果恢复后，若辉光曾被打断在中间状态，则重启动画追平目标。
      _startTicker();
    }
  }

  /// 当前辉光位置/透明度是否尚未到达目标（存在未完成的动画）。
  bool _hasPendingAnimation() =>
      (_glow.value - _target).distance >= 0.5 ||
      (_glowAlpha.value - _targetAlpha).abs() >= 0.01;

  @override
  void dispose() {
    _disposeWindowWatcher?.call();
    _ticker.dispose();
    _glow.dispose();
    _glowAlpha.dispose();
    super.dispose();
  }

  /// 跟随/淡入的平滑时间常数（保持跟手）。
  static const _followTau = Duration(milliseconds: 45);
  /// 淡出的平滑时间常数（比跟随更舒缓，肉眼可感知的渐隐）。
  static const _fadeTau = Duration(milliseconds: 450);

  double _smoothing(Duration dt, Duration tau) =>
      (1 - math.exp(-dt.inMicroseconds / tau.inMicroseconds))
          .clamp(0.0, 1.0);

  void _onTick(Duration elapsed) {
    if (!_hasSize) return;
    final dt = elapsed - _lastElapsed;
    _lastElapsed = elapsed;
    final s = _smoothing(dt, _followTau);
    final alphaTau = _targetAlpha < _glowAlpha.value ? _fadeTau : _followTau;
    final sAlpha = _smoothing(dt, alphaTau);

    final nextGlow = Offset.lerp(_glow.value, _target, s)!;
    final nextAlpha =
        _glowAlpha.value + (_targetAlpha - _glowAlpha.value) * sAlpha;

    final glowSettled = (nextGlow - _target).distance < 0.5;
    final alphaSettled = (nextAlpha - _targetAlpha).abs() < 0.01;
    if (glowSettled && alphaSettled) {
      _glow.value = _target;
      _glowAlpha.value = _targetAlpha;
      _ticker.stop();
    } else {
      _glow.value = nextGlow;
      _glowAlpha.value = nextAlpha;
    }
  }

  void _startTicker() {
    if (_ticker.isActive || !_hasSize) return;
    _lastElapsed = Duration.zero;
    _ticker.start();
  }

  void _onEnter(PointerEnterEvent event) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) return;
    _targetAlpha = 1.0;
    _target = event.localPosition;
    _startTicker();
  }

  void _onHover(PointerHoverEvent event) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) return;
    _targetAlpha = 1.0;
    _target = event.localPosition;
    _startTicker();
  }

  void _onExit(PointerExitEvent event) => _fadeOut();

  /// 兜底：鼠标离开浏览器窗口时（引擎事件缺失的情况下）同样原地淡出。
  void _onWindowLeave() => _fadeOut();

  void _fadeOut() {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) return;
    _targetAlpha = 0.0;
    _startTicker();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final glowColor = Theme.of(context).colorScheme.primary;
    return MouseRegion(
      onEnter: disableAnimations ? null : _onEnter,
      onHover: disableAnimations ? null : _onHover,
      onExit: disableAnimations ? null : _onExit,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (!_hasSize) {
            _hasSize = true;
            _glow.value = Offset(
              constraints.maxWidth / 2,
              constraints.maxHeight / 2,
            );
            _target = _glow.value;
          }
          return Stack(
            fit: StackFit.expand,
            children: [
              widget.child,
              // 栅格 + 辉光覆盖在内容之上：页面过渡的不透明底色盖住内容区，
              // 只有放在最上层才能全屏可见。用 IgnorePointer 不拦截指针事件。
              if (!disableAnimations)
                IgnorePointer(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_glow, _glowAlpha]),
                    builder: (context, _) => RepaintBoundary(
                      child: CustomPaint(
                        painter: _BackgroundPainter(
                          color: glowColor,
                          glow: _glow.value,
                          glowAlpha: _glowAlpha.value,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final Color color;
  final Offset glow;
  final double glowAlpha;

  _BackgroundPainter({
    required this.color,
    required this.glow,
    required this.glowAlpha,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    _paintGrid(canvas, size);

    if (glowAlpha <= 0.0) return;
    // 光标辉光：范围适中，浓度随 glowAlpha 淡入淡出。
    final radius = math.max(size.shortestSide * 0.5, 220.0);
    final glowRect = Rect.fromCircle(center: glow, radius: radius);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.13 * glowAlpha),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(glowRect),
    );
  }

  /// 栅格线条：屏幕中心清晰、向四边渐隐；
  /// 鼠标光圈范围内再提亮一档（跟随鼠标），光圈外保持较淡的基础浓度。
  void _paintGrid(Canvas canvas, Size size) {
    final pitch = math.max(size.shortestSide / 13.0, 40.0);
    final center = size.center(Offset.zero);

    // 基础栅格：中心清晰、向边缘渐隐。
    final base = Paint()
      ..strokeWidth = 1.0
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.10),
          color.withValues(alpha: 0.05),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.62, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: size.shortestSide));
    _drawGridLines(canvas, size, pitch, base);

    // 提亮层：以鼠标光圈为圆心，光圈内栅格额外 +0.06（随辉光同步淡入淡出），
    // 光圈外为透明。
    final glowRadius = math.max(size.shortestSide * 0.5, 220.0);
    final boost = Paint()
      ..strokeWidth = 1.0
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.06 * glowAlpha),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: glow, radius: glowRadius));
    _drawGridLines(canvas, size, pitch, boost);
  }

  void _drawGridLines(Canvas canvas, Size size, double pitch, Paint paint) {
    for (double x = size.width % pitch; x <= size.width; x += pitch) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = size.height % pitch; y <= size.height; y += pitch) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_BackgroundPainter oldDelegate) =>
      oldDelegate.glow != glow ||
      oldDelegate.glowAlpha != glowAlpha ||
      oldDelegate.color != color;
}
