import 'package:flutter/material.dart';

/// 管理浅色 / 深色主题切换（二态，避免 system 态下点击无感）。
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController(super.initial);

  void toggle() {
    value = value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }
}
