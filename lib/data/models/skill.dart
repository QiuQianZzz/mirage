class Skill {
  final String category;
  final String icon;
  final List<SkillItem> items;

  const Skill({
    required this.category,
    required this.icon,
    required this.items,
  });

  factory Skill.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'];
    final items = <SkillItem>[];
    if (rawItems is List) {
      for (final raw in rawItems) {
        if (raw is Map) {
          items.add(SkillItem.fromMap(Map<String, dynamic>.from(raw)));
        }
      }
    }
    return Skill(
      category: map['category'] as String? ?? '未分类',
      icon: map['icon'] as String? ?? 'star',
      items: items,
    );
  }
}

class SkillItem {
  final String name;
  final int level;

  const SkillItem({required this.name, required this.level});

  factory SkillItem.fromMap(Map<String, dynamic> map) {
    final raw = map['level'];
    return SkillItem(
      name: map['name'] as String? ?? '',
      level: raw is int ? raw : int.tryParse(raw?.toString() ?? '') ?? 0,
    );
  }
}
