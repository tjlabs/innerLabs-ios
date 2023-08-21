import 'package:flutter/material.dart';
import 'package:map_ui_module/map_ui_module.dart';
import 'package:map_ui_module/providers/jupiter_sdk.dart';
import 'package:map_ui_module/providers/map_provider.dart';
import 'package:map_ui_module/providers/pp_provider.dart';
import 'package:map_ui_module/providers/scale_factor_provider.dart';
import 'package:map_ui_module/utilities/map_component/map_component_list.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final jupiterSDK = JupiterSDK();
  final ppProvider = PPProvider();
  final mapProvider = MapProvider();
  final scaleFactorProvider = ScaleFactorProvider();

  await ppProvider.init(ppFile: 'S3_7F.csv');
  await mapProvider.init(
    mapWidth: 1199,
    mapHeight: 1155,
    mapFile: 'S3_7F.png',
    mapComponentList: [exitLogo, elevatorLogo, toiletLogo, smoreLogo, tjlabsLogo, littlecatLogo, yesnowLogo],
  );
  await scaleFactorProvider.init();
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider<JupiterSDK>.value(value: jupiterSDK),
      ChangeNotifierProvider.value(value: ppProvider),
      ChangeNotifierProvider.value(value: mapProvider),
      ChangeNotifierProvider.value(value: scaleFactorProvider),
    ],
    child: const MapUIModule(),
  ));
}
