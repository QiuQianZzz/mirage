import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routes/sections.dart';
import '../../data/content_repository.dart';
import '../../data/models/essay.dart';
import '../../widgets/markdown_view.dart';

class EssayDetailPage extends StatelessWidget {
  final ContentRepository repository;
  final String slug;

  const EssayDetailPage({
    super.key,
    required this.repository,
    required this.slug,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Essay>>(
      future: repository.loadEssays(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('加载失败：${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        Essay? essay;
        for (final e in snapshot.data!) {
          if (e.slug == slug) {
            essay = e;
            break;
          }
        }
        if (essay == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('文章不存在'),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => context.go(Sections.essays.path),
                  child: const Text('返回随笔'),
                ),
              ],
            ),
          );
        }

        final theme = Theme.of(context);
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 80),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    essay.title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(essay.date),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  if (essay.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      essay.tags.join(' / '),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  MarkdownView(data: essay.body),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${_two(date.month)}-${_two(date.day)}';
  }

  String _two(int v) => v.toString().padLeft(2, '0');
}
