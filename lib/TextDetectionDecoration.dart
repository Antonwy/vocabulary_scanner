import 'package:flutter/material.dart';
import 'package:vocabulary_scanner/Helper.dart';

class TextDetectionDecoration extends Decoration {
  Size orginalImageSize;
  List<Rect> rects;

  TextDetectionDecoration({this.orginalImageSize, this.rects});

  @override
  BoxPainter createBoxPainter([VoidCallback onChanged]) {
    return _TextDetectPainter(orginalImageSize: orginalImageSize, rects: rects);
  }
}

class _TextDetectPainter extends BoxPainter {
  Size orginalImageSize;
  List<Rect> rects;

  _TextDetectPainter({this.orginalImageSize, this.rects});

  Size size;
  Offset _offset;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    size = configuration.size;
    _offset = offset;

    for (Rect rect in rects) {
      canvas.drawRect(
          convertRect(rect),
          Paint()
            ..style = PaintingStyle.stroke
            ..color = Colors.red
            ..strokeWidth = 1);
    }
  }

  Rect convertRect(Rect rect) {
    return Rect.fromLTRB(
        getX(rect.left), getY(rect.top), getX(rect.right), getY(rect.bottom));
  }

  double getX(double x) {
    return Helper.mapValue(x, 0, orginalImageSize.width, 0, size.width) +
        _offset.dx;
  }

  double getY(double y) {
    return Helper.mapValue(y, 0, orginalImageSize.height, 0, size.height) +
        _offset.dy;
  }
}
