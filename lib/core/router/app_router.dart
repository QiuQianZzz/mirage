import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/content_repository.dart';
import '../../features/blog/blog_detail_page.dart';
import '../../features/blog/blog_list_page.dart';
import '../../features/essays/essay_detail_page.dart';
import '../../features/essays/essays_list_page.dart';
import '../../features/home/home_page.dart';
import '../../features/layout/app_shell.dart';
import '../../features/layout/not_found_page.dart';
import '../../features/photos/photos_page.dart';
import '../../features/projects/project_detail_page.dart';
import '../../features/projects/projects_page.dart';
import '../../features/skills/skills_page.dart';
import '../routes/sections.dart';
import '../theme/theme_controller.dart';

GoRouter createAppRouter(
  ContentRepository repository,
  ThemeController themeController, {
  required void Function(Offset origin) onThemeToggle,
}) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(
          navigationShell: navigationShell,
          themeController: themeController,
          repository: repository,
          onThemeToggle: onThemeToggle,
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => HomePage(repository: repository),
              ),
            ],
          ),
          for (final s in Sections.all) _sectionBranch(s, repository),
        ],
      ),
    ],
    errorBuilder: (context, state) => const NotFoundPage(),
  );
}

/// 为分区 [s] 构建一个路由分支：主列表页 + （若有）详情页。
StatefulShellBranch _sectionBranch(
  Section s,
  ContentRepository repository,
) {
  return StatefulShellBranch(
    routes: [
      GoRoute(
        path: s.path,
        builder: (context, state) {
          switch (s) {
            case Sections.blog:
              return BlogListPage(repository: repository);
            case Sections.essays:
              return EssaysListPage(repository: repository);
            case Sections.projects:
              return ProjectsPage(repository: repository);
            case Sections.photos:
              return PhotosPage(repository: repository);
            case Sections.skills:
              return SkillsPage(repository: repository);
            default:
              throw StateError('未处理的分区：$s');
          }
        },
      ),
      if (s.hasDetail)
        GoRoute(
          path: '${s.path}/:slug',
          builder: (context, state) {
            final slug = state.pathParameters['slug']!;
            switch (s) {
              case Sections.blog:
                return BlogDetailPage(repository: repository, slug: slug);
              case Sections.essays:
                return EssayDetailPage(repository: repository, slug: slug);
              case Sections.projects:
                return ProjectDetailPage(repository: repository, slug: slug);
              default:
                throw StateError('$s 没有详情页');
            }
          },
        ),
    ],
  );
}