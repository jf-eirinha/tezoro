import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'ocr_vision_screen.dart';
import 'tflite_screen.dart';

List<CameraDescription> cameras;

Future<void> main() async {
  cameras = await availableCameras();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ML Kit Vision OCR for Flutter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'TensorFlow Lite for Flutter'),
      routes: {
        '/SecondScreen': (context) => TextDetector(),
        '/ThirdScreen': (context) => TakePicturePageLite(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            RaisedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/SecondScreen');
                },
              child: const Text("ML Kit Vision OCR for Flutter")
            ),
            RaisedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/ThirdScreen');
                },
              child: const Text("TensorFlow Lite for Flutter")
            ),
          ],
        ),
      ),
    );
  }
}
