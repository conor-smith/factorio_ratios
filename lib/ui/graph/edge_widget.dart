import 'package:factorio_ratios/factorio/graph/geometry/geometry.dart';
import 'package:factorio_ratios/factorio/graph/graph.dart';
import 'package:factorio_ratios/factorio/graph/state/state.dart';
import 'package:flutter/material.dart';

class EdgeWidget extends StatefulWidget {
  final DirectedEdge edge;

  const EdgeWidget({super.key, required this.edge});

  @override
  State<EdgeWidget> createState() => _EdgeWidgetState();
}

class _EdgeWidgetState extends State<EdgeWidget> {
  bool selected = false;
  late EdgeGeometry geometry;

  @override
  void initState() {
    super.initState();

    geometry = widget.edge.geometry;

    // All relevant state is stored within edge object
    widget.edge.addListener((event) {
      for (var mutation in event.mutations) {
        switch (mutation) {
          case EdgeEventType.selectToggle:
            selected = event.selected!;

          case EdgeEventType.tempGeometry:
          case EdgeEventType.newGeometry:
            geometry = event.newGeometry!;

          default:
            break;
        }
      }

      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: LinesPainter(geometry.lines[0], selected));
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
