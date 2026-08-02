import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

import '../core/routes/sections.dart';
import 'frontmatter_parser.dart';
import 'models/blog_post.dart';
import 'models/content_settings.dart';
import 'models/essay.dart';
import 'models/photo.dart';
import 'models/project.dart';
import 'models/site_config.dart';
import 'models/skill.dart';

/// 负责加载站点配置与内容（博客 / 项目 / 技能 / 随笔 / 图片）。
/// 根据 site.yaml 中的 content.source 在本地模板与 git 子模块之间切换。
class ContentRepository {
  Future<SiteConfig>? _configFuture;
  Future<ContentSettings>? _settingsFuture;
  Future<List<BlogPost>>? _postsFuture;
  Future<List<Project>>? _projectsFuture;
  Future<List<Skill>>? _skillsFuture;
  Future<List<Essay>>? _essaysFuture;
  Future<List<Photo>>? _photosFuture;

  /// 读取基础设施配置（`assets/config/app.yaml`），决定内容来源。
  /// 缓存 Future，避免重复加载。
  Future<ContentSettings> loadContentSettings() {
    return _settingsFuture ??= () async {
      final raw = await rootBundle.loadString('assets/config/app.yaml');
      final map = loadYaml(raw) as Map;
      return ContentSettings.fromMap(_flatten(map));
    }();
  }

  /// 从生效的内容区（local_path 或 submodule_path）读取站点信息 site.yaml。
  /// 缓存 Future，避免重复加载。
  Future<SiteConfig> loadConfig() {
    return _configFuture ??= () async {
      final settings = await loadContentSettings();
      final raw = await rootBundle.loadString(
        'assets/${settings.effectiveContentPath}/site.yaml',
      );
      final map = loadYaml(raw) as Map;
      return SiteConfig.fromMap(_flatten(map));
    }();
  }

  Future<List<BlogPost>> loadPosts() {
    return _postsFuture ??= () async {
      final posts = await _loadCollection<BlogPost>(
        subdir: 'posts',
        build: BlogPost.fromMap,
      );
      posts.sort((a, b) => b.date.compareTo(a.date));
      return posts;
    }();
  }

  Future<List<Project>> loadProjects() {
    return _projectsFuture ??= () async {
      final projects = await _loadCollection<Project>(
        subdir: 'projects',
        build: Project.fromMap,
      );
      projects.sort((a, b) => b.date.compareTo(a.date));
      return projects;
    }();
  }

  Future<List<Skill>> loadSkills() {
    return _skillsFuture ??= () async {
      final paths = await _markdownPaths(subdir: 'skills');
      final skills = <Skill>[];
      for (final path in paths) {
        final raw = await rootBundle.loadString(path);
        final (map, _) = FrontmatterParser.parse(raw);
        skills.add(Skill.fromMap(map));
      }
      return skills;
    }();
  }

  Future<List<Essay>> loadEssays() {
    return _essaysFuture ??= () async {
      final essays = await _loadCollection<Essay>(
        subdir: 'essays',
        build: Essay.fromMap,
      );
      essays.sort((a, b) => b.date.compareTo(a.date));
      return essays;
    }();
  }

  Future<List<Photo>> loadPhotos() {
    return _photosFuture ??= () async {
      final settings = await loadContentSettings();
      final path = 'assets/${settings.effectiveContentPath}/photos/index.yaml';
      final raw = await rootBundle.loadString(path);
      final list = loadYaml(raw) as List;
      return list
          .map((e) => Photo.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    }();
  }

  Future<String> generateFeedXml() async {
    final config = await loadConfig();
    final posts = await loadPosts();
    final essays = await loadEssays();

    final items = <_FeedItem>[
      for (final p in posts)
        _FeedItem(
          title: p.title,
          link: Sections.blog.detailPath(p.slug),
          date: p.date,
          description: p.summary,
        ),
      for (final e in essays)
        _FeedItem(
          title: e.title,
          link: Sections.essays.detailPath(e.slug),
          date: e.date,
          description: e.summary,
        ),
    ]..sort((a, b) => b.date.compareTo(a.date));

    final buffer = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln('<rss version="2.0">')
      ..writeln('<channel>')
      ..writeln('<title>${config.title}</title>')
      ..writeln('<description>${config.bio.first}</description>')
      ..writeln('<link>${config.siteUrl ?? ''}</link>')
      ..writeln('<lastBuildDate>${items.isNotEmpty ? items.first.date.toIso8601String() : DateTime.now().toIso8601String()}</lastBuildDate>');
    for (final item in items.take(20)) {
      buffer
        ..writeln('<item>')
        ..writeln('<title>${_xmlEscape(item.title)}</title>')
        ..writeln('<link>${config.siteUrl ?? ''}${item.link}</link>')
        ..writeln('<pubDate>${item.date.toIso8601String()}</pubDate>')
        ..writeln('<description>${_xmlEscape(item.description)}</description>')
        ..writeln('</item>');
    }
    buffer
      ..writeln('</channel>')
      ..writeln('</rss>');
    return buffer.toString();
  }

  String _xmlEscape(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  /// 读取指定子目录下的全部 md 文件并构建模型。
  Future<List<T>> _loadCollection<T>({
    required String subdir,
    required T Function(String slug, Map<String, dynamic> map, String body)
        build,
  }) async {
    final paths = await _markdownPaths(subdir: subdir);
    final result = <T>[];
    for (final path in paths) {
      final raw = await rootBundle.loadString(path);
      final (map, body) = FrontmatterParser.parse(raw);
      final slug = _slugOf(path);
      result.add(build(slug, map, body));
    }
    return result;
  }

  /// 列出内容目录下指定子目录中的全部 .md 资源路径。
  Future<List<String>> _markdownPaths({required String subdir}) async {
    final settings = await loadContentSettings();
    final prefix = 'assets/${settings.effectiveContentPath}/$subdir/';
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    return manifest.listAssets().where((path) {
      return path.startsWith(prefix) && path.endsWith('.md');
    }).toList();
  }

  String _slugOf(String path) {
    final segments = path.split('/');
    final filename = segments.last;
    return filename.endsWith('.md')
        ? filename.substring(0, filename.length - 3)
        : filename;
  }

  Map<String, dynamic> _flatten(Map map) {
    final result = <String, dynamic>{};
    map.forEach((key, value) {
      if (value is Map) {
        result[key.toString()] = _flatten(value);
      } else {
        result[key.toString()] = value;
      }
    });
    return result;
  }
}

class _FeedItem {
  final String title;
  final String link;
  final DateTime date;
  final String description;

  const _FeedItem({
    required this.title,
    required this.link,
    required this.date,
    required this.description,
  });
}
