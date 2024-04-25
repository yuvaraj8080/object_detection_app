import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/scan_controller.dart';

class CameraView extends StatelessWidget {
  const CameraView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:GetBuilder<ScanController>(
        init:ScanController(),
        builder:(controller){
          return controller.isCameraInitialized.value
              ? Stack(
                children: [
                  CameraPreview(controller.cameraController),
                  Align(
                    alignment:Alignment.bottomCenter,
                    child: Container(
                      width:400,
                      height:100,
                      decoration:BoxDecoration(
                        borderRadius:BorderRadius.circular(8),
                        border:Border.all(color:Colors.green,width:4)
                      ),
                      child: Column(
                        mainAxisSize:MainAxisSize.min,
                          children:[
                         Container(
                           color:Colors.white,
                             child:  Center(child: Text(controller.label,style:TextStyle(fontWeight:FontWeight.bold,fontSize:15)))),
                      ])
                    ),
                  )
                ],
              )
              : const Center(child:Text("Loading Preview")
          );
        }
      )
    );
  }
}
