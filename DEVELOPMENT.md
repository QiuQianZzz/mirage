# 开发文档

## 环境要求

- Flutter SDK 3.x（Dart ^3.12.2）
- Node.js 18+（用于工具脚本）

## 目录结构

```
lib/
├── main.dart                     # 入口
├── app.dart                      # 根组件（主题切换动画、路由）
├── core/
│   ├── theme/                    # MD3 主题（青色种子，浅/深色）
│   │   ├── app_theme.dart        # ThemeData 定义
│   │   └── theme_controller.dart # 浅/深二态切换
│   └── router/
│       └── app_router.dart       # go_router 路由配置
├── data/
│   ├── models/                   # 数据模型
│   │   ├── blog_post.dart
│   │   ├── essay.dart
│   │   ├── photo.dart
│   │   ├── project.dart
│   │   ├── skill.dart
│   │   └── site_config.dart
│   ├── frontmatter_parser.dart   # YAML frontmatter 解析
│   └── content_repository.dart   # 内容加载 + RSS 生成
├── features/
│   ├── layout/
│   │   ├── app_shell.dart        # 响应式导航栏
│   │   └── not_found_page.dart
│   ├── home/home_page.dart       # 首页
│   ├── blog/                     # 博客列表 + 详情
│   ├── essays/                   # 随笔列表 + 详情
│   ├── projects/                 # 项目列表 + 详情
│   ├── photos/photos_page.dart   # 图片
│   └── skills/skills_page.dart   # 技能
└── widgets/
    └── markdown_view.dart        # Markdown 渲染（代码块高亮/复制/可选中，链接跳转）

assets/
├── config/site.yaml              # 站点配置
├── content/
│   ├── posts/                    # 博客 Markdown
│   ├── essays/                   # 随笔 Markdown
│   ├── projects/                 # 项目 Markdown
│   ├── skills/                   # 技能 Markdown
│   └── photos/index.yaml         # 图片数据
├── content_override/             # git 子模块挂载点
└── fonts/NotoSansSC-Subset.ttf   # 子集字体（gitignored）

tool/
├── build.mjs                     # 一键构建
├── dev.mjs                       # 开发模式
├── preview.mjs                   # 本地预览服务器
├── subset_font.mjs               # 字体子集化
└── gen_feed.mjs                  # RSS 生成
```

## 开发命令

```bash
# 本地开发（自动替换占位符，退出时恢复）
node tool/dev.mjs                # 默认 Chrome
node tool/dev.mjs -d edge        # 指定浏览器
node tool/dev.mjs -d windows     # 桌面应用

# 一键构建
node tool/build.mjs              # 构建 + 生成 feed.xml
node tool/build.mjs --preview    # 构建完自动预览
node tool/build.mjs --no-cdn     # 国内部署（不依赖 Google CDN）

# 单独运行各工具
node tool/subset_font.mjs        # 字体子集化
node tool/gen_feed.mjs           # 生成 RSS
node tool/preview.mjs            # 预览 build/web/
```

## 构建流程

`node tool/build.mjs --no-cdn` 执行以下步骤：

1. 读取 `site.yaml`，将 `{{site_title}}` / `{{site_name}}` 注入 `index.html` 和 `manifest.json`
2. `subset_font.mjs` — 扫描内容提取中文字符，生成子集字体
3. `flutter build web --release --no-web-resources-cdn` — 编译 Flutter Web
4. 替换 `build/web/` 产物中的占位符为实际值
5. `gen_feed.mjs` — 从 posts + essays 生成 RSS XML

> 源文件 `web/index.html` 和 `web/manifest.json` 始终保持 `{{site_title}}` 占位符，不会被修改。

## 站点配置

`assets/config/site.yaml`：

```yaml
site:
  title: QiuQianZzz           # 页面标题（人名）
  site_name: Mirage            # 导航栏 logo（项目名）
  author: QiuQianZzz
  role: Flutter / Web 开发者
  site_url: https://xxx.com    # RSS 链接前缀
  email: hello@example.com
  social:
    GitHub: https://github.com/xxx
    博客: https://blog.xxx.com
  bio:
    - 第一段介绍
    - 第二段介绍

content:
  source: local                # local 或 submodule
  local_path: content
  submodule_path: content_override
```

## 内容管理

所有内容为 Markdown 文件，带 YAML frontmatter。

### 博客 `assets/content/posts/*.md`

```yaml
---
title: 文章标题
date: 2026-01-15
tags: [flutter, 教程]
summary: 一句话摘要
featured: true
---
正文内容...
```

### 随笔 `assets/content/essays/*.md`

```yaml
---
title: 随笔标题
date: 2026-05-22
tags: [生活]
summary: 一句话摘要
---
正文内容...
```

### 项目 `assets/content/projects/*.md`

```yaml
---
name: 项目名称
description: 项目描述
date: 2026-03-01
tags: [flutter, web]
repo: https://github.com/xxx/yyy
demo: https://yyy.example.com
---
项目详情...
```

### 技能 `assets/content/skills/*.md`

```yaml
---
category: 前端框架
icon: code
items:
  - name: Flutter
    level: 4
  - name: Vue
    level: 3
---
```

### 图片 `assets/content/photos/index.yaml`

```yaml
- url: assets/content/photos/img01.jpg    # 本地 / 网络 URL / 子模块相对路径
  caption: 图片说明
  date: 2026-03-15
  album: 生活
```

## 切换内容源

将自有内容仓库挂载为 git 子模块：

```bash
git submodule add https://github.com/you/content assets/content_override
```

修改 `site.yaml`：

```yaml
content:
  source: submodule
  submodule_path: content_override
```

## 路由结构

| 路由 | 页面 | 导航项 |
|------|------|--------|
| `/` | 首页 | 点击 Logo |
| `/blog` | 博客列表 | 博客 |
| `/blog/:slug` | 博客详情 | — |
| `/essays` | 随笔列表 | 随笔 |
| `/essays/:slug` | 随笔详情 | — |
| `/projects` | 项目列表 | 项目 |
| `/projects/:slug` | 项目详情 | — |
| `/photos` | 图片 | 图片 |
| `/skills` | 技能 | 技能 |

## 部署

构建产物在 `build/web/`，所有路由需要回退到 `index.html`。

### Cloudflare Pages / Vercel / Netlify

自动处理 SPA 回退，直接部署 `build/web/` 即可。

### GitHub Pages

在 `build/web/` 中添加 `404.html`（复制 `index.html`）：

```bash
cp build/web/index.html build/web/404.html
```
