import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mirage/core/theme/app_theme.dart';
import 'package:mirage/widgets/markdown_view.dart';

void main() {
  testWidgets('MarkdownView renders fenced code blocks + inline code',
      (WidgetTester tester) async {
    const md = r'''
正文里有 `inline code` 和 `package:flutter/material.dart`。

```dart
void main() {
  print('hello');
}
```

无语言代码块：

```
line one
line two
```
''';
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: MarkdownView(data: md),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('inline code'), findsOneWidget);
    expect(find.text('dart'), findsOneWidget);
    expect(find.text('text'), findsOneWidget);
    expect(find.byIcon(Icons.content_copy_rounded), findsWidgets);
    expect(find.byType(SelectableText), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('single-line fenced code block also shows language bar',
      (WidgetTester tester) async {
    const md = '```yaml\nname: mirage\n```';
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(child: MarkdownView(data: md)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('yaml'), findsOneWidget);
    expect(find.byType(SelectableText), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('MarkdownView renders in dark theme without errors',
      (WidgetTester tester) async {
    const md = '```dart\nvoid main() {}\n```';
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: SingleChildScrollView(child: MarkdownView(data: md)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('code highlighting applies distinct token colors',
      (WidgetTester tester) async {
    const md = '```dart\nvoid main() {\n  print("hi");\n}\n```';
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(child: MarkdownView(data: md)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final selectable =
        tester.widget<SelectableText>(find.byType(SelectableText));
    final span = selectable.textSpan!;
    final colors = <Color?>[];
    void walk(TextSpan s) {
      if (s.style?.color != null) colors.add(s.style!.color);
      s.children?.forEach((c) => walk(c as TextSpan));
    }

    walk(span);
    expect(colors, isNotEmpty);
    expect(
      colors.where((c) => c != span.style?.color),
      isNotEmpty,
      reason: '至少一个 token 应有区别于根样式的颜色',
    );
  });

  testWidgets('dart code highlights Flutter framework types',
      (WidgetTester tester) async {
    const md = '```dart\n'
        'class MyApp extends StatelessWidget {\n'
        '  @override\n'
        '  Widget build(BuildContext context) {\n'
        '    return MaterialApp(theme: ThemeData(), home: const Scaffold(body: Text("hi")));\n'
        '  }\n'
        '}\n'
        '```';
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(child: MarkdownView(data: md)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final selectable =
        tester.widget<SelectableText>(find.byType(SelectableText));
    final colors = <Color>[];
    void walk(TextSpan s) {
      final c = s.style?.color;
      if (c != null) colors.add(c);
      s.children?.forEach((c) => walk(c as TextSpan));
    }

    walk(selectable.textSpan!);
    // 浅色主题 type 色：StatelessWidget / Widget / BuildContext / MaterialApp 等
    expect(colors, contains(const Color(0xffc18401)));
    expect(tester.takeException(), isNull);
  });

  testWidgets('default blog posts render without errors',
      (WidgetTester tester) async {
    const posts = [
      'assets/content_effective/posts/building-this-site.md',
    ];
    for (final path in posts) {
      final raw = await rootBundle.loadString(path);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: MarkdownView(data: raw),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '渲染失败: $path');
    }
  });
}
