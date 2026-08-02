---
title: Markdown 渲染效果一览
date: 2026-02-01
tags: [markdown, 说明]
summary: 本站正文用 flutter_markdown 渲染，这篇文章把支持的语法挨个展示一遍，方便你了解效果。
---

这篇文章把本站支持的主要 Markdown 语法挨个展示一遍。文中代码块支持**语法高亮**、
**一键复制**，正文与代码都可以**长按选中复制**。

## 标题

从 `##` 到 `######` 都能正常渲染，依次是二级到六级标题。

### 三级标题

#### 四级标题

##### 五级标题

###### 六级标题

## 文本样式

- **加粗文字**
- *斜体文字*
- ~~删除线文字~~
- `行内代码`，用来标记 `package:flutter/material.dart` 这样的标识符
- 普通文本，段落之间会有合适的行高与间距

## 引用

> 简单，是最好的设计。
>
> 引用支持多段，也支持嵌套：

>> 这是嵌套的引用，用于引用引用中的引用。

## 列表

无序列表：

- Flutter
- Dart
- Web

有序列表：

1. 编写 Markdown
2. 构建站点
3. 上线发布

嵌套列表：

- 前端
  - Flutter
  - Vue
- 后端
  1. Node.js
  2. Go

任务列表：

- [x] 支持语法高亮
- [x] 支持一键复制
- [ ] 支持更多语法

## 链接

外链示例：[Flutter 官网](https://flutter.dev) 、[Dart 语言](https://dart.dev) ，
点击会在新窗口打开。

## 表格

| 语言     | 用途     | 熟练度 |
| -------- | -------- | ----- |
| Flutter  | 跨端 UI  | 高     |
| Dart     | 业务逻辑 | 高     |
| TypeScript | 前端     | 中     |

## 代码块

Dart（Flutter）：

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mirage',
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      home: const Scaffold(
        body: Center(child: Text('Hello, Flutter!')),
      ),
    );
  }
}
```

JavaScript：

```javascript
const greet = (name) => `Hello, ${name}!`;
console.log(greet("Mirage"));
```

Python：

```python
def fib(n):
    a, b = 0, 1
    for _ in range(n):
        a, b = b, a + b
    return a
```

JSON：

```json
{
  "site": "Mirage",
  "framework": "Flutter",
  "version": "1.0.0"
}
```

YAML：

```yaml
site:
  title: Mirage
  theme: Material 3
```

Shell：

```bash
flutter pub get && flutter build web --release
```

不写语言标签的代码块会自动检测语言（太长的内容会退化为纯文本）：

```
SELECT id, title, date FROM posts ORDER BY date DESC;
```

## 分割线

---

以上就是本站 Markdown 渲染的主要效果。如果你发现某个语法显示不正常，欢迎告诉我。
