import 'string_list.dart';

class Project {
  final String slug;
  final String name;
  final String description;
  final List<String> tags;
  final String? repo;
  final String? demo;
  final DateTime date;
  final bool featured;
  final String body;

  const Project({
    required this.slug,
    required this.name,
    required this.description,
    required this.tags,
    required this.repo,
    required this.demo,
    required this.date,
    required this.featured,
    required this.body,
  });

  factory Project.fromMap(String slug, Map<String, dynamic> map, String body) {
    return Project(
      slug: slug,
      name: map['name'] as String? ?? slug,
      description: map['description'] as String? ?? '',
      tags: toStringList(map['tags']),
      repo: map['repo'] as String?,
      demo: map['demo'] as String?,
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      featured: map['featured'] as bool? ?? false,
      body: body,
    );
  }
}
