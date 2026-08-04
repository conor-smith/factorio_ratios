import 'package:factorio_ratios/factorio/base_planner/edge/edge.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/edge_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/geometry_operation.dart';
import 'package:factorio_ratios/ui/base_planner/graph_widget.dart';
import 'package:flutter/material.dart';

class EdgeWidget extends StatelessWidget {
  final EdgeChangeNotifier notifier;

  const EdgeWidget({super.key, required this.notifier});

  Widget _buildEdgeWidget(BuildContext context) => IgnorePointer(
    child: CustomPaint(
      size: notifier.geometry.rect.size,
      painter: LinesPainter(notifier.geometry.lines[0], notifier.selected),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: notifier,
      builder: (context, _) {
        var geometryOp = notifier.geometryOp;

        if (geometryOp != null) {
          return ListenableBuilder(
            listenable: geometryOp,
            builder: (newContext, _) => _buildEdgeWidget(newContext),
          );
        } else {
          return _buildEdgeWidget(context);
        }
      },
    );
  }
}

class EdgeChangeNotifier extends ElementViewChangeNotifier {
  final Edge edge;

  EdgeGeometry _geometry;

  EdgeChangeNotifier(this.edge) : _geometry = edge.geometry;

  EdgeGeometry get geometry => _geometry;

  @override
  void newSnapshot() {
    super.newSnapshot();

    if (edge.geometry != _geometry) {
      _geometry = edge.geometry;
      notifyListeners();
    }
  }

  @override
  set geometryOp(GeometryOperation newOp) {
    super.geometryOp = newOp;

    _geometry = newOp.getEdgeGeometryBuilder(edge)!;

    notifyListeners();
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
