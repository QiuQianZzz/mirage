import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routes/sections.dart';
import '../../data/content_repository.dart';
import '../../data/models/blog_post.dart';
import '../../widgets/page_title.dart';

class BlogListPage extends StatelessWidget {
  final ContentRepository repository;

  const BlogListPage({super.key, required this.repository});

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BlogPost>>(
      future: repository.loadPosts(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('加载失败：${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final posts = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 80),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PageTitle(english: Sections.blog.watermark),
                  for (final post in posts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: InkWell(
                        onTap: () =>
                            context.go(Sections.blog.detailPath(post.slug)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(post.date),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            if (post.summary.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                post.summary,
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
