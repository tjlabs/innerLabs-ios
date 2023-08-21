import 'package:flutter/material.dart';

class ScaleFactorProvider extends ChangeNotifier {
  late double _xScale;
  late double _yScale;
  late double _xOffset;
  late double _yOffset;
  late double _rotationAngle;

  double get xScale => _xScale;
  double get yScale => _yScale;
  double get xOffset => _xOffset;
  double get yOffset => _yOffset;
  double get rotationAngle => _rotationAngle;

  init({
    double xScale = 62.19,
    double yScale = 56,
    double xOffset = 440,
    double yOffset = 420,
    double rotationAngle = 0,
  }) {
    _xScale = xScale;
    _yScale = yScale;
    _xOffset = xOffset;
    _yOffset = yOffset;
    _rotationAngle = rotationAngle;
  }

  void setXScale(double xScale) {
    _xScale = xScale;
    notifyListeners();
  }

  void setYScale(double yScale) {
    _yScale = yScale;
    notifyListeners();
  }

  void setXOffset(double xOffset) {
    _xOffset = xOffset;
    notifyListeners();
  }

  void setYOffset(double yOffset) {
    _yOffset = yOffset;
    notifyListeners();
  }

  void setRotationAngle(double rotationAngle) {
    _rotationAngle = rotationAngle;
    notifyListeners();
  }
}
