import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/models/photo.dart';

/// 打开照片放大预览（lightbox）。
///
/// 遮罩使用当前主题的 `surface`（深浅色均自然），支持：
/// - 捏合/拖拽缩放（[InteractiveViewer]）
/// - 点击空白处关闭
/// - 按 Esc 关闭
/// - 右上角关闭按钮
Future<void> showPhotoLightbox(BuildContext context, Photo photo) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '关闭',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) =>
        _PhotoLightbox(photo: photo),
    transitionBuilder: (context, animation, secondary, child) =>
        FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: ScaleTransition(
        scale: Tween(begin: 0.96, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOut),
        ),
        child: child,
      ),
    ),
  );
}

class _PhotoLightbox extends StatefulWidget {
  final Photo photo;

  const _PhotoLightbox({required this.photo});

  @override
  State<_PhotoLightbox> createState() => _PhotoLightboxState();
}

class _PhotoLightboxState extends State<_PhotoLightbox> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Widget _image() {
    return widget.photo.isNetwork
        ? Image.network(widget.photo.url, fit: BoxFit.contain)
        : Image.asset(widget.photo.url, fit: BoxFit.contain);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ColoredBox(
      color: scheme.surface,
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.of(context).pop();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
              Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: IconButton(
                        tooltip: '关闭',
                        icon: const Icon(Icons.close_rounded),
                        color: scheme.onSurfaceVariant,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: InteractiveViewer(
                        maxScale: 5,
                        boundaryMargin: const EdgeInsets.all(80),
                        child: Center(child: _image()),
                      ),
                    ),
                  ),
                  if (widget.photo.caption.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                      child: Text(
                        widget.photo.caption,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}