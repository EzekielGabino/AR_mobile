import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:camera/camera.dart';
import 'dart:typed_data';
import 'dart:math';
import 'package:image/image.dart' as img;

class Detection {
  final String className;
  final double confidence;
  final BoundingBox boxRect;
  Detection(this.className, this.confidence, this.boxRect);
}

class BoundingBox {
  final double left, top, right, bottom;
  BoundingBox(this.left, this.top, this.right, this.bottom);
}

class DetectionResult {
  final Detection detection;
  DetectionResult(this.detection);
}

/// Result of letterbox-preprocessing an image: the model input, plus the
/// scale/padding needed to map detected boxes (in padded-square-normalized
/// space) back to normalized coordinates in the ORIGINAL image.
class LetterboxResult {
  final Float32List input;
  final double scale;
  final int padX;
  final int padY;
  final int origWidth;
  final int origHeight;

  LetterboxResult({
    required this.input,
    required this.scale,
    required this.padX,
    required this.padY,
    required this.origWidth,
    required this.origHeight,
  });
}

class DetectionService {
  late Interpreter interpreter;
  late IsolateInterpreter isolateInterpreter;
  final int inputSize = 640;
  final List<String> classNames = [
    'Tube_brush',
    'alcohol_lamp',
    'beaker',
    'boiling_flask',
    'boiling_flask_3_neck',
    'conical_flask',
    'crucible',
    'evaporating_dish',
    'filter_flask',
    'funnel',
    'glass_rod',
    'graduated_cylinder',
    'medicine_dropper',
    'medicine_spoon',
    'mortar',
    'plastic_wash_bottle',
    'rubber_suction_bulb',
    'separatory_funnel',
    'test_tube',
    'volumetric_flask',
    'wide_mouth_bottle',
  ];

  Future<void> loadModel() async {
    interpreter = await Interpreter.fromAsset('assets/models/best.tflite');
    interpreter.allocateTensors();
    isolateInterpreter = await IsolateInterpreter.create(
      address: interpreter.address,
    );
  }

  /// Letterbox-resizes [image] into a inputSize x inputSize square,
  /// preserving aspect ratio by padding with gray bars (114,114,114 —
  /// the Ultralytics/YOLO default pad color) instead of stretching. This
  /// matches how YOLO training pipelines preprocess images by default;
  /// a plain stretch-resize here would distort the object's proportions
  /// depending on its orientation, which is a classic cause of a model
  /// only detecting reliably at certain angles.
  LetterboxResult preprocessImage(img.Image image) {
    final origWidth = image.width;
    final origHeight = image.height;
    final scale = min(inputSize / origWidth, inputSize / origHeight);
    final newWidth = (origWidth * scale).round();
    final newHeight = (origHeight * scale).round();

    final resized = img.copyResize(image, width: newWidth, height: newHeight);

    final padded = img.Image(width: inputSize, height: inputSize);
    img.fill(padded, color: img.ColorRgb8(114, 114, 114));

    final padX = ((inputSize - newWidth) / 2).round();
    final padY = ((inputSize - newHeight) / 2).round();
    img.compositeImage(padded, resized, dstX: padX, dstY: padY);

    var input = Float32List(1 * 3 * inputSize * inputSize);
    int idx = 0;
    for (int c = 0; c < 3; c++) {
      for (int y = 0; y < inputSize; y++) {
        for (int x = 0; x < inputSize; x++) {
          final pixel = padded.getPixel(x, y);
          double value = c == 0
              ? pixel.r.toDouble()
              : c == 1
              ? pixel.g.toDouble()
              : pixel.b.toDouble();
          input[idx++] = value / 255.0;
        }
      }
    }

    return LetterboxResult(
      input: input,
      scale: scale,
      padX: padX,
      padY: padY,
      origWidth: origWidth,
      origHeight: origHeight,
    );
  }

  Future<List<List<List<double>>>> runInference(Float32List input) async {
    var output = List.generate(
      1,
      (_) => List.generate(25, (_) => List.filled(8400, 0.0)),
    );

    await isolateInterpreter.run(
      input.reshape([1, 3, inputSize, inputSize]),
      output,
    );

    return output;
  }

  /// Maps a box from padded-square-normalized space (what the model
  /// outputs) back to normalized coordinates in the ORIGINAL image —
  /// undoing the letterbox scale + padding from preprocessImage().
  BoundingBox _unletterboxBox(BoundingBox box, LetterboxResult lb) {
    double unmapX(double norm) {
      final pxPadded = norm * inputSize;
      final pxOrig = (pxPadded - lb.padX) / lb.scale;
      return (pxOrig / lb.origWidth).clamp(0.0, 1.0);
    }

    double unmapY(double norm) {
      final pxPadded = norm * inputSize;
      final pxOrig = (pxPadded - lb.padY) / lb.scale;
      return (pxOrig / lb.origHeight).clamp(0.0, 1.0);
    }

    return BoundingBox(
      unmapX(box.left),
      unmapY(box.top),
      unmapX(box.right),
      unmapY(box.bottom),
    );
  }

  // Extracts all candidate boxes above threshold, then applies NMS to keep
  // only the best. Pass the LetterboxResult from preprocessImage() so
  // boxes get mapped back to the original image's proportions — omit it
  // only if you're feeding in boxes that are already in that space.
  List<Detection> postprocess(
    List<List<List<double>>> output, {
    LetterboxResult? letterbox,
    double confThreshold = 0.4,
    double iouThreshold = 0.45,
  }) {
    final predictions = output[0]; // [25][8400]
    List<Detection> candidates = [];

    double maxScoreSeen = 0;
    for (int i = 0; i < 8400; i++) {
      double maxScore = 0;
      int maxClassIdx = -1;
      for (int c = 0; c < classNames.length; c++) {
        final score = predictions[4 + c][i];
        if (score > maxScore) {
          maxScore = score;
          maxClassIdx = c;
        }
      }
      if (maxScore > maxScoreSeen) maxScoreSeen = maxScore;

      if (maxScore > confThreshold) {
        final cx = predictions[0][i];
        final cy = predictions[1][i];
        final w = predictions[2][i];
        final h = predictions[3][i];

        final left = (cx - w / 2);
        final top = (cy - h / 2);
        final right = (cx + w / 2);
        final bottom = (cy + h / 2);

        candidates.add(
          Detection(
            classNames[maxClassIdx],
            maxScore,
            BoundingBox(left, top, right, bottom),
          ),
        );
      }
    }

    // Logged regardless of whether anything crossed the threshold — this
    // tells you whether a failed detect was a near-miss (threshold too
    // strict) or the model genuinely didn't recognize the object at all
    // (a training-data problem, not a threshold problem).
    debugPrint(
      'postprocess: max class score seen this frame: '
      '${maxScoreSeen.toStringAsFixed(3)} (threshold: $confThreshold)',
    );

    final kept = _nonMaxSuppression(candidates, iouThreshold);

    if (letterbox == null) return kept;
    return kept
        .map(
          (d) => Detection(
            d.className,
            d.confidence,
            _unletterboxBox(d.boxRect, letterbox),
          ),
        )
        .toList();
  }

  List<Detection> _nonMaxSuppression(
    List<Detection> candidates,
    double iouThreshold,
  ) {
    candidates.sort((a, b) => b.confidence.compareTo(a.confidence));
    List<Detection> kept = [];

    while (candidates.isNotEmpty) {
      final best = candidates.removeAt(0);
      kept.add(best);
      candidates.removeWhere(
        (c) => _iou(best.boxRect, c.boxRect) > iouThreshold,
      );
    }
    return kept;
  }

  double _iou(BoundingBox a, BoundingBox b) {
    final interLeft = max(a.left, b.left);
    final interTop = max(a.top, b.top);
    final interRight = min(a.right, b.right);
    final interBottom = min(a.bottom, b.bottom);

    if (interRight < interLeft || interBottom < interTop) return 0.0;

    final interArea = (interRight - interLeft) * (interBottom - interTop);
    final areaA = (a.right - a.left) * (a.bottom - a.top);
    final areaB = (b.right - b.left) * (b.bottom - b.top);

    return interArea / (areaA + areaB - interArea);
  }

  // Converts a CameraImage (YUV420 on Android) to an img.Image (RGB) for
  // inference. Not currently used by the capture-based flow (which
  // decodes a JPEG from takePicture() instead) — kept for reference in
  // case a live-stream mode is reintroduced later.
  img.Image convertCameraImage(CameraImage cameraImage, int sensorOrientation) {
    final width = cameraImage.width;
    final height = cameraImage.height;

    final yPlane = cameraImage.planes[0];
    final uPlane = cameraImage.planes[1];
    debugPrint('U plane bytesPerPixel: ${uPlane.bytesPerPixel}');
    final vPlane = cameraImage.planes[2];
    final uvPixelStride = uPlane.bytesPerPixel ?? 2;

    final image = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yIndex = y * yPlane.bytesPerRow + x;
        final uvIndex =
            (y ~/ 2) * uPlane.bytesPerRow + (x ~/ 2) * uvPixelStride;

        final yValue = yPlane.bytes[yIndex];
        final uValue = uPlane.bytes[uvIndex];
        final vValue = vPlane.bytes[uvIndex];

        final r = (yValue + 1.402 * (vValue - 128)).clamp(0, 255).toInt();
        final g =
            (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
                .clamp(0, 255)
                .toInt();
        final b = (yValue + 1.772 * (uValue - 128)).clamp(0, 255).toInt();

        image.setPixelRgb(x, y, r, g, b);
      }
    }

    return img.copyRotate(image, angle: sensorOrientation);
  }

  Future<DetectionResult?> detectFromCameraImage(
    CameraImage cameraImage,
    int sensorOrientation,
  ) async {
    final rgbImage = convertCameraImage(cameraImage, sensorOrientation);
    final letterbox = preprocessImage(rgbImage);
    final output = await runInference(letterbox.input);
    final detections = postprocess(output, letterbox: letterbox);

    debugPrint('Detections after NMS: ${detections.length}');

    if (detections.isEmpty) return null;
    detections.sort((a, b) => b.confidence.compareTo(a.confidence));
    return DetectionResult(detections.first);
  }

  void dispose() {
    isolateInterpreter.close();
  }
}
