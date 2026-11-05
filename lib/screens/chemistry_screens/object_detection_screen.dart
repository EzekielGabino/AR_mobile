import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:scilense_ar_mobile/components/object_detection&sample_experiment/box_painter.dart';
import 'package:scilense_ar_mobile/components/object_detection&sample_experiment/detection_overlay_info.dart';
import 'package:scilense_ar_mobile/services/detection_service.dart';
import 'package:scilense_ar_mobile/theme/app_theme.dart';

/// Free-play object detection — no Experiment, no guided steps, no
/// equipment gating. Live camera + continuous throttled detection while
/// browsing, with a shutter to freeze on a deliberate capture. Useful as
/// a standalone "what is this?" tool, or for testing/demoing the model
/// outside a specific experiment's flow.
class ObjectDetectionScreen extends StatefulWidget {
  const ObjectDetectionScreen({super.key});

  @override
  State<ObjectDetectionScreen> createState() => _ObjectDetectionScreenState();
}

class _ObjectDetectionScreenState extends State<ObjectDetectionScreen> {
  CameraController? controller;
  final DetectionService detectionService = DetectionService();
  bool isDisposed = false;
  late CameraDescription selectedCamera;
  Size? _lastDetectionImageSize;

  Detection? currentDetection;
  bool _busy = false;
  DateTime _lastRun = DateTime.fromMillisecondsSinceEpoch(0);
  static const _throttle = Duration(milliseconds: 300);

  // The JPEG-encoded frame that produced the current currentDetection —
  // kept so the shutter can freeze on an already-succeeding live result
  // instead of gambling on a brand-new takePicture() call.
  Uint8List? _lastLiveFrameBytes;

  // Shutter state: once frozen, the live stream is stopped and the
  // background shows the captured still instead of CameraPreview.
  bool isFrozen = false;
  Uint8List? frozenBytes;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await detectionService.loadModel();
    final cameras = await availableCameras();
    selectedCamera = cameras.first;
    controller = CameraController(selectedCamera, ResolutionPreset.medium);
    await controller!.initialize();
    if (mounted) setState(() {});
    controller!.startImageStream(_onCameraFrame);
  }

  void _onCameraFrame(CameraImage cameraImage) {
    if (!mounted || isDisposed || _busy || isFrozen) return;
    final now = DateTime.now();
    if (now.difference(_lastRun) < _throttle) return;
    _lastRun = now;
    _processFrame(cameraImage);
  }

  Future<void> _processFrame(CameraImage cameraImage) async {
    _busy = true;
    try {
      final rgbImage = detectionService.convertCameraImage(
        cameraImage,
        selectedCamera.sensorOrientation,
      );
      final letterbox = detectionService.preprocessImage(rgbImage);
      final output = await detectionService.runInference(letterbox.input);
      final detections = detectionService.postprocess(
        output,
        letterbox: letterbox,
      );
      if (!mounted || isDisposed || isFrozen) return;

      // No equipment gating here — accept whatever the model finds, or
      // hold the last known box on a miss (silent, same as the guided
      // flow's live guide box).
      if (detections.isNotEmpty) {
        final jpegBytes = Uint8List.fromList(img.encodeJpg(rgbImage));
        setState(() {
          currentDetection = detections.first;
          _lastLiveFrameBytes = jpegBytes;
          _lastDetectionImageSize = Size(
            rgbImage.width.toDouble(),
            rgbImage.height.toDouble(),
          );
        });
      }
    } catch (e) {
      debugPrint('Object detection error (ignored): $e');
    } finally {
      _busy = false;
    }
  }

  /// Shutter tap: locks in whatever the background live-detection loop
  /// has already found — no new camera call, no shutter click, no race
  /// with the continuous stream. If nothing has been detected yet, asks
  /// the student to wait for a box to appear first, rather than gambling
  /// on a brand-new independent capture that might land on a worse angle
  /// than what's already showing.
  void _onShutterTap() {
    if (isFrozen) return; // already captured, use Retake first

    if (currentDetection == null || _lastLiveFrameBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nothing detected yet — hold steady until a box appears.',
          ),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (controller != null && controller!.value.isStreamingImages) {
      controller!.stopImageStream();
    }

    setState(() {
      isFrozen = true;
      frozenBytes = _lastLiveFrameBytes;
      // currentDetection is already set to the matching result.
    });
  }

  void _retake() {
    setState(() {
      isFrozen = false;
      frozenBytes = null;
      currentDetection = null;
      _lastLiveFrameBytes = null;
    });
    controller!.startImageStream(_onCameraFrame);
  }

  @override
  void dispose() {
    isDisposed = true;
    controller?.dispose();
    detectionService.isolateInterpreter.close();
    super.dispose();
  }

  Widget _buildFittedCamera(Size canvasSize) {
    final deviceRatio = canvasSize.width / canvasSize.height;
    final previewRatio = 1 / controller!.value.aspectRatio;
    return ClipRect(
      child: Transform.scale(
        scale: previewRatio / deviceRatio,
        child: Center(
          child: AspectRatio(
            aspectRatio: previewRatio,
            child: CameraPreview(controller!),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Object Detection'),
        centerTitle: true,
        foregroundColor: AppColors.textPrimary,
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
          return Stack(
            children: [
              frozenBytes != null
                  ? Positioned.fill(
                      child: Image.memory(frozenBytes!, fit: BoxFit.cover),
                    )
                  : _buildFittedCamera(canvasSize),
              if (!isFrozen)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _CenterGuideBoxPainter(),
                      size: canvasSize,
                    ),
                  ),
                ),
              if (currentDetection != null)
                Positioned.fill(
                  child: CustomPaint(
                    painter: DetectionBoxPainter(
                      detection: currentDetection,
                      previewSize: canvasSize,
                      imageSize: _lastDetectionImageSize,
                    ),
                  ),
                ),
              if (currentDetection != null)
                Positioned(
                  top: 20,
                  right: 20,
                  child: DetectionOverlay(
                    className: currentDetection!.className,
                  ),
                ),
              if (currentDetection != null)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${currentDetection!.className} '
                        '(${(currentDetection!.confidence * 100).toStringAsFixed(0)}%)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Center(
                  child: isFrozen
                      ? ElevatedButton.icon(
                          onPressed: _retake,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retake'),
                        )
                      : FloatingActionButton(
                          onPressed: _onShutterTap,
                          child: const Icon(Icons.camera_alt),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Generic centered dashed frame to help with equipment framing — not
/// tied to a specific equipment silhouette (unlike AlignmentGuideOverlay
/// in the guided flow), since this screen handles all classes.
class _CenterGuideBoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final guideRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.7,
      height: size.height * 0.45,
    );

    final paint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    const dashLength = 10.0;
    const gapLength = 6.0;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(guideRect, const Radius.circular(16)));

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final len = draw ? dashLength : gapLength;
        final next = (distance + len).clamp(0, metric.length);
        if (draw) {
          canvas.drawPath(metric.extractPath(distance, next.toDouble()), paint);
        }
        distance += len;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CenterGuideBoxPainter oldDelegate) => false;
}
