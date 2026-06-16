import 'package:factorio_ratios/factorio/base_planner/edge/edge.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/geometry.dart';
import 'package:flutter/material.dart';

class EdgeWidget extends StatefulWidget {
  final Edge edge;

  const EdgeWidget({super.key, required this.edge});

  @override
  State<EdgeWidget> createState() => _EdgeWidgetState();
}

class _EdgeWidgetState extends State<EdgeWidget> {
  @override
  Widget build(BuildContext context) {
    // return CustomPaint(painter: LinesPainter(geometry.lines[0], selected));

    return Placeholder();
  }
}

class LinesPainter extends CustomPainter {
  final Line line;
  final bool selected;

  LinesPainter(this.line, this.selected);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      line.start,
      line.end,
      Paint()
        ..strokeWidth = 2
        ..color = selected ? Colors.yellow : Colors.black,
    );
  }

  @override
  bool shouldRepaint(covariant LinesPainter oldDelegate) {
    return oldDelegate.line != line || oldDelegate.selected != selected;
  }
}
