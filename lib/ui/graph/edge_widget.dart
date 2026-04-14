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
  void initState() {
    super.initState();

    // All relevant state is stored within edge object
    widget.edge.addListener((isRollback, event) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: LinesPainter(widget.edge.lines[0]));
  }
}

class LinesPainter extends CustomPainter {
  final Line line;

  LinesPainter(this.line);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      line.start,
      line.end,
      Paint()
        ..strokeWidth = 2
        ..color = Colors.black,
    );
  }

  @override
  bool shouldRepaint(covariant LinesPainter oldDelegate) {
    return oldDelegate.line != line;
  }
}
