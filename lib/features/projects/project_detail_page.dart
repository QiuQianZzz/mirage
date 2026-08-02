import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/routes/sections.dart';
import '../../data/content_repository.dart';
import '../../data/models/project.dart';
import '../../widgets/markdown_view.dart';

class ProjectDetailPage extends StatelessWidget {
  final ContentRepository repository;
  final String slug;

  const ProjectDetailPage({
    super.key,
    required this.repository,
    required this.slug,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Project>>(
      future: repository.loadProjects(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('加载失败：${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        Project? project;
        for (final p in snapshot.data!) {
          if (p.slug == slug) {
            project = p;
            break;
          }
        }
        if (project == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('项目不存在'),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => context.go(Sections.projects.path),
                  child: const Text('返回项目'),
                ),
              ],
            ),
          );
        }

        final theme = Theme.of(context);
        final repo = project.repo;
        final demo = project.demo;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 80),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    project.description,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (project.tags.isNotEmpty)
                    Text(
                      project.tags.join(' / '),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    children: [
                      if (repo != null)
                        InkWell(
                          onTap: () => _launch(repo),
                          child: const Text('仓库'),
                        ),
                      if (demo != null)
                        InkWell(
                          onTap: () => _launch(demo),
                          child: const Text('在线演示'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  MarkdownView(data: project.body),
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
