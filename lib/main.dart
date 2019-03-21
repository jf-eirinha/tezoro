import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'ocr_vision_screen.dart';
import 'automl_screen.dart';
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
      title: 'Tezoro App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Tezoro'),
      routes: {
        '/SecondScreen': (context) => TakePicturePage(),
        '/FourthScreen': (context) => APIPage(),
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
              child: const Text("Test Text ML")
            ),
            RaisedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/ThirdScreen');
                },
              child: const Text("Test Picture ML")
            ),
            RaisedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/FourthScreen');
                },
              child: const Text("REST API")
            ),
          ],
        ),
      ),
    );
  }
}
