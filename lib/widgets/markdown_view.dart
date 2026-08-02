import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:highlight/highlight.dart' as hl;
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

/// Markdown 正文渲染（与站点配色一致的样式）。
class MarkdownView extends StatelessWidget {
  final String data;

  const MarkdownView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return MarkdownBody(
      data: data,
      onTapLink: (text, href, title) async {
        final uri = Uri.tryParse(href ?? '');
        if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
          return;
        }
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      builders: {
        'pre': _CodeBlockBuilder(),
      },
      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
        blockSpacing: 16,
        h1: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
        h1Padding: const EdgeInsets.only(top: 8, bottom: 4),
        h2: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
        h2Padding: const EdgeInsets.only(top: 8, bottom: 4),
        h3: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
        h3Padding: const EdgeInsets.only(top: 8, bottom: 4),
        h4: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        h4Padding: const EdgeInsets.only(top: 8, bottom: 4),
        h5: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        h5Padding: const EdgeInsets.only(top: 8, bottom: 4),
        h6: theme.textTheme.titleSmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        h6Padding: const EdgeInsets.only(top: 8, bottom: 4),
        p: theme.textTheme.bodyLarge?.copyWith(height: 1.75),
        pPadding: EdgeInsets.zero,
        a: TextStyle(color: scheme.primary),
        em: const TextStyle(fontStyle: FontStyle.italic),
        strong: const TextStyle(fontWeight: FontWeight.bold),
        listIndent: 24,
        listBulletPadding: const EdgeInsets.only(right: 8),
        blockquote: theme.textTheme.bodyLarge?.copyWith(
          height: 1.75,
          color: scheme.onSurfaceVariant,
        ),
        blockquoteDecoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          border: Border(
            left: BorderSide(color: scheme.primary, width: 3),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        blockquotePadding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        code: TextStyle(
          color: scheme.onSurfaceVariant,
          backgroundColor: scheme.surfaceContainerHighest,
          fontFamily: 'monospace',
          fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 14) * 0.9,
          height: 1.5,
        ),
        codeblockPadding: EdgeInsets.zero,
        codeblockDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
        ),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: scheme.outlineVariant),
          ),
        ),
        tableHead: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        tableBody: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
        tableCellsPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        tableBorder: TableBorder.all(
          color: scheme.outlineVariant,
          width: 1,
        ),
      ),
      selectable: true,
    );
  }
}

/// 代码块渲染：多行显示语言栏 + 复制按钮，文本可选中复制；单行紧凑显示。
class _CodeBlockBuilder extends MarkdownElementBuilder {
  _CodeBlockBuilder();

  @override
  bool isBlockElement() => true;

  /// 吞掉 `pre` 内的文本，但返回非空占位。flutter_markdown 需要内联容器非空
  /// 才会在块结束时清空内部状态（否则 build 末尾 `_inlines.isEmpty` 断言失败）；
  /// 该占位会被合并进 pre 块，而 pre 块内容已被 [_CodeBlock] 整体替换、不会渲染。
  @override
  Widget? visitText(md.Text text, TextStyle? preferredStyle) =>
      const SizedBox.shrink();

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final code = element.textContent.replaceAll(RegExp(r'\n+$'), '');
    String language = '';
    final children = element.children;
    if (children != null && children.isNotEmpty) {
      final first = children.first;
      if (first is md.Element) {
        final cls = (first.attributes['class'] ?? '').trim();
        final match = RegExp(r'^(?:language|lang)-(.*)$').firstMatch(cls);
        if (match != null) {
          language = _normalizeLanguage(match[1]!);
        }
      }
    }
    return _CodeBlock(code: code, language: language);
  }
}

/// 常见语言的别名归一化，保证高亮命中。
/// （highlight 包本身已内置 js/jsx/ts/html/docker/sh 等别名，这里是兜底。）
const Map<String, String> _languageAliases = {
  'py': 'python',
  'ps1': 'powershell',
  'ps': 'powershell',
  'shell': 'bash',
  'c++': 'cpp',
  'c#': 'cs',
  'gql': 'graphql',
  'docker': 'dockerfile',
  'sh': 'bash',
  'yml': 'yaml',
  'md': 'markdown',
  'vue': 'vue',
};

/// 浅色主题：Atom One Light 风格配色，覆盖 highlight 常见输出类名。
const Map<String, TextStyle> _lightCodeTheme = {
  'root': TextStyle(
    color: Color(0xff383a42),
    backgroundColor: Color(0xfff6f8fa),
  ),
  'comment': TextStyle(color: Color(0xffa0a1a7), fontStyle: FontStyle.italic),
  'quote': TextStyle(color: Color(0xffa0a1a7), fontStyle: FontStyle.italic),
  'doctag': TextStyle(color: Color(0xffa626a4)),
  'keyword': TextStyle(color: Color(0xffa626a4)),
  'formula': TextStyle(color: Color(0xffa626a4)),
  'meta': TextStyle(color: Color(0xffa0a1a7)),
  'literal': TextStyle(color: Color(0xff986801)),
  'number': TextStyle(color: Color(0xff986801)),
  'symbol': TextStyle(color: Color(0xff986801)),
  'bullet': TextStyle(color: Color(0xff986801)),
  'char': TextStyle(color: Color(0xff986801)),
  'string': TextStyle(color: Color(0xff50a14f)),
  'regexp': TextStyle(color: Color(0xff50a14f)),
  'meta-string': TextStyle(color: Color(0xff50a14f)),
  'addition': TextStyle(color: Color(0xff50a14f)),
  'variable': TextStyle(color: Color(0xffe45649)),
  'template-variable': TextStyle(color: Color(0xffe45649)),
  'attribute': TextStyle(color: Color(0xffe45649)),
  'attr': TextStyle(color: Color(0xffe45649)),
  'tag': TextStyle(color: Color(0xffe45649)),
  'name': TextStyle(color: Color(0xffe45649)),
  'selector-tag': TextStyle(color: Color(0xffe45649)),
  'deletion': TextStyle(color: Color(0xffe45649)),
  'title': TextStyle(color: Color(0xffe45649), fontWeight: FontWeight.w600),
  'section': TextStyle(color: Color(0xffe45649), fontWeight: FontWeight.w600),
  'selector-id': TextStyle(color: Color(0xffe45649)),
  'type': TextStyle(color: Color(0xffc18401)),
  'class': TextStyle(color: Color(0xffc18401)),
  'title-class': TextStyle(color: Color(0xffc18401)),
  'built_in': TextStyle(color: Color(0xffc18401)),
  'selector-class': TextStyle(color: Color(0xffc18401)),
  'function': TextStyle(color: Color(0xff4078f2)),
  'title-function': TextStyle(color: Color(0xff4078f2)),
  'property': TextStyle(color: Color(0xff4078f2)),
  'operator': TextStyle(color: Color(0xff0184bc)),
  'selector-attr': TextStyle(color: Color(0xff50a14f)),
  'selector-pseudo': TextStyle(color: Color(0xff0184bc)),
  'link': TextStyle(color: Color(0xff0184bc)),
  'params': TextStyle(color: Color(0xff383a42)),
  'emphasis': TextStyle(fontStyle: FontStyle.italic),
  'strong': TextStyle(fontWeight: FontWeight.bold),
};

/// 深色主题：Atom One Dark 风格配色，覆盖 highlight 常见输出类名。
const Map<String, TextStyle> _darkCodeTheme = {
  'root': TextStyle(
    color: Color(0xffabb2bf),
    backgroundColor: Color(0xff282c34),
  ),
  'comment': TextStyle(color: Color(0xff5c6370), fontStyle: FontStyle.italic),
  'quote': TextStyle(color: Color(0xff5c6370), fontStyle: FontStyle.italic),
  'doctag': TextStyle(color: Color(0xffc678dd)),
  'keyword': TextStyle(color: Color(0xffc678dd)),
  'formula': TextStyle(color: Color(0xffc678dd)),
  'meta': TextStyle(color: Color(0xff5c6370)),
  'literal': TextStyle(color: Color(0xffd19a66)),
  'number': TextStyle(color: Color(0xffd19a66)),
  'symbol': TextStyle(color: Color(0xffd19a66)),
  'bullet': TextStyle(color: Color(0xffd19a66)),
  'char': TextStyle(color: Color(0xffd19a66)),
  'string': TextStyle(color: Color(0xff98c379)),
  'regexp': TextStyle(color: Color(0xff98c379)),
  'meta-string': TextStyle(color: Color(0xff98c379)),
  'addition': TextStyle(color: Color(0xff98c379)),
  'variable': TextStyle(color: Color(0xffe06c75)),
  'template-variable': TextStyle(color: Color(0xffe06c75)),
  'attribute': TextStyle(color: Color(0xffe06c75)),
  'attr': TextStyle(color: Color(0xffe06c75)),
  'tag': TextStyle(color: Color(0xffe06c75)),
  'name': TextStyle(color: Color(0xffe06c75)),
  'selector-tag': TextStyle(color: Color(0xffe06c75)),
  'deletion': TextStyle(color: Color(0xffe06c75)),
  'title': TextStyle(color: Color(0xffe06c75), fontWeight: FontWeight.w600),
  'section': TextStyle(color: Color(0xffe06c75), fontWeight: FontWeight.w600),
  'selector-id': TextStyle(color: Color(0xffe06c75)),
  'type': TextStyle(color: Color(0xffe5c07b)),
  'class': TextStyle(color: Color(0xffe5c07b)),
  'title-class': TextStyle(color: Color(0xffe5c07b)),
  'built_in': TextStyle(color: Color(0xffe5c07b)),
  'selector-class': TextStyle(color: Color(0xffe5c07b)),
  'function': TextStyle(color: Color(0xff61afef)),
  'title-function': TextStyle(color: Color(0xff61afef)),
  'property': TextStyle(color: Color(0xff61afef)),
  'operator': TextStyle(color: Color(0xff56b6c2)),
  'selector-attr': TextStyle(color: Color(0xff98c379)),
  'selector-pseudo': TextStyle(color: Color(0xff56b6c2)),
  'link': TextStyle(color: Color(0xff56b6c2)),
  'params': TextStyle(color: Color(0xffabb2bf)),
  'emphasis': TextStyle(fontStyle: FontStyle.italic),
  'strong': TextStyle(fontWeight: FontWeight.bold),
};

String _normalizeLanguage(String raw) {
  final name = raw.trim().toLowerCase();
  if (name.isEmpty) return '';
  return _languageAliases[name] ?? name;
}

class _CodeBlock extends StatefulWidget {
  final String code;
  final String language;

  const _CodeBlock({required this.code, required this.language});

  @override
  State<_CodeBlock> createState() => _CodeBlockState();
}

class _CodeBlockState extends State<_CodeBlock> {
  bool _copied = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    setState(() => _copied = true);
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final codeTheme = isDark ? _darkCodeTheme : _lightCodeTheme;
    final rootStyle = codeTheme['root']!;
    final bg = rootStyle.backgroundColor!;
    final fg = rootStyle.color!;
    final codeStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 13.5,
      height: 1.6,
      letterSpacing: 0.5,
      wordSpacing: 0,
      color: fg,
    );

    final Widget codeText = SelectableText.rich(
      TextSpan(
        style: codeStyle,
        children: _highlightToSpans(
          widget.code,
          widget.language,
          codeTheme,
        ),
      ),
    );

    final headerBg = isDark
        ? Color.lerp(bg, Colors.black, 0.4)!
        : Color.lerp(bg, Colors.black, 0.06)!;
    final headerFg = isDark ? Color.lerp(fg, Colors.white, 0.2)! : fg;

    return Container(
      width: double.infinity,
      color: bg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: headerBg,
              border: Border(
                bottom: BorderSide(color: fg.withValues(alpha: 0.18)),
              ),
            ),
            padding: const EdgeInsets.only(left: 16, right: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.language.isEmpty ? 'text' : widget.language,
                    style: TextStyle(
                      color: headerFg.withValues(alpha: 0.9),
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _copy,
                  icon: Icon(
                    _copied ? Icons.check_rounded : Icons.content_copy_rounded,
                    size: 17,
                  ),
                  color: headerFg.withValues(alpha: 0.85),
                  tooltip: '复制代码',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 38,
                    minHeight: 38,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: codeText,
          ),
        ],
      ),
    );
  }
}

/// 无语言标签时自动检测高亮的代码长度上限（避免对超长文本做全语言解析）。
const int _kAutoDetectMaxLength = 400;

/// Dart 核心与 Flutter 框架常见类型名。highlight 内置 dart 语法未收录这些，
/// 这里在渲染时把它们按 `type` 配色补上，让 Flutter 代码高亮更直观。
const Set<String> _dartTypeNames = {
  // Dart 核心
  'Object', 'String', 'num', 'int', 'double', 'bool', 'void', 'Never', 'Null',
  'dynamic', 'Future', 'Stream', 'List', 'Set', 'Map', 'Iterable', 'Iterator',
  'Record', 'Function', 'Symbol', 'Type', 'Uri', 'RegExp', 'DateTime',
  'Duration', 'Stopwatch', 'Pattern', 'Match', 'Completer', 'StreamController',
  'StreamSubscription', 'Zone', 'Timer', 'Random', 'BigInt', 'Enum',
  'StackTrace', 'Isolate', 'Comparable', 'Key',
  // Flutter / Material
  'Widget', 'StatelessWidget', 'StatefulWidget', 'State', 'BuildContext',
  'GlobalKey', 'ValueKey', 'Element', 'RenderObject', 'RenderBox',
  'Color', 'Colors', 'TextStyle', 'TextTheme', 'ThemeData', 'Theme',
  'MaterialApp', 'Material', 'Scaffold', 'AppBar', 'Navigator', 'Route',
  'ModalRoute', 'PageRoute', 'InkWell', 'GestureDetector', 'Text',
  'RichText', 'TextSpan', 'Image', 'Icon', 'IconData', 'IconButton',
  'TextButton', 'ElevatedButton', 'OutlinedButton', 'FloatingActionButton',
  'Card', 'Container', 'Padding', 'Center', 'Align', 'Column', 'Row',
  'Stack', 'IndexedStack', 'ListView', 'GridView', 'Wrap', 'Flex',
  'Expanded', 'Flexible', 'Spacer', 'SizedBox', 'ConstrainedBox',
  'AspectRatio', 'FractionallySizedBox', 'FittedBox', 'AnimatedContainer',
  'AnimatedBuilder', 'AnimatedSwitcher', 'FadeTransition',
  'ScaleTransition', 'SlideTransition', 'Opacity', 'Transform', 'ClipPath',
  'ClipRRect', 'ClipRect', 'DecoratedBox', 'Positioned', 'Baseline',
  'IntrinsicWidth', 'IntrinsicHeight', 'SingleChildScrollView', 'ScrollView',
  'CustomScrollView', 'SliverList', 'SliverGrid', 'SliverAppBar',
  'RefreshIndicator', 'TabBar', 'TabBarView', 'Tab', 'DefaultTabController',
  'Drawer', 'BottomNavigationBar', 'NavigationRail', 'NavigationBar',
  'Chip', 'Switch', 'Checkbox', 'Radio', 'Slider', 'ProgressIndicator',
  'CircularProgressIndicator', 'LinearProgressIndicator', 'SnackBar',
  'Dialog', 'AlertDialog', 'BottomSheet', 'Tooltip', 'PopupMenuButton',
  'Divider', 'VerticalDivider', 'Hero', 'ValueListenableBuilder',
  'ValueNotifier', 'ChangeNotifier', 'ValueChanged', 'VoidCallback',
  'TextEditingController', 'ScrollController', 'TabController', 'Animation',
  'AnimationController', 'TickerProviderStateMixin',
  'SingleTickerProviderStateMixin', 'CurvedAnimation', 'Curves',
  'EdgeInsets', 'EdgeInsetsGeometry', 'Border', 'BorderSide', 'BorderRadius',
  'BorderRadiusGeometry', 'BoxConstraints', 'BoxDecoration', 'BoxShadow',
  'Alignment', 'AlignmentGeometry', 'Matrix4', 'Offset', 'Rect', 'Size',
  'FontWeight', 'FontStyle', 'TextAlign', 'TextOverflow', 'TextDirection',
  'MainAxisAlignment', 'MainAxisSize', 'CrossAxisAlignment',
  'WrapAlignment', 'StackFit', 'Clip', 'BoxFit', 'BoxShape', 'BlendMode',
  'FilterQuality', 'ImageProvider', 'AssetImage', 'NetworkImage',
  'InputDecoration', 'OutlineInputBorder', 'UnderlineInputBorder', 'Form',
  'FocusNode', 'TextInputAction', 'TextInputType', 'Locale',
  'Localizations', 'Directionality', 'MediaQuery', 'MediaQueryData',
  'WidgetsBinding', 'WidgetsFlutterBinding', 'ScrollPhysics',
  'AlwaysScrollableScrollPhysics', 'BouncingScrollPhysics', 'TextScaler',
  'SelectionArea', 'SelectableText', 'SelectableRegion', 'RepaintBoundary',
  'RenderRepaintBoundary', 'RawImage', 'CustomClipper', 'Path',
  'ColorScheme', 'IconTheme', 'WidgetSpan', 'TextSelection', 'WidgetState',
  // go_router
  'GoRouter', 'GoRoute', 'GoRouterState', 'NavigatorState',
};

final RegExp _dartIdentifierRe = RegExp(r'[A-Za-z_$][A-Za-z0-9_$]*');

/// 把 highlight 未识别的 Dart / Flutter 类型标识符补上 `type` 配色。
/// 只处理没有样式、没有子节点的纯文本 span，避免覆盖关键字 / 字符串。
List<TextSpan> _applyDartTypeHighlight(
  List<TextSpan> spans,
  TextStyle? typeStyle,
) {
  if (typeStyle == null) return spans;
  final out = <TextSpan>[];
  for (final span in spans) {
    if (span.children != null || span.style != null || span.text == null) {
      out.add(span);
      continue;
    }
    out.addAll(_colorDartTypesInText(span.text!, typeStyle));
  }
  return out;
}

List<TextSpan> _colorDartTypesInText(String text, TextStyle typeStyle) {
  var last = 0;
  final spans = <TextSpan>[];
  for (final match in _dartIdentifierRe.allMatches(text)) {
    final word = match[0]!;
    if (!_dartTypeNames.contains(word)) continue;
    if (match.start > last) {
      spans.add(TextSpan(text: text.substring(last, match.start)));
    }
    spans.add(TextSpan(text: word, style: typeStyle));
    last = match.end;
  }
  if (spans.isEmpty) return <TextSpan>[TextSpan(text: text)];
  if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
  return spans;
}

/// 把 highlight.js 的解析结果转成带语法颜色的 [TextSpan]，供可选中文本使用。
List<TextSpan> _highlightToSpans(
  String code,
  String language,
  Map<String, TextStyle> theme,
) {
  final bool isDart = language == 'dart';
  final bool autoDetect =
      language.isEmpty && code.length <= _kAutoDetectMaxLength;
  final String effectiveLanguage =
      language.isEmpty ? (autoDetect ? '' : 'plaintext') : language;

  final List<hl.Node> nodes;
  try {
    final result = autoDetect
        ? hl.highlight.parse(code, autoDetection: true)
        : hl.highlight.parse(code, language: effectiveLanguage);
    nodes = result.nodes ?? const <hl.Node>[];
  } catch (_) {
    return <TextSpan>[TextSpan(text: code)];
  }
  var spans = _nodeToSpans(nodes, theme);
  if (isDart) {
    spans = _applyDartTypeHighlight(spans, theme['type']);
  }
  return _mergeAdjacentSpans(spans);
}

/// 相邻且样式相同的文本 span 合并，减少 span 数量、提高排版性能。
/// theme 中同一 class 对应同一个 [TextStyle] 实例，可直接用 `==` 比较。
List<TextSpan> _mergeAdjacentSpans(List<TextSpan> spans) {
  if (spans.length < 2) return spans;
  final merged = <TextSpan>[];
  for (final span in spans) {
    final last = merged.isNotEmpty ? merged.last : null;
    if (last != null &&
        last.children == null &&
        span.children == null &&
        last.style == span.style) {
      merged[merged.length - 1] = TextSpan(
        text: (last.text ?? '') + (span.text ?? ''),
        style: last.style,
      );
    } else {
      merged.add(span);
    }
  }
  return merged;
}

List<TextSpan> _nodeToSpans(
  List<hl.Node> nodes,
  Map<String, TextStyle> theme,
) {
  final spans = <TextSpan>[];
  for (final node in nodes) {
    if (node.value != null) {
      spans.add(
        TextSpan(
          text: node.value,
          style: node.className == null ? null : theme[node.className],
        ),
      );
    } else if (node.children != null) {
      spans.add(
        TextSpan(
          style: node.className == null ? null : theme[node.className],
          children: _nodeToSpans(node.children!, theme),
        ),
      );
    }
  }
  return spans;
}

