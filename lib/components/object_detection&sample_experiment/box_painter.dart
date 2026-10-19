import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/services/detection_service.dart';

class DetectionBoxPainter extends CustomPainter {
  final Detection? detection;
  final Size previewSize; // fallback only, kept for compatibility
  final Size?
  imageSize; // size of the source image detection.boxRect is normalized against

  DetectionBoxPainter({
    this.detection,
    required this.previewSize,
    this.imageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (detection == null) return;
    final box = detection!.boxRect;
    Rect rect;

    if (imageSize != null && imageSize!.width > 0 && imageSize!.height > 0) {
      // The preview is shown with a "cover" fit (see _buildFittedCamera):
      // the source image is scaled up and center-cropped to fill the
      // canvas. Replicate that same crop before mapping the box into
      // canvas space, or the box drifts/misresizes relative to the object.
      final imgAspect = imageSize!.width / imageSize!.height;
      final canvasAspect = size.width / size.height;

      double cropLeft = 0, cropRight = 1, cropTop = 0, cropBottom = 1;
      if (imgAspect > canvasAspect) {
        final visibleWidthFrac = canvasAspect / imgAspect;
        cropLeft = (1 - visibleWidthFrac) / 2;
        cropRight = 1 - cropLeft;
      } else {
        final visibleHeightFrac = imgAspect / canvasAspect;
        cropTop = (1 - visibleHeightFrac) / 2;
        cropBottom = 1 - cropTop;
      }

      double mapX(double x) =>
          (x - cropLeft) / (cropRight - cropLeft) * size.width;
      double mapY(double y) =>
          (y - cropTop) / (cropBottom - cropTop) * size.height;

      rect = Rect.fromLTRB(
        mapX(box.left),
        mapY(box.top),
        mapX(box.right),
        mapY(box.bottom),
      );
    } else {
      // Old behavior — only correct if nothing is being cropped.
      rect = Rect.fromLTRB(
        box.left * size.width,
        box.top * size.height,
        box.right * size.width,
        box.bottom * size.height,
      );
    }

    canvas.drawRect(
      rect,
      Paint()
        ..color = Colors.greenAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant DetectionBoxPainter oldDelegate) => true;
}
