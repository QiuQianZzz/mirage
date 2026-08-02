/// 主题持久化存储：web 上读写 localStorage，其它平台为空操作。
///
/// 通过条件导入选择实现，避免在非 web 环境编译 `dart:js_interop`。
library;

export 'theme_store_stub.dart'
    if (dart.library.js_interop) 'theme_store_web.dart';
