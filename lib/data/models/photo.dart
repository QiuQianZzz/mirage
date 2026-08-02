class Photo {
  final String url;
  final String caption;
  final DateTime date;
  final String? album;

  const Photo({
    required this.url,
    required this.caption,
    required this.date,
    this.album,
  });

  factory Photo.fromMap(Map<String, dynamic> map) {
    return Photo(
      url: map['url'] as String? ?? '',
      caption: map['caption'] as String? ?? '',
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      album: map['album'] as String?,
    );
  }

  bool get isNetwork => url.startsWith('http');
}
