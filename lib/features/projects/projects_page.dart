import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routes/sections.dart';
import '../../data/content_repository.dart';
import '../../data/models/project.dart';
import '../../widgets/page_title.dart';

class ProjectsPage extends StatelessWidget {
  final ContentRepository repository;

  const ProjectsPage({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Project>>(
      future: repository.loadProjects(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('加载失败：${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final projects = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 80),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PageTitle(english: Sections.projects.watermark),
                  for (final project in projects)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: InkWell(
                        onTap: () => context
                            .go(Sections.projects.detailPath(project.slug)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (project.description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                project.description,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            if (project.tags.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                project.tags.join(' / '),
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
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
