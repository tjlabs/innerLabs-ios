import 'dart:developer';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_ui_module/models/pp.dart';

class PPProvider extends ChangeNotifier {
  late List<PP> _ppList;
  late int _minX;
  late int _minY;
  late int _maxX;
  late int _maxY;

  List<PP> get ppList => _ppList;
  int get minX => _minX;
  int get minY => _minY;
  int get maxX => _maxX;
  int get maxY => _maxY;

  Future<void> init({
    required String ppFile,
  }) async {
    _ppList = await _getPPListfromCSV(ppFile);
    var minMaxCordinate = getMinMaxPoints(_ppList);
    _minX = minMaxCordinate.$1;
    _minY = minMaxCordinate.$2;
    _maxX = minMaxCordinate.$3;
    _maxY = minMaxCordinate.$4;
  }

  Future<List<PP>> _getPPListfromCSV(String fileName) async {
    try {
      String rawData = await rootBundle.loadString('assets/pp/$fileName');
      List<List<dynamic>> csvData = const CsvToListConverter().convert(rawData);
      List<PP> ppList = <PP>[];
      for (List<dynamic> element in csvData) {
        ppList.add(PP(element[0] as int, element[1] as int));
      }
      return ppList;
    } catch (e) {
      log('Fail to load $fileName: $e');
      return [];
    }
  }

  (int minX, int minY, int maxX, int maxY) getMinMaxPoints(List<PP> ppList) {
    int minX = ppList[0].x;
    int minY = ppList[0].y;
    int maxX = minX;
    int maxY = minY;

    for (PP element in ppList) {
      int x = element.x;
      int y = element.y;

      if (x < minX) {
        minX = x;
      }
      if (x > maxX) {
        maxX = x;
      }
      if (y < minY) {
        minY = y;
      }
      if (y > maxY) {
        maxY = y;
      }
    }

    return (minX, minY, maxX, maxY);
  }
}
