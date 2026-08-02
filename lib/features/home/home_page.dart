import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/content_repository.dart';

class HomePage extends StatelessWidget {
  final ContentRepository repository;

  const HomePage({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: repository.loadConfig(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('加载失败：${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final config = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 80),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 名称
                  Text(
                    config.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 角色
                  Text(
                    config.role,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 个人介绍
                  for (final paragraph in config.bio)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        paragraph,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.7,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  // Find me on
                  Text(
                    'Find me on',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final link in config.social)
                        _SocialLink(
                          name: link.name,
                          icon: link.icon,
                          onTap: () => _launch(link.url),
                        ),
                    ],
                  ),
                  if (config.email != null) ...[
                    const SizedBox(height: 12),
                    _EmailLink(
                      email: config.email!,
                      onTap: () => _launch('mailto:${config.email}'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// 社交链接：图标 + 名称常驻展示，悬停时高亮并显示底色药丸。
class _SocialLink extends StatefulWidget {
  final String name;
  final String icon;
  final VoidCallback onTap;

  const _SocialLink({
    required this.name,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_SocialLink> createState() => _SocialLinkState();
}

class _SocialLinkState extends State<_SocialLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = _hover ? scheme.onSurface : scheme.onSurfaceVariant;
    // 下划线：默认淡色，hover 时加深至文字色；粗细恒定避免布局跳动。
    final lineColor = _hover ? fg : scheme.outline.withValues(alpha: 0.6);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          // 禁用 M3 默认 hover 高亮，避免与自定义换色叠加。
          hoverColor: Colors.transparent,
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SocialIcon(icon: widget.icon, size: 16, color: fg),
                    const SizedBox(width: 8),
                    Text(
                      widget.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                // 下划线：与图标+文字同宽，画在内容底部稍下方。
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: -5,
                  child: Container(height: 1, color: lineColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 邮箱行（antfu 风格）：`Or mail me at 邮箱地址`，悬停时高亮。
class _EmailLink extends StatefulWidget {  final String email;
  final VoidCallback onTap;

  const _EmailLink({required this.email, required this.onTap});

  @override
  State<_EmailLink> createState() => _EmailLinkState();
}

class _EmailLinkState extends State<_EmailLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        // 禁用 M3 默认 hover 高亮，避免与下划线变色叠加。
        hoverColor: Colors.transparent,
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Or mail me at ',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              _AnimatedLinkText(
                text: widget.email,
                color: scheme.onSurface,
                hovered: _hover,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 社交链接图标：SVG，支持本地资源路径或 http(s) 图片地址，按给定颜色着色。
class _SocialIcon extends StatelessWidget {
  final String icon;
  final double size;
  final Color color;

  const _SocialIcon({
    required this.icon,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final filter = ColorFilter.mode(color, BlendMode.srcIn);
    final isNetwork =
        icon.startsWith('http://') || icon.startsWith('https://');
    return isNetwork
        ? SvgPicture.network(
            icon,
            width: size,
            height: size,
            colorFilter: filter,
          )
        : SvgPicture.asset(
            icon,
            width: size,
            height: size,
            colorFilter: filter,
          );
  }
}

/// antfu 风格链接文字：常驻粗体 + 常驻下划线，hover 时下划线加粗加深。
class _AnimatedLinkText extends StatelessWidget {
  final String text;
  final Color color;
  final bool hovered;

  const _AnimatedLinkText({
    required this.text,
    required this.color,
    required this.hovered,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    return Text(
      text,
      style: base.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
        decoration: TextDecoration.underline,
        decorationColor: hovered ? color : scheme.outline.withValues(alpha: 0.6),
        decorationThickness: 1,
      ),
    );
  }
}
