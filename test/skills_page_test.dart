import 'package:flutter_test/flutter_test.dart';
import 'package:mirage/data/frontmatter_parser.dart';
import 'package:mirage/data/models/skill.dart';

void main() {
  test('Skill.fromMap 能从 YAML frontmatter 解析出分类与技能项', () {
    const source = '''
---
category: 开发语言
icon: code
items:
  - name: Dart
    level: 5
  - name: TypeScript
    level: 4
---
''';
    final (map, _) = FrontmatterParser.parse(source);
    final skill = Skill.fromMap(map);

    expect(skill.category, '开发语言');
    expect(skill.icon, 'code');
    expect(skill.items, hasLength(2));
    expect(skill.items.first.name, 'Dart');
    expect(skill.items.first.level, 5);
  });
}