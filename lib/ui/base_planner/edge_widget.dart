import 'package:factorio_ratios/factorio/base_planner/edge/edge.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/edge_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/geometry.dart';
import 'package:flutter/material.dart';

class EdgeWidget extends StatefulWidget {
  final Edge edge;

  const EdgeWidget({super.key, required this.edge});

  @override
  State<EdgeWidget> createState() => _EdgeWidgetState();
}

class _EdgeWidgetState extends State<EdgeWidget> {
  late EdgeGeometry geometry;

  // For convenience
  Edge get edge => widget.edge;

  @override
  void initState() {
    super.initState();

    geometry = edge.edgeGeometry;

    edge.addListener(
      this,
      (event) =>
          setState(() => geometry = event.edgeGeometry ?? edge.edgeGeometry),
    );
  }

  @override
  void dispose() {
    super.dispose();

    edge.removeListener(this);
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: LinesPainter(geometry.lines[0], edge.isSelected),
    );
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
  bool shouldRepaint(LinesPainter oldDelegate) =>
      oldDelegate.line != line || oldDelegate.selected != selected;
}
