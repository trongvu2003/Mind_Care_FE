import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:mind_mare_fe/theme/app_colors.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:saver_gallery/saver_gallery.dart';

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

  // Kết quả AI để vẽ overlay
  List<FaceEmotion> faces = [];
  double lastImageW = 0;
  double lastImageH = 0;
  bool isAnalyzing = false;

  String get baseUrl {
    if (Platform.isAndroid) return 'http://192.168.1.72:3000';
    return 'http://127.0.0.1:3000';
  }

  @override
  void initState() {
    super.initState();
    initCamera(selectedCameraIndex);
  }

  Future<void> initCamera(int index) async {
    try {
      cameras = await availableCameras();
      if (cameras != null && cameras!.isNotEmpty) {
        controller = CameraController(
          cameras![index],
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await controller!.initialize();
        setState(() => isCameraReady = true);
      }
    } catch (e) {
      setState(() => isCameraReady = false);
      _toast('Lỗi khởi tạo camera: $e');
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

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _captureAndSave() async {
    if (controller == null || !controller!.value.isInitialized) return;

    try {
      final shot = await controller!.takePicture();
      if (Platform.isAndroid) {
        var photos = await Permission.photos.request();
        if (!photos.isGranted) {
          var storage = await Permission.storage.request();
          if (!storage.isGranted) {
            _toast('Cần cấp quyền để lưu ảnh');
            return;
          }
        }
      } else if (Platform.isIOS) {
        final addOnly = await Permission.photosAddOnly.request();
        if (!addOnly.isGranted) {
          _toast('Cần cấp quyền để lưu ảnh');
          return;
        }
      }

      // Lưu vào thư viện (Pictures/MindMare)
      final res = await SaverGallery.saveFile(
        filePath: shot.path,
        fileName: 'mind_mare_${DateTime.now().millisecondsSinceEpoch}.jpg',
        androidRelativePath: 'Pictures/MindMare',
        skipIfExists: false,
      );

      if (res.isSuccess) {
        _toast('Ảnh đã lưu vào Thư viện');
      } else {
        _toast('Lưu ảnh thất bại: ${res.errorMessage ?? ''}');
      }
    } catch (e) {
      _toast('Lỗi lưu ảnh: $e');
    }
  }

  Future<void> _analyzeOnce() async {
    if (controller == null || !controller!.value.isInitialized) return;
    if (isAnalyzing) return;
    setState(() => isAnalyzing = true);

    try {
      final shot = await controller!.takePicture();
      final bytes = await shot.readAsBytes();
      // Kích thước ảnh để scale overlay
      final uiImage = await decodeImageFromList(bytes);
      lastImageW = uiImage.width.toDouble();
      lastImageH = uiImage.height.toDouble();

      // chuẩn bị multipart call tới NestJS
      final uri = Uri.parse('$baseUrl/analyze/image');
      final req = http.MultipartRequest('POST', uri)
        ..files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: 'frame.jpg'),
        );

      // gửi
      final resp = await req.send();
      final body = await resp.stream.bytesToString();

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final jsonMap = jsonDecode(body) as Map<String, dynamic>;
        final facesJson = (jsonMap['faces'] as List?) ?? [];
        final parsed = facesJson.map((e) => FaceEmotion.fromJson(e)).toList();

        setState(() {
          faces = parsed;
        });

        if (faces.isEmpty) _toast('Không phát hiện khuôn mặt nào');
      } else {
        throw Exception('HTTP ${resp.statusCode}: $body');
      }
    } catch (e) {
      _toast('Phân tích thất bại: $e');
    } finally {
      if (mounted) setState(() => isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPreviewSize =
        isCameraReady && controller?.value.previewSize != null;
    final previewW =
        hasPreviewSize ? controller!.value.previewSize!.height : 0.0;
    final previewH =
        hasPreviewSize ? controller!.value.previewSize!.width : 0.0;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.text,
        elevation: 0,
        title: const Text(
          "Camera AI",
          style: TextStyle(
            color: AppColors.title,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body:
          isCameraReady
              ? SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: previewW,
                    height: previewH,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CameraPreview(controller!),
                        // Overlay khung & label
                        if (faces.isNotEmpty &&
                            lastImageW > 0 &&
                            lastImageH > 0)
                          CustomPaint(
                            painter: EmotionPainter(
                              faces: faces,
                              imageW: lastImageW,
                              imageH: lastImageH,
                              previewW: previewW,
                              previewH: previewH,
                              isFrontCamera:
                                  controller!.description.lensDirection ==
                                  CameraLensDirection.front,
                            ),
                          ),

                        // Badge loading
                        if (isAnalyzing)
                          const Align(
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: EdgeInsets.only(top: 80),
                              child: _AnalyzingBadge(),
                            ),
                          ),
                      ],
                    ),
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
              icon: const Icon(
                Icons.cameraswitch,
                color: Colors.white,
                size: 32,
              ),
              onPressed: switchCamera,
            ),
            GestureDetector(
              onTap: _captureAndSave,
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
              icon: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 32,
              ),
              onPressed: _analyzeOnce,
              tooltip: 'Phân tích cảm xúc 1 lần',
            ),
          ],
        ),
      ),
    );
  }
}

class FaceEmotion {
  final Rect box; // toạ độ theo ảnh gốc
  final String label;
  final Map<String, double> scores;

  FaceEmotion({required this.box, required this.label, required this.scores});

  factory FaceEmotion.fromJson(Map<String, dynamic> json) {
    final List boxArr = json['box'] ?? [0, 0, 0, 0];
    final x = (boxArr[0] as num).toDouble();
    final y = (boxArr[1] as num).toDouble();
    final w = (boxArr[2] as num).toDouble();
    final h = (boxArr[3] as num).toDouble();

    final scoresRaw = (json['scores'] as Map?) ?? {};
    final scores = scoresRaw.map(
      (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
    );

    return FaceEmotion(
      box: Rect.fromLTWH(x, y, w, h),
      label: (json['label'] ?? '').toString(),
      scores: scores,
    );
  }
}

class EmotionPainter extends CustomPainter {
  final List<FaceEmotion> faces;
  final double imageW, imageH; // kích thước ảnh gốc
  final double previewW, previewH; // kích thước widget preview
  final bool isFrontCamera;

  EmotionPainter({
    required this.faces,
    required this.imageW,
    required this.imageH,
    required this.previewW,
    required this.previewH,
    required this.isFrontCamera,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = previewW / imageW;
    final scaleY = previewH / imageH;

    final rectPaint =
        Paint()
          ..color = const Color(0xFFFF5252)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;

    for (final f in faces) {
      Rect r = Rect.fromLTWH(
        f.box.left * scaleX,
        f.box.top * scaleY,
        f.box.width * scaleX,
        f.box.height * scaleY,
      );
      if (isFrontCamera) {
        r = Rect.fromLTWH(previewW - r.right, r.top, r.width, r.height);
      }

      canvas.drawRect(r, rectPaint);

      final text =
          '${f.label.toUpperCase()}'
          '${f.scores[f.label] != null ? ' ${(f.scores[f.label]! * 100).toStringAsFixed(0)}%' : ''}';
      final tp = _tp(
        text,
        const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      );

      final padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 4);
      final bgRect = Rect.fromLTWH(
        r.left,
        (r.top - tp.height - 6).clamp(0, previewH),
        tp.width + padding.horizontal,
        tp.height + padding.vertical,
      );

      final bgPaint = Paint()..color = const Color(0xCC000000);
      canvas.drawRRect(
        RRect.fromRectAndRadius(bgRect, const Radius.circular(6)),
        bgPaint,
      );

      tp.paint(canvas, Offset(bgRect.left + 6, bgRect.top + 4));
    }
  }

  TextPainter _tp(String text, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );
    tp.layout();
    return tp;
  }

  @override
  bool shouldRepaint(covariant EmotionPainter old) {
    return old.faces != faces ||
        old.imageW != imageW ||
        old.imageH != imageH ||
        old.previewW != previewW ||
        old.previewH != previewH ||
        old.isFrontCamera != isFrontCamera;
  }
}

class _AnalyzingBadge extends StatelessWidget {
  const _AnalyzingBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xCC000000),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 8),
          Text('AI Processing...', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
