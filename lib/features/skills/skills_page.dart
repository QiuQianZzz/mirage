import 'package:flutter/material.dart';

import '../../core/routes/sections.dart';
import '../../data/content_repository.dart';
import '../../data/models/skill.dart';
import '../../widgets/page_title.dart';

class SkillsPage extends StatelessWidget {
  final ContentRepository repository;

  const SkillsPage({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Skill>>(
      future: repository.loadSkills(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('加载失败：${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final skills = snapshot.data!;
        final theme = Theme.of(context);

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 80),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PageTitle(english: Sections.skills.watermark),
                  const SizedBox(height: 24),
                  for (final skill in skills) ...[
                    _SkillCard(skill: skill),
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 8),
                  _LevelLegend(theme: theme),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 单个技能分类卡片：图标 + 分类名 + 技能分段条。
class _SkillCard extends StatelessWidget {
  final Skill skill;

  const _SkillCard({required this.skill});

  IconData get _icon {
    switch (skill.icon) {
      case 'widget':
        return Icons.widgets_outlined;
      case 'code':
        return Icons.code;
      case 'science':
        return Icons.science_outlined;
      case 'git':
        return Icons.merge;
      case 'tool':
        return Icons.handyman_outlined;
      default:
        return Icons.star_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_icon, size: 20, color: scheme.primary),
              ),
              const SizedBox(width: 12),
              Text(
                skill.category,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final item in skill.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SkillItemRow(item: item),
            ),
        ],
      ),
    );
  }
}

/// 技能项：左侧名称，右侧 5 段等级条。
class _SkillItemRow extends StatelessWidget {
  final SkillItem item;

  const _SkillItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final level = item.level.clamp(0, 5);

    return Row(
      children: [
        Expanded(
          child: Text(
            item.name,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(width: 12),
        for (var i = 0; i < 5; i++)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Container(
              width: 22,
              height: 5,
              decoration: BoxDecoration(
                color: i < level
                    ? scheme.primary
                    : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
      ],
    );
  }
}

/// 底部等级说明。
class _LevelLegend extends StatelessWidget {
  final ThemeData theme;

  const _LevelLegend({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '等级：1 了解 · 2 熟悉 · 3 掌握 · 4 精通 · 5 专家',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
      ),
    );
  }
}