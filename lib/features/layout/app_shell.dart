import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/routes/sections.dart';
import '../../core/theme/theme_controller.dart';
import '../../data/content_repository.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/mirage_logo.dart';

class AppShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  final ThemeController themeController;
  final ContentRepository repository;
  final void Function(Offset origin) onThemeToggle;

  const AppShell({
    super.key,
    required this.navigationShell,
    required this.themeController,
    required this.repository,
    required this.onThemeToggle,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with TickerProviderStateMixin {
  late final AnimationController _branchAnimation;

  StatefulNavigationShell get navigationShell => widget.navigationShell;
  ThemeController get themeController => widget.themeController;
  ContentRepository get repository => widget.repository;
  void Function(Offset origin) get onThemeToggle => widget.onThemeToggle;

  @override
  void initState() {
    super.initState();
    _branchAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _branchAnimation.dispose();
    super.dispose();
  }

  void _goBranch(int index) {
    final target = index + 1;
    final isCurrentBranch = target == navigationShell.currentIndex;
    navigationShell.goBranch(target, initialLocation: isCurrentBranch);
    // 仅真实切换分支时播放淡入动画；
    // 同一分支内返回列表（如详情页 → 列表）由路由过渡处理，避免与弹出动画重叠。
    if (!isCurrentBranch) {
      _branchAnimation.forward(from: 0);
    }
  }

  void _goHome() {
    final isHome = navigationShell.currentIndex == 0;
    navigationShell.goBranch(0, initialLocation: isHome);
    if (!isHome) {
      _branchAnimation.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      body: AnimatedBackground(
        child: Column(
          children: [
            FutureBuilder(
              future: repository.loadConfig(),
              builder: (context, snapshot) {
                final siteName = snapshot.data?.siteName ?? 'Mirage';
                return _NavBar(
                  wide: wide,
                  currentIndex: navigationShell.currentIndex,
                  onDestinationSelected: _goBranch,
                  onLogoPressed: _goHome,
                  themeController: themeController,
                  onThemeToggle: onThemeToggle,
                  siteName: siteName,
                );
              },
            ),
            Expanded(
              child: FadeTransition(
                opacity: _branchAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.015),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _branchAnimation,
                      curve: Curves.easeOut,
                    ),
                  ),
                  child: navigationShell,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 极简导航栏：无背景、无边框、无阴影，纯文字 + 图标。
class _NavBar extends StatelessWidget {
  final bool wide;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onLogoPressed;
  final ThemeController themeController;
  final void Function(Offset origin) onThemeToggle;
  final String siteName;

  const _NavBar({
    required this.wide,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.onLogoPressed,
    required this.themeController,
    required this.onThemeToggle,
    required this.siteName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: wide ? 24 : 8, vertical: 12),
      child: Row(
        children: [
          InkWell(
            onTap: onLogoPressed,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedMirageLogo(
                  size: 22,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  siteName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          for (var i = 0; i < Sections.all.length; i++)
            _NavLink(
              key: ValueKey('nav-$i'),
              icon: Sections.all[i].icon,
              selectedIcon: Sections.all[i].selectedIcon,
              label: Sections.all[i].title,
              selected: currentIndex == i + 1,
              showLabel: wide,
              onTap: () => onDestinationSelected(i),
            ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'RSS 订阅',
            icon: const Icon(Icons.rss_feed_outlined, size: 18),
            onPressed: () async {
              final uri = Uri.parse('${Uri.base.origin}/feed.xml');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.platformDefault);
              }
            },
          ),
          _ThemeToggle(
            themeController: themeController,
            onToggle: onThemeToggle,
          ),
        ],
      ),
    );
  }
}

/// 导航链接：宽屏显示文字，窄屏只显示图标。无背景无边框，点击有涟漪。
class _NavLink extends StatefulWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final bool showLabel;
  final VoidCallback onTap;

  const _NavLink({
    super.key,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.showLabel,
    required this.onTap,
  });

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = widget.selected
        ? scheme.onSurface
        : _hover
            ? scheme.onSurface
            : scheme.onSurfaceVariant;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: widget.showLabel
              ? Text(
                  widget.label,
                  style: TextStyle(
                    color: fg,
                    fontWeight: widget.selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                )
              : Icon(
                  widget.selected ? widget.selectedIcon : widget.icon,
                  size: 18,
                  color: fg,
                ),
        ),
      ),
    );
  }
}

/// 主题切换按钮。
class _ThemeToggle extends StatelessWidget {
  final ThemeController themeController;
  final void Function(Offset origin) onToggle;

  const _ThemeToggle({
    required this.themeController,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeController,
      builder: (context, mode, _) {
        final isDark = mode != ThemeMode.light;
        return IconButton(
          tooltip: isDark ? '切换为浅色模式' : '切换为深色模式',
          icon: Icon(
            isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
            size: 18,
          ),
          onPressed: () {
            final box = context.findRenderObject() as RenderBox?;
            final origin = (box != null && box.hasSize)
                ? box.localToGlobal(box.size.center(Offset.zero))
                : Offset.zero;
            onToggle(origin);
          },
        );
      },
    );
  }
}
