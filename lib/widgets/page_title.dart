import 'package:flutter/material.dart';

/// 页面标题：大号英文半透明水印，纵向下缘渐隐淡出。
///
/// 英文整体约 15% 半透明，视觉上贴近背景水印，但仍是参与布局的内容元素。
class PageTitle extends StatelessWidget {
  /// 大号英文水印词（装饰用，如 BLOG / PROJECTS）。
  final String english;

  const PageTitle({
    super.key,
    required this.english,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.onSurface;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              c.withValues(alpha: 0.15),
              c.withValues(alpha: 0.15),
              c.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(bounds),
          child: Text(
            english,
            style: theme.textTheme.displayMedium?.copyWith(
              fontSize: 44,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              height: 1.05,
              color: c,
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}