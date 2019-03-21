import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

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
      Uri.encodeFull('https://automl.googleapis.com/v1beta1/projects/tezoro-bba6b/locations/us-central1/models/ICN2401483474436740584:predict'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ya29.c.ElrSBrBcPQ8ieKs06Xk16gOguAhMKtjIrboVEQ72a2iva0Isu2BdFBX8QKL6TFVQlcSc0_ywsNz2QcLRmuzmF85f4zJPcLeB64_FiTy8_pYAhxxzqeTpfVAf4Pc"
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
