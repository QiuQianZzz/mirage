import 'string_list.dart';

class BlogPost {
  final String slug;
  final String title;
  final DateTime date;
  final List<String> tags;
  final String summary;
  final bool featured;
  final String body;

  const BlogPost({
    required this.slug,
    required this.title,
    required this.date,
    required this.tags,
    required this.summary,
    required this.featured,
    required this.body,
  });

  factory BlogPost.fromMap(String slug, Map<String, dynamic> map, String body) {
    return BlogPost(
      slug: slug,
      title: map['title'] as String? ?? slug,
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      tags: toStringList(map['tags']),
      summary: map['summary'] as String? ?? '',
      featured: map['featured'] as bool? ?? false,
      body: body,
    );
  }
}
