import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// 在 web 上注册窗口级鼠标移出监听：鼠标真正离开浏览器窗口时回调
/// [onExit]，用于弥补引擎 `PointerExitEvent` 在窗口边缘不可靠的问题。
///
/// 使用 `mouseout`（冒泡）+ `relatedTarget == null` 判断指针离开文档，
/// 而非 `mouseleave`（不冒泡、挂在 window 上基本不触发）。
/// 返回取消注册的函数。
void Function() watchWindowPointerExit({required void Function() onExit}) {
  final handler = (web.Event event) {
    if ((event as web.MouseEvent).relatedTarget == null) {
      onExit();
    }
  }.toJS;
  web.window.addEventListener('mouseout', handler);
  return () {
    web.window.removeEventListener('mouseout', handler);
  };
}
