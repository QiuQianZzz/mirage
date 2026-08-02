import 'string_list.dart';

class Essay {
  final String slug;
  final String title;
  final DateTime date;
  final List<String> tags;
  final String summary;
  final String body;

  const Essay({
    required this.slug,
    required this.title,
    required this.date,
    required this.tags,
    required this.summary,
    required this.body,
  });

  factory Essay.fromMap(String slug, Map<String, dynamic> map, String body) {
    return Essay(
      slug: slug,
      title: map['title'] as String? ?? slug,
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      tags: toStringList(map['tags']),
      summary: map['summary'] as String? ?? '',
      body: body,
    );
  }
}
