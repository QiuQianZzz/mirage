import 'package:yaml/yaml.dart';

/// 解析 YAML frontmatter（--- 包裹的头部）与正文。
class FrontmatterParser {
  /// 返回 (frontmatterMap, body)。
  static (Map<String, dynamic>, String) parse(String source) {
    final lines = source.split('\n');
    if (lines.isEmpty || lines.first.trim() != '---') {
      return (const {}, source.trim());
    }

    var end = -1;
    for (var i = 1; i < lines.length; i++) {
      if (lines[i].trim() == '---') {
        end = i;
        break;
      }
    }
    if (end == -1) {
      return (const {}, source.trim());
    }

    final yamlText = lines.sublist(1, end).join('\n');
    final body = lines.sublist(end + 1).join('\n').trim();

    Map<String, dynamic> map = const {};
    try {
      final parsed = loadYaml(yamlText);
      if (parsed is Map) {
        map = _flatten(parsed);
      }
    } catch (_) {
      // 解析失败时按空 frontmatter 处理
    }
    return (map, body);
  }

  static Map<String, dynamic> _flatten(Map map) {
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
