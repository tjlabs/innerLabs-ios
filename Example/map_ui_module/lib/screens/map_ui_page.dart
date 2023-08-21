import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:map_ui_module/models/flt_result.dart';
import 'package:map_ui_module/models/map_component.dart';
import 'package:map_ui_module/models/pp.dart';
import 'package:map_ui_module/providers/jupiter_sdk.dart';
import 'package:map_ui_module/providers/map_provider.dart';
import 'package:map_ui_module/providers/pp_provider.dart';
import 'package:map_ui_module/providers/scale_factor_provider.dart';
import 'package:provider/provider.dart';

class MapUIPage extends StatefulWidget {
  const MapUIPage({super.key});

  @override
  State<MapUIPage> createState() => _MapUIPageState();
}

class _MapUIPageState extends State<MapUIPage> with SingleTickerProviderStateMixin {
  late PPProvider _ppProvider;
  late ScaleFactorProvider _scaleFactorProvider;
  late MapProvider _mapProvider;

  late FLTResult _fltResult;
  late bool _isAutoMode;

  late double mobileWidth;
  late double mobileScale;

  final TransformationController _transformationController = TransformationController();

  double _enlargementScale = 1.0;

  @override
  void didChangeDependencies() {
    context.read<JupiterSDK>().getFLTResult();
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    context.read<JupiterSDK>().closeSubscription();
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _ppProvider = context.read<PPProvider>();
    _scaleFactorProvider = context.read<ScaleFactorProvider>();
    _mapProvider = context.read<MapProvider>();

    _fltResult = context.select<JupiterSDK, FLTResult>((jupiterSDK) => jupiterSDK.fltResult);
    _isAutoMode = context.select<JupiterSDK, bool>((jupiterSDK) => jupiterSDK.isAutoMode);

    mobileWidth = MediaQuery.of(context).size.width;
    mobileScale = mobileWidth / _mapProvider.mapWidth;

    return WillPopScope(
      onWillPop: () async {
        context.read<JupiterSDK>().closeSubscription();
        return true;
      },
      child: Scaffold(
        // appBar: AppBar(
        //   title: const Text('Map UI Module'),
        //   leading: IconButton(
        //     onPressed: () {
        //       context.read<JupiterSDK>().closeSubscription();
        //       Navigator.pop(context);
        //     },
        //     icon: const Icon(Icons.arrow_back_ios),
        //   ),
        // ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: _mapProvider.mapWidth * mobileScale,
                height: _mapProvider.mapHeight * mobileScale,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                ),
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  boundaryMargin: EdgeInsets.symmetric(
                    horizontal: _mapProvider.mapWidth * mobileScale,
                    vertical: _mapProvider.mapHeight * mobileScale,
                  ),
                  minScale: 0.5,
                  maxScale: 3.0,
                  onInteractionUpdate: (details) {
                    setState(() {
                      _enlargementScale = _transformationController.value.getMaxScaleOnAxis();
                    });
                  },
                  child: Stack(
                    children: [
                      SizedBox(
                        width: _mapProvider.mapWidth * mobileScale,
                        height: _mapProvider.mapHeight * mobileScale,
                        child: Image.asset(
                          _mapProvider.mapURL,
                          width: _mapProvider.mapWidth * mobileScale,
                          height: _mapProvider.mapHeight * mobileScale,
                          fit: BoxFit.contain,
                        ),
                      ),
                      ...mapComponentListWidget(_mapProvider, _fltResult),
                      ...ppListWidget(_ppProvider, _scaleFactorProvider),
                      currentPositionIcon(_ppProvider, _scaleFactorProvider, _fltResult),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> ppListWidget(PPProvider ppProvider, ScaleFactorProvider scaleFactorProvider) {
    return [
      for (PP pp in ppProvider.ppList)
        Positioned(
          left: ((pp.x.toDouble() - ppProvider.minX) * scaleFactorProvider.xScale + scaleFactorProvider.xOffset) * mobileScale - 2,
          bottom: ((pp.y.toDouble() - ppProvider.minY) * scaleFactorProvider.yScale + scaleFactorProvider.yOffset) * mobileScale - 2,
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
    ];
  }

  Widget appBar(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height + 50,
      width: MediaQuery.of(context).size.width,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back_ios),
            ),
          ),
        ],
      ),
    );
  }

  Widget currentPositionIcon(PPProvider ppProvider, ScaleFactorProvider scaleFactorProvider, FLTResult fltOutput) {
    return Positioned(
      left: ((fltOutput.x.toDouble() - ppProvider.minX) * scaleFactorProvider.xScale + scaleFactorProvider.xOffset) * mobileScale - 16,
      bottom: ((fltOutput.y.toDouble() - ppProvider.minY) * scaleFactorProvider.yScale + scaleFactorProvider.yOffset) * mobileScale - 16,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: Image.asset(
              'assets/inner_icon.png',
              fit: BoxFit.fill,
            ),
          ),
          Transform.rotate(
            angle: -fltOutput.absoluteHeading * math.pi / 180,
            child: SizedBox(
              width: 32,
              height: 32,
              child: Transform.translate(
                offset: const Offset(20, 0),
                child: Transform.rotate(
                  angle: 90 * math.pi / 180,
                  child: const Icon(
                    Icons.navigation,
                    size: 16,
                    color: Colors.blueGrey,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  List<Widget> mapComponentListWidget(MapProvider mapProvider, FLTResult fltOutput) {
    return [
      for (MapComponent component in mapProvider.mapComponentList) mapComponent(component, fltOutput),
    ];
  }

  Widget mapComponent(MapComponent component, FLTResult fltOutput) {
    return Positioned(
      left: component.offsetX * mobileScale,
      bottom: component.offsetY * mobileScale,
      child: Image.asset(
        component.imageURL,
        width: component.width * mobileScale,
        height: component.height * mobileScale,
      ),
    );
  }
}
