import 'package:flutter/material.dart';

class CustomRectPainter extends CustomPainter {
  final List<Rect> rects;

  CustomRectPainter(this.rects);

  @override
  void paint(Canvas canvas, Size size) {

    for (Rect rect in rects) {
      canvas.drawRect(
          rect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2..color = Colors.red);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    // TODO: implement shouldRepaint
    return null;
  }
}
