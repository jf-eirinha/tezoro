import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';

import 'detector_painters.dart';
import 'utils.dart';
import 'package:tflite/tflite.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

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

class APIPage extends StatefulWidget {
  @override
  _APIPageState createState() => _APIPageState();
  
}

class _APIPageState extends State<APIPage> {
  
  File _image;

  Future getImage() async {
    var   image = await ImagePicker.pickImage(source: ImageSource.gallery);

    setState(() {
     _image = image; 
    });

  }

  Future<String> getData() async {

    List<int> imageBytes = _image.readAsBytesSync();
    String base64Image = base64Encode(imageBytes);

    Map jsonRequest = {
      "payload": {
        "image": {
          "imageBytes": base64Image
          }
        }
    };
    String body = json.encode(jsonRequest);

    var response = await http.post(
      Uri.encodeFull(' https://automl.googleapis.com/v1beta1/projects/tezoro-bba6b/locations/us-central1/models/ICN2401483474436740584:predict'),
      headers: {
        "Content-Type": "application/json"
        "Authorization: Bearer ya29.GlvHBkWCONE-1620NYpvoiL68ecyZOjK2TaU9cOARkW3sAOumv_4Mr2EC8q9yflFhTTrViowvSsaMUydAeacZoqbXpgNPBuDBkCX9_5nw4FZIrefTTyIkVmazNoi"
      },
      body: body
    );

    Map data = json.decode(response.body);
    print(data);
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Center(
        child: _image == null 
            ? RaisedButton(
                child: new Text("Get Image!"),
                onPressed: getImage,
              )
            : RaisedButton(
                child: new Text("Get Data!"),
                onPressed: getData,
              )
          ), 
        );
  }  
}

class TakePicturePageLite extends StatefulWidget {
  @override
  _TakePicturePageLiteState createState() => _TakePicturePageLiteState();
}

class _TakePicturePageLiteState extends State<TakePicturePageLite> {
  
  dynamic _scanResults;
  CameraController _camera;

  bool _isDetecting = false;
  CameraLensDirection _direction = CameraLensDirection.back;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future loadModel() async {
    try {
      String res = await Tflite.loadModel(
        model: "assets/mobilenet_v1_1.0_224.tflite",
        labels: "assets/mobilenet_v1_1.0_224.txt",
      );
      print(res);
    } on PlatformException {
      print('Failed to load model.');
    }
  }

  Future recognizeImage(image) async {
    loadModel();
    var result = await Tflite.runModelOnFrame(
      bytesList: image.planes.map((plane) {return plane.bytes;}).toList(),// required
      imageHeight: image.height,
      imageWidth: image.width,
      imageMean: 127.5,   // defaults to 127.5
      imageStd: 127.5,    // defaults to 127.5
      rotation: 90,       // defaults to 90, Android only
      numResults: 2,      // defaults to 5
      threshold: 0.1,     // defaults to 0.1
    );

    print('I am up in here recognizing images!');

  }

  void _initializeCamera() async {
    _camera = CameraController(
      await getCamera(_direction),
      defaultTargetPlatform == TargetPlatform.iOS
        ? ResolutionPreset.low
        : ResolutionPreset.medium,
    );
    await _camera.initialize();

    _camera.startImageStream((CameraImage image) {
      if (_isDetecting) return;

      print('I am up in here initializing cameras!!!!');

      _isDetecting = true;
      recognizeImage(image).then(
        (dynamic result) {
           setState(() {
            _scanResults = result; 
           }); 

          _isDetecting = false;
        },
      ).catchError(
        (_) {
          _isDetecting = false;
        },
      );
    });
  }

  Widget _buildResults() {
    const Text noResultsText =  const Text('No results!');

    if(_scanResults == null || 
    _camera == null ||
    !_camera.value.isInitialized) {
      return noResultsText;
    }

    CustomPainter painter;

    final Size imageSize = Size(
      _camera.value.previewSize.height,
      _camera.value.previewSize.width,
    );

     painter = LabelDetectorPainter(imageSize, _scanResults);

     return CustomPaint(
       painter: painter,
      );
  }

  Widget  _buildImage() {
    return Container(
      constraints: const BoxConstraints.expand(),
      child: _camera == null
          ? const Center(
            child: Text('Initializing Camera...',
            style: TextStyle(
              color: Colors.green,
              fontSize: 30.0,
            ),
          )
        )
        : Stack(
            fit: StackFit.expand,
            children: <Widget>[
              CameraPreview(_camera),
              _buildResults(),
            ],
          )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Package Classifier Lite'),
      ),
      body: _buildImage(),
    );
  }

}

class TakePicturePage extends StatefulWidget {
  @override
  _TakePicturePageState createState() => _TakePicturePageState();
  
}

class _TakePicturePageState extends State<TakePicturePage> {
  
  dynamic _scanResults;
  CameraController _camera;

  bool _isDetecting = false;
  CameraLensDirection _direction = CameraLensDirection.back;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  void _initializeCamera() async {
    _camera = CameraController(
      await getCamera(_direction),
      defaultTargetPlatform == TargetPlatform.iOS
        ? ResolutionPreset.low
        : ResolutionPreset.medium,
    );
    await _camera.initialize();

    _camera.startImageStream((CameraImage image) {
      if (_isDetecting) return;

      _isDetecting = true;

      final FirebaseVision mlVision = FirebaseVision.instance;
      detect(image, mlVision.textRecognizer().processImage).then(
        (dynamic result) {
          setState(() {
            _scanResults = result;
          });

          _isDetecting = false;
        },
      ).catchError(
        (_) {
          _isDetecting = false;
        },
      );
    });
  }

  Widget _buildResults() {
    const Text noResultsText =  const Text('No results!');

    if(_scanResults == null || 
    _camera == null ||
    !_camera.value.isInitialized) {
      return noResultsText;
    }

    CustomPainter painter;

    final Size imageSize = Size(
      _camera.value.previewSize.height,
      _camera.value.previewSize.width,
    );

     painter = TextDetectorPainter(imageSize, _scanResults);

     return CustomPaint(
       painter: painter,
      );
  }

  Widget  _buildImage() {
    return Container(
      constraints: const BoxConstraints.expand(),
      child: _camera == null
          ? const Center(
            child: Text('Initializing Camera...',
            style: TextStyle(
              color: Colors.green,
              fontSize: 30.0,
            ),
          )
        )
        : Stack(
            fit: StackFit.expand,
            children: <Widget>[
              CameraPreview(_camera),
              _buildResults(),
            ],
          )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Package Classifier'),
      ),
      body: _buildImage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.display1,
            ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
