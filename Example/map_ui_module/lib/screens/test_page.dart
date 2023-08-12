import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  static const channelName = 'com.tjlabscorp.flutter.mapuimodule';
  final methodChannel = const MethodChannel(channelName);

  String stringFromNativeCode = 'Waiting for native code...';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map UI Module'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(stringFromNativeCode),
            ElevatedButton(
              onPressed: () async {
                try {
                  final String result = await methodChannel.invokeMethod('fromNativeCode');
                  setState(() {
                    stringFromNativeCode = result;
                  });
                } catch (e) {
                  debugPrint(e.toString());
                }
              },
              child: const Text('Get string from native code'),
            ),
          ],
        ),
      ),
    );
  }
}
