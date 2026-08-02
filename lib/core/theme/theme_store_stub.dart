import 'package:flutter/material.dart';

/// 非 web 平台没有 localStorage：不持久化，始终返回 null。
ThemeMode? readStoredTheme() => null;

void storeTheme(ThemeMode mode) {}
