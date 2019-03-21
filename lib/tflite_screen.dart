import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'detector_painters.dart';
import 'utils.dart';
import 'package:tflite/tflite.dart';

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
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }

  Future loadModel() async {
    try {
      final res = await Tflite.loadModel(
        model: "assets/mobilenet_v1_1.0_224.tflite",
        labels: "assets/mobilenet_v1_1.0_224.txt",
      );
      print(res);
    } catch(e) {
      print('Failed to load model.');
      print(e);
    }
  }

  Future recognizeImage(image) async {
    await loadModel();
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

    setState(() {
            _scanResults = result; 
      }); 
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
    
    if (_camera == null) {
      _initializeCamera();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Package Classifier Lite'),
      ),
      body: _buildImage(),
    );
  }

}
