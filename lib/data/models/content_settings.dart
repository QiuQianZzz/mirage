/// 内容来源的基础设施配置（对应 `assets/config/app.yaml`）。
///
/// 只描述“从哪里读取内容”，本身不属于内容，也不随内容仓库发布。
class ContentSettings {
  /// 内容来源：`local`（本地模板）或 `submodule`（git 子模块仓库）。
  final String source;

  /// 本地模板内容目录名（位于 assets/ 下）。
  final String localPath;

  /// 子模块内容目录名（位于 assets/ 下）。
  final String submodulePath;

  const ContentSettings({
    required this.source,
    required this.localPath,
    required this.submodulePath,
  });

  factory ContentSettings.fromMap(Map<String, dynamic> map) {
    final content = map['content'] as Map<String, dynamic>? ?? const {};
    return ContentSettings(
      source: content['source'] as String? ?? 'local',
      localPath: content['local_path'] as String? ?? 'content',
      submodulePath: content['submodule_path'] as String? ?? 'content_override',
    );
  }

  /// 生效的内容目录名。
  ///
  /// Flutter Web 无法打包 git 子模块目录（父仓库将其视为 gitlink，子目录全部
  /// 缺失），因此由 `tool/sync-content.mjs` 在构建/运行前把内容源物料化到普通
  /// 目录 `assets/content_effective/`，应用一律从这里读取。
  String get effectiveContentPath => 'content_effective';
}