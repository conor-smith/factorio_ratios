import 'package:factorio_ratios/factorio/base_planner/geometry/geometry_operation.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/node_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/node/node.dart';
import 'package:factorio_ratios/ui/base_planner/graph_widget.dart';
import 'package:factorio_ratios/ui/simple_gesture_detector.dart';
import 'package:flutter/material.dart';

const _unselectedBoxDecoration = BoxDecoration(
  border: Border.fromBorderSide(BorderSide()),
  borderRadius: BorderRadius.all(Radius.circular(5)),
);
const _selectedBoxDecoration = BoxDecoration(
  border: Border.fromBorderSide(BorderSide(color: Colors.yellow)),
  borderRadius: BorderRadius.all(Radius.circular(5)),
);

class NodeWidget extends StatelessWidget {
  final NodeChangeNotifier notifier;

  const NodeWidget({super.key, required this.notifier});

  Widget _buildNodeWidget(BuildContext context) => SimpleGestureDetector(
    onPrimaryPointerDown: (_) => beginElementOperation(context),
    onPrimaryClick: (_) =>
        selectToggleAndEndElementOperation(context, notifier.node),
    onPointerCancel: (_) => endElementOperation(context),
    onDragStart: (_) {
      if (notifier.selected) {
        beginNodeDragOperation(context);
      }
    },
    onDrag: (start, move) =>
        notifier.geometryOp?.performOperation(move.position - start.position),
    onDragCancel: (_) => cancelGeometryOperation(context),
    onDragEnd: (_, _) => notifier.geometryOp?.applyUpdate(),
    child: Positioned.fromRect(
      rect: notifier.geometry.rect,
      child: Container(
        decoration: notifier.selected
            ? _selectedBoxDecoration
            : _unselectedBoxDecoration,
        child: Center(child: Text(notifier.node.toString())),
      ),
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
            builder: (newContext, _) => _buildNodeWidget(newContext),
          );
        } else {
          return _buildNodeWidget(context);
        }
      },
    );
  }
}

class NodeChangeNotifier extends ElementChangeNotifier {
  final NodeElement node;

  NodeGeometry _geometry;

  NodeChangeNotifier(this.node) : _geometry = node.geometry;

  NodeGeometry get geometry => _geometry;

  @override
  void newSnapshot() {
    super.newSnapshot();

    if (node.geometry != _geometry) {
      _geometry = node.geometry;
      notifyListeners();
    }
  }

  @override
  set geometryOp(GeometryOperation newOp) {
    super.geometryOp = newOp;

    _geometry = newOp.getNodeGeometryBuilder(node)!;

    notifyListeners();
  }
}
