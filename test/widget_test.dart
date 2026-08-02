import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mirage/app.dart';
import 'package:mirage/core/router/app_router.dart';
import 'package:mirage/core/theme/app_theme.dart';
import 'package:mirage/core/theme/theme_controller.dart';
import 'package:mirage/data/content_repository.dart';
import 'package:mirage/features/blog/blog_detail_page.dart';
import 'package:mirage/features/blog/blog_list_page.dart';

void main() {
  testWidgets('App renders navigation shell on narrow screens', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    expect(find.text('Mirage'), findsWidgets);
    // 窄屏只显示图标，不显示文字标签
    expect(find.byIcon(Icons.article_outlined), findsWidgets);
    expect(find.byIcon(Icons.folder_outlined), findsWidgets);
    expect(find.byIcon(Icons.memory), findsWidgets);
  });

  testWidgets('App renders text labels on wide screens', (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(const App());
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Mirage'), findsWidgets);
    expect(find.text('博客'), findsWidgets);
    expect(find.text('随笔'), findsWidgets);
    expect(find.text('项目'), findsWidgets);
    expect(find.text('拾光'), findsWidgets);
    expect(find.text('技艺'), findsWidgets);
  });

  testWidgets('nav switches branches and navigates list<->detail', (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    // 点击导航栏「博客」进入博客列表分支
    await tester.tap(find.byKey(const ValueKey('nav-0')));
    await tester.pumpAndSettle();
    expect(find.byType(BlogListPage), findsOneWidget);

    // 直接在路由层面从列表进入详情、再返回列表
    final repository = ContentRepository();
    final themeController = ThemeController(ThemeMode.light);
    addTearDown(themeController.dispose);
    final router = createAppRouter(
      repository,
      themeController,
      onThemeToggle: (_) {},
    );
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    router.go('/blog/hello-mirage');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(BlogDetailPage), findsOneWidget);

    router.go('/blog');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(BlogListPage), findsOneWidget);
  });
}
