import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class ScanController extends GetxController {
  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    initCamera();
    initTFLite();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    cameraController.dispose();
  }

  /// CREATING VERIEBLE
  late CameraController cameraController;
  late List<CameraDescription> cameras;

  var cameraCount = 0;
  var isCameraInitialized = false.obs;

  var x,y,w,h = 0.0;
  var label = "";

  initCamera() async {
    if (await Permission.camera.request().isGranted) {
      cameras = await availableCameras();

      cameraController = CameraController(
        cameras[0],
        ResolutionPreset.max,
      );
      await cameraController.initialize().then((value){
        cameraController.startImageStream((image) {
          cameraCount++;
          if(cameraCount % 10 == 0){
            cameraCount = 0;
            objectDetector(image);
          }
          update();
        });

      });
      isCameraInitialized(true);
      update();
    } else {
      Get.snackbar("Permission Denied", "");
    }
  }

  /// CREATE METHOD FOR THE INIT TFLITE
  initTFLite() async{
    await Tflite.loadModel(
      model:"assets/model.tflite",
      labels:"assets/labels.txt",
      isAsset: true,
      numThreads: 1,
      useGpuDelegate:false
    );
  }


  /// CREATING A OBJECT DETECTOR METHOD
  objectDetector(CameraImage image) async {
    var detections = await Tflite.runModelOnFrame(
      bytesList: image.planes.map((e) {
        return e.bytes;
      }).toList(),
      imageHeight: image.height,
      imageWidth: image.width,
      imageMean: 127.5,
      imageStd: 127.5,
      numResults: 1,
      rotation: 90,
      threshold: 0.4,
    );
    if (detections != null && detections.isNotEmpty) {
      var ourDetectedObject = detections.first;
      if(ourDetectedObject["confidenceInClass"]*100 > 45){
        label = detections.first['detectedClass'].tostring();
        h = ourDetectedObject['rect']['h'];
        w = ourDetectedObject['rect']['w'];
        x = ourDetectedObject['rect']['x'];
        y = ourDetectedObject['rect']['y'];
      }
      update();
    }
  }



}
