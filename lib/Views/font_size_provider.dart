import 'package:flutter/material.dart';

class FontSizeProvider extends ChangeNotifier {
  double _textSize;

  FontSizeProvider(this._textSize); // Add this constructor

  double get textSize => _textSize;

  void updateTextSize(double newSize) {
    _textSize = newSize;
    notifyListeners();
  }
}
