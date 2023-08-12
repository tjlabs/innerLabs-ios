import 'package:flutter/material.dart';
import 'package:map_ui_module/screens/test_page.dart';

class MapUIModule extends StatelessWidget {
  const MapUIModule({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Map UI Module',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TestPage(),
    );
  }
}
