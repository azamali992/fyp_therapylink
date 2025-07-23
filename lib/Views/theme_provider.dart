import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark;

  ThemeProvider(this._isDark);

  bool get isDark => _isDark;

  void setDarkMode(bool value) {
    _isDark = value;
    notifyListeners();
  }

  void toggle() {
    _isDark = !_isDark;
    notifyListeners();
  }
}
