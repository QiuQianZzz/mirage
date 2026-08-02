List<String> toStringList(dynamic value) {
  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }
  if (value is String && value.isNotEmpty) {
    return value.split(',').map((e) => e.trim()).toList();
  }
  return const [];
}
