import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// localStorage 键名，与启动页 index.html 中读取时保持一致。
const String kThemeStorageKey = 'mirage.theme';

/// 读取持久化的主题模式；无记录或读取失败时返回 null。
ThemeMode? readStoredTheme() {
  try {
    return switch (web.window.localStorage.getItem(kThemeStorageKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => null,
    };
  } catch (_) {
    return null;
  }
}

void storeTheme(ThemeMode mode) {
  try {
    web.window.localStorage.setItem(
      kThemeStorageKey,
      mode == ThemeMode.dark ? 'dark' : 'light',
    );
  } catch (_) {
    // 隐私模式等场景下写入可能失败，忽略即可。
  }
}
