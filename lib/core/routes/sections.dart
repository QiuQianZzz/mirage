import 'package:flutter/material.dart';

/// 单一数据源：定义站点各分区的路由段、中文标题、英文水印、图标与是否含详情页。
///
/// 导航栏、路由、列表页水印/跳转、详情页返回与 RSS 链接均从此读取，
/// 保证「路由段 + 文案」只在一处维护。
///
/// 使用 [Sections] 静态类作为命名空间，避免与各页面中同名的列表变量
/// （如 `essays`、`projects`、`photos`）冲突。
class Section {
  /// 路由段名（如 'blog' → '/blog'）。
  final String name;

  /// 导航栏中文标题（如 博客）。
  final String title;

  /// 页面顶部装饰水印（如 BLOG）。
  final String watermark;

  /// 未选中时的导航图标。
  final IconData icon;

  /// 选中时的导航图标。
  final IconData selectedIcon;

  /// 是否有关联的 `/:slug` 详情页。
  final bool hasDetail;

  const Section({
    required this.name,
    required this.title,
    required this.watermark,
    required this.icon,
    required this.selectedIcon,
    required this.hasDetail,
  });

  String get path => '/$name';

  String detailPath(String slug) => '/$name/$slug';
}

/// 站点全部分区的命名空间。
abstract final class Sections {
  /// 博客。
  static const blog = Section(
    name: 'blog',
    title: '博客',
    watermark: 'BLOG',
    icon: Icons.article_outlined,
    selectedIcon: Icons.article,
    hasDetail: true,
  );

  /// 随笔。
  static const essays = Section(
    name: 'essays',
    title: '随笔',
    watermark: 'ESSAYS',
    icon: Icons.edit_note_outlined,
    selectedIcon: Icons.edit_note,
    hasDetail: true,
  );

  /// 项目。
  static const projects = Section(
    name: 'projects',
    title: '项目',
    watermark: 'PROJECTS',
    icon: Icons.folder_outlined,
    selectedIcon: Icons.folder,
    hasDetail: true,
  );

  /// 拾光（图片）。
  static const photos = Section(
    name: 'photos',
    title: '拾光',
    watermark: 'PHOTOS',
    icon: Icons.photo_outlined,
    selectedIcon: Icons.photo,
    hasDetail: false,
  );

  /// 技艺（技能）。
  static const skills = Section(
    name: 'skills',
    title: '技艺',
    watermark: 'SKILLS',
    icon: Icons.memory,
    selectedIcon: Icons.memory,
    hasDetail: false,
  );

  /// 导航分区顺序（与路由 index 0 为首页的 branch 一一对应）。
  static const List<Section> all = [blog, essays, projects, photos, skills];
}