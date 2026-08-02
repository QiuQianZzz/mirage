# Mirage

基于 Flutter + Material Design 3 的个人站点。

## 功能

- 响应式布局（宽屏文字导航 / 窄屏图标导航）
- 浅色 / 深色主题切换（圆形扩散动画）
- 博客、随笔、项目、图片、技能五个板块
- Markdown 内容管理（支持本地模板 / git 子模块切换）
- Markdown 渲染：标题 / 表格 / 引用 / 任务列表，代码块语法高亮 + 一键复制，正文与代码均可选中复制
- RSS 订阅
- 中文字体按需子集化（17MB → 几百 KB）
- 一键构建脚本

## 快速开始

```bash
# 安装依赖
flutter pub get
npm install --prefix tool

# 本地开发
node tool/dev.mjs -d edge

# 构建 + 预览
node tool/build.mjs --preview --no-cdn
```

## 部署

构建产物在 `build/web/`，可直接部署到任何静态托管服务：

- **Cloudflare Pages** / **Vercel** / **Netlify** — 自动压缩，推荐
- **GitHub Pages** — 需要配置 404 回退

## 自定义

编辑 `assets/config/site.yaml` 修改站点信息、社交链接、个人介绍。

内容文件位于 `assets/content/` 下各子目录，格式为带 YAML frontmatter 的 Markdown。

## 文档

- [开发文档](DEVELOPMENT.md) — 环境配置、构建流程、内容管理、目录结构
