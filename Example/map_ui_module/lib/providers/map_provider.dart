import 'package:flutter/material.dart';
import 'package:map_ui_module/models/map_component.dart';

class MapProvider extends ChangeNotifier {
  late double _mapWidth;
  late double _mapHeight;
  late String _mapFile;
  late double _mapAspectRatio;
  List<MapComponent> _mapComponentList = [];

  double get mapWidth => _mapWidth;
  double get mapHeight => _mapHeight;
  String get mapURL => 'assets/map/$_mapFile';
  double get mapAspectRatio => _mapAspectRatio;
  List<MapComponent> get mapComponentList => _mapComponentList;

  init({
    required double mapWidth,
    required double mapHeight,
    required String mapFile,
    required List<MapComponent> mapComponentList,
  }) {
    _mapWidth = mapWidth;
    _mapHeight = mapHeight;
    _mapFile = mapFile;
    _mapAspectRatio = mapWidth / mapHeight;
    _mapComponentList = mapComponentList;
  }
}
