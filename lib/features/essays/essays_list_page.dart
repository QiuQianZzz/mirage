import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routes/sections.dart';
import '../../data/content_repository.dart';
import '../../data/models/essay.dart';
import '../../widgets/page_title.dart';

class EssaysListPage extends StatelessWidget {
  final ContentRepository repository;

  const EssaysListPage({super.key, required this.repository});

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Essay>>(
      future: repository.loadEssays(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('加载失败：${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final essays = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 80),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PageTitle(english: Sections.essays.watermark),
                  for (final essay in essays)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: InkWell(
                        onTap: () =>
                            context.go(Sections.essays.detailPath(essay.slug)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              essay.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(essay.date),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            if (essay.summary.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                essay.summary,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
