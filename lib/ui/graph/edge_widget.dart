import 'package:factorio_ratios/factorio/graph.dart';
import 'package:flutter/material.dart';

class EdgeWidget extends StatefulWidget {
  final DirectedEdge edge;

  const EdgeWidget({super.key, required this.edge});

  @override
  State<EdgeWidget> createState() => _EdgeWidgetState();
}

class _EdgeWidgetState extends State<EdgeWidget> {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: LinesPainter(
        start: widget.edge.lines[0],
        end: widget.edge.lines[1],
      ),
    );
  }
}

class LinesPainter extends CustomPainter {
  final Offset start, end;

  LinesPainter({required this.start, required this.end});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      start,
      end,
      Paint()
        ..strokeWidth = 2
        ..color = Colors.black,
    );
  }

  @override
  bool shouldRepaint(covariant LinesPainter oldDelegate) {
    return oldDelegate.start != start || oldDelegate.end != end;
  }
}
