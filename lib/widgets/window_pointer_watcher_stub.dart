/// 监听指针真正离开浏览器窗口的事件。
///
/// Flutter 的 [MouseRegion] 依赖引擎投递的 `PointerExitEvent`，
/// 在 web 上指针移出窗口边缘时可能不可靠（flutter/flutter#78280），
/// 因此在 web 上额外监听 window 级 `mouseleave` 作为兜底。
/// 非 web 平台为无操作实现，返回空注销函数。
void Function() watchWindowPointerExit({required void Function() onExit}) {
  return () {};
}
