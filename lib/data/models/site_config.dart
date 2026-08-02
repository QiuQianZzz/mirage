class SiteConfig {
  final String title;
  final String siteName;
  final String author;
  final String role;
  final String tagline;
  final String description;
  final String? avatar;
  final String? email;
  final String? siteUrl;
  final List<SocialLink> social;
  final List<String> bio;

  const SiteConfig({
    required this.title,
    required this.siteName,
    required this.author,
    required this.role,
    required this.tagline,
    required this.description,
    required this.avatar,
    required this.email,
    this.siteUrl,
    required this.social,
    required this.bio,
  });

  factory SiteConfig.fromMap(Map<String, dynamic> map) {
    final site = map['site'] as Map<String, dynamic>? ?? const {};
    final social = site['social'] as List? ?? const [];

    return SiteConfig(
      title: site['title'] as String? ?? 'Mirage',
      siteName: site['site_name'] as String? ?? 'Mirage',
      author: site['author'] as String? ?? '',
      role: site['role'] as String? ?? '',
      tagline: site['tagline'] as String? ?? '',
      description: site['description'] as String? ?? '',
      avatar: site['avatar'] as String?,
      email: site['email'] as String?,
      siteUrl: site['site_url'] as String?,
      social: social
          .map((e) => SocialLink.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      bio: _toStringList(site['bio']),
    );
  }

  static List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return const [];
  }
}

/// 社交链接：名称、跳转地址与图标（支持本地资源路径或 http(s) 图片地址）。
class SocialLink {
  final String name;
  final String url;
  final String icon;

  const SocialLink({
    required this.name,
    required this.url,
    required this.icon,
  });

  factory SocialLink.fromMap(Map<String, dynamic> map) {
    return SocialLink(
      name: map['name']?.toString() ?? '',
      url: map['url']?.toString() ?? '',
      icon: map['icon']?.toString() ?? '',
    );
  }
}
