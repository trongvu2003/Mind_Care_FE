import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:mind_mare_fe/theme/app_colors.dart';

class CameraAIPage extends StatefulWidget {
  const CameraAIPage({super.key});

  @override
  State<CameraAIPage> createState() => _CameraAIPageState();
}

class _CameraAIPageState extends State<CameraAIPage> {
  CameraController? controller;
  List<CameraDescription>? cameras;
  bool isCameraReady = false;
  int selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    initCamera(selectedCameraIndex);
  }

  Future<void> initCamera(int index) async {
    cameras = await availableCameras();
    if (cameras != null && cameras!.isNotEmpty) {
      controller = CameraController(cameras![index], ResolutionPreset.high);
      await controller!.initialize();
      setState(() => isCameraReady = true);
    }
  }

  void switchCamera() async {
    if (cameras == null || cameras!.length < 2) return;
    setState(() => isCameraReady = false);
    selectedCameraIndex = (selectedCameraIndex + 1) % cameras!.length;
    await initCamera(selectedCameraIndex);
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.text,
        elevation: 0,
        title: const Text(
          "Camera AI",
          style: TextStyle(
            color:AppColors.title,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: isCameraReady
          ? SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller!.value.previewSize!.height,
            height: controller!.value.previewSize!.width,
            child: CameraPreview(controller!),
          ),
        ),
      )
          : const Center(
        child: CircularProgressIndicator(color: Colors.teal),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
        color: Colors.black.withOpacity(0.5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [

            IconButton(
              icon: const Icon(Icons.cameraswitch, color: Colors.white, size: 32),
              onPressed: switchCamera,
            ),
            GestureDetector(
              onTap: () async {
                if (controller != null && controller!.value.isInitialized) {
                  final image = await controller!.takePicture();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Ảnh đã chụp: ${image.path}")),
                  );
                }
              },
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: Container(
                  margin: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            IconButton(
              icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("AI Processing...")),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
