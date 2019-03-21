import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'detector_painters.dart';
import 'utils.dart';


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
