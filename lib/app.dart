import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/theme/theme_store.dart';
import 'data/content_repository.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with TickerProviderStateMixin {
  final ContentRepository _repository = ContentRepository();
  final GlobalKey _boundaryKey = GlobalKey();

  late final ThemeController _themeController = ThemeController(
    readStoredTheme() ??
        (WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light),
  );

  late final GoRouter _router =
      createAppRouter(_repository, _themeController, onThemeToggle: _toggleTheme);

  String? _appTitle;

  late final AnimationController _revealController;

  ui.Image? _oldSnapshot;
  Offset? _revealOrigin;

  @override
  void initState() {
    super.initState();
    _repository.loadConfig().then((c) {
      if (mounted) setState(() => _appTitle = c.title);
    });
    // 预热内容缓存，避免首次切换分支时列表仍在加载、淡入的是空白页。
    _repository.loadPosts();
    _repository.loadProjects();
    _repository.loadSkills();
    _repository.loadEssays();
    _repository.loadPhotos();
    // 初始停在 1.0（不裁剪），切换时从 0 向外扩散到 1。
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
      value: 1.0,
    )..addStatusListener(_onRevealStatus);
  }

  @override
  void dispose() {
    _oldSnapshot?.dispose();
    _revealController.dispose();
    _themeController.dispose();
    super.dispose();
  }

  void _onRevealStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (!mounted) return;
      _oldSnapshot?.dispose();
      setState(() {
        _oldSnapshot = null;
        _revealOrigin = null;
      });
    }
  }

  /// 截取当前（旧主题）画面作为背景，切换主题后新主题从点击点向外扩散。
  Future<void> _toggleTheme(Offset origin) async {
    if (_revealController.isAnimating) return;

    ui.Image? snapshot;
    final boundary = _boundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary != null) {
      try {
        snapshot = await boundary.toImage(
          pixelRatio: math.min(View.of(context).devicePixelRatio, 1.5),
        );
      } catch (_) {
        snapshot = null;
      }
    }

    if (!mounted) return;
    setState(() {
      _oldSnapshot = snapshot;
      _revealOrigin = origin;
    });
    _themeController.toggle();
    storeTheme(_themeController.value);

    if (snapshot != null) {
      _revealController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = RepaintBoundary(
      key: _boundaryKey,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: _themeController,
        builder: (context, mode, _) {
          return MaterialApp.router(
            title: _appTitle,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: mode,
            routerConfig: _router,
          );
        },
      ),
    );

    return Directionality(
      textDirection: TextDirection.ltr,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenSize = Size(constraints.maxWidth, constraints.maxHeight);
          return Stack(
            fit: StackFit.expand,
            children: [
              // 背景：旧主题整屏画面（静态，不裁剪）。
              if (_oldSnapshot != null)
                Positioned.fill(
                  child: RawImage(image: _oldSnapshot, fit: BoxFit.cover),
                ),
              // 前景：新主题，从点击点向外放大的圆形裁剪。
              AnimatedBuilder(
                animation: _revealController,
                child: app,
                builder: (context, child) {
                  final t = Curves.easeInOutCubic
                      .transform(_revealController.value);
                  return ClipPath(
                    clipper: _CircleRevealClipper(
                      origin: _revealOrigin ?? Offset.zero,
                      progress: t,
                      screenSize: screenSize,
                    ),
                    child: child!,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 以点击点为圆心、随 progress（0→1）从 0 放大到最大半径的圆形裁剪，
/// 使上层的新主题从点击点向四周扩散。
class _CircleRevealClipper extends CustomClipper<Path> {
  final Offset origin;
  final double progress;
  final Size screenSize;

  _CircleRevealClipper({
    required this.origin,
    required this.progress,
    required this.screenSize,
  });

  double get _maxRadius {
    final corners = [
      (origin - Offset.zero).distance,
      (origin - Offset(screenSize.width, 0)).distance,
      (origin - Offset(0, screenSize.height)).distance,
      (origin - screenSize.bottomRight(Offset.zero)).distance,
    ];
    return corners.reduce(math.max);
  }

  @override
  Path getClip(Size size) {
    final radius = math.max(0.0, _maxRadius * progress);
    return Path()..addOval(Rect.fromCircle(center: origin, radius: radius));
  }

  @override
  bool shouldReclip(_CircleRevealClipper oldClipper) {
    return oldClipper.origin != origin ||
        oldClipper.progress != progress ||
        oldClipper.screenSize != screenSize;
  }
}
