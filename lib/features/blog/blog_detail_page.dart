import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routes/sections.dart';
import '../../data/content_repository.dart';
import '../../data/models/blog_post.dart';
import '../../widgets/markdown_view.dart';

class BlogDetailPage extends StatelessWidget {
  final ContentRepository repository;
  final String slug;

  const BlogDetailPage({
    super.key,
    required this.repository,
    required this.slug,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BlogPost>>(
      future: repository.loadPosts(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('加载失败：${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        BlogPost? post;
        for (final p in snapshot.data!) {
          if (p.slug == slug) {
            post = p;
            break;
          }
        }
        if (post == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('文章不存在'),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => context.go(Sections.blog.path),
                  child: const Text('返回博客'),
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
                  SelectableText(
                    post.title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    _formatDate(post.date),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  if (post.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SelectableText(
                      post.tags.join(' / '),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 24),
                  MarkdownView(data: post.body),
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
