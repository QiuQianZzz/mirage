import 'package:flutter/material.dart';

/// 站点品牌种子色：青蓝色系。
const Color kSeedColor = Color(0xFF006A6A);

/// 全局页面过渡：一层不透明底色立即盖住下层页面，内容再在其上淡入 + 轻微上移。
///
/// 这样过渡期间旧页面不会与新页面同屏，文字不会重叠；同时保留淡入效果。
class OpaqueSlideTransitionsBuilder extends PageTransitionsBuilder {
  const OpaqueSlideTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: Theme.of(context).scaffoldBackgroundColor),
        FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.02),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        ),
      ],
    );
  }
}

abstract final class AppTheme {
  static final ThemeData _light = _base(
    ColorScheme.fromSeed(seedColor: kSeedColor),
  );

  static final ThemeData _dark = _base(
    ColorScheme.fromSeed(
      seedColor: kSeedColor,
      brightness: Brightness.dark,
    ),
  );

  static ThemeData light() => _light;

  static ThemeData dark() => _dark;

  static ThemeData _base(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Noto Sans SC',
      fontFamilyFallback: const ['Roboto', 'sans-serif'],
      scaffoldBackgroundColor: scheme.surface,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: OpaqueSlideTransitionsBuilder(),
          TargetPlatform.iOS: OpaqueSlideTransitionsBuilder(),
          TargetPlatform.macOS: OpaqueSlideTransitionsBuilder(),
          TargetPlatform.windows: OpaqueSlideTransitionsBuilder(),
          TargetPlatform.linux: OpaqueSlideTransitionsBuilder(),
          TargetPlatform.fuchsia: OpaqueSlideTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      chipTheme: const ChipThemeData(),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.secondaryContainer,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.secondaryContainer,
      ),
    );
  }
}
