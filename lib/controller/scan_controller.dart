import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class ScanController extends GetxController {
  late CameraController cameraController;
  late List<CameraDescription> cameras;

  var isCameraInitialized = false.obs;
  var isProcessing = false; // Flag to check if the interpreter is busy

  // Initialize coordinates and dimensions with 0.0 to ensure they are never null
  double x = 0.0, y = 0.0, w = 0.0, h = 0.0;
  String label = "";

  @override
  void onInit() {
    super.onInit();
    initCamera();
    initTFLite();
  }

  @override
  void dispose() {
    cameraController.dispose();
    Tflite.close(); // Ensure the TFLite resources are disposed
    super.dispose();
  }

  initCamera() async {
    if (await Permission.camera.request().isGranted) {
      cameras = await availableCameras();

      cameraController = CameraController(
        cameras[0],
        ResolutionPreset.max,
      );
      await cameraController.initialize().then((_) {
        isCameraInitialized(true);
        cameraController.startImageStream((image) {
          if (!isProcessing) {
            isProcessing = true;
            objectDetector(image);
          }
        });
      });
      update();
    } else {
      Get.snackbar("Permission Denied", "Camera permission is required!");
    }
  }

  initTFLite() async {
    await Tflite.loadModel(
      model: "assets/model.tflite",
      labels: "assets/labels.txt",
      isAsset: true,
      numThreads: 1,
      useGpuDelegate: false,
    );
  }

  objectDetector(CameraImage image) async {
    var detections = await Tflite.runModelOnFrame(
      bytesList: image.planes.map((plane) => plane.bytes).toList(),
      imageHeight: image.height,
      imageWidth: image.width,
      imageMean: 127.5,  // Ensuring that these values are not the issue
      imageStd: 127.5,
      numResults: 1,
      rotation: 90,
      threshold: 0.4,
    );

    if (detections != null && detections.isNotEmpty) {
      var ourDetectedObject = detections.first;
      double confidence = ourDetectedObject["confidenceInClass"] ?? 0.0;
      if (confidence * 100 > 45) {
        label = ourDetectedObject['detectedClass'].toString() ?? "";
        // Ensure we're using null-aware access and defaults for all rect parameters
        Map<String, double> rect = ourDetectedObject['rect'] as Map<String, double>? ?? {};
        h = rect['h'] ?? 0.0;
        w = rect['w'] ?? 0.0;
        x = rect['x'] ?? 0.0;
        y = rect['y'] ?? 0.0;
      }
    }
    isProcessing = false; // Reset the flag after processing
    update();
    if (kDebugMode) {
      print(detections?.first.toString());
      label = detections!.first.toString();
    }
  }
}
