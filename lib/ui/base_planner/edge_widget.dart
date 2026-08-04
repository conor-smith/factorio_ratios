import 'package:factorio_ratios/factorio/base_planner/edge/edge.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/edge_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/geometry_operation.dart';
import 'package:factorio_ratios/ui/base_planner/graph_widget.dart';
import 'package:flutter/material.dart';

class EdgeWidget extends StatelessWidget {
  final EdgeChangeNotifier notifier;

  const EdgeWidget({super.key, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class EdgeChangeNotifier extends ElementViewChangeNotifier {
  final Edge edge;

  EdgeGeometry _geometry;
  GeometryOperation? _geometryOp;

  EdgeChangeNotifier(this.edge) : _geometry = edge.geometry, _geometryOp = null;

  EdgeGeometry get geometry => _geometry;

  @override
  void newSnapshot() {
    if (edge.geometry != _geometry) {
      _geometry = edge.geometry;
      notifyListeners();
    }
  }

  GeometryOperation? popGeometryOp() {
    var geometryOp = _geometryOp;
    _geometryOp = null;
    return geometryOp;
  }

  @override
  void checkForBuilder(GeometryOperation geometryOp) {
    var builder = geometryOp.getEdgeGeometryBuilder(edge);

    if (builder != null) {
      _geometryOp = geometryOp;
      _geometry = builder;
      notifyListeners();
    }
  }
}

// class EdgeWidget extends StatefulWidget {
//   final Edge edge;

//   const EdgeWidget({super.key, required this.edge});

//   @override
//   State<EdgeWidget> createState() => _EdgeWidgetState();
// }

// class _EdgeWidgetState extends State<EdgeWidget> {
//   late EdgeGeometry geometry;

//   // For convenience
//   Edge get edge => widget.edge;

//   @override
//   void initState() {
//     super.initState();

//     geometry = edge.geometry;

//     edge.addListener(
//       this,
//       (event) => setState(() => geometry = event.geometry ?? edge.geometry),
//     );
//   }

//   @override
//   void dispose() {
//     super.dispose();

//     edge.removeListener(this);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return IgnorePointer(
//       child: CustomPaint(
//         size: geometry.rect.size,
//         painter: LinesPainter(geometry.lines[0], edge.isSelected),
//       ),
//     );
//   }
// }

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
