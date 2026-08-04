import 'package:factorio_ratios/factorio/base_planner/geometry/geometry_operation.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/node_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/node/node.dart';
import 'package:factorio_ratios/ui/base_planner/graph_widget.dart';
import 'package:flutter/material.dart';

class NodeWidget extends StatefulWidget {
  final NodeChangeNotifier notifier;

  const NodeWidget({super.key, required this.notifier});

  @override
  State<NodeWidget> createState() => _NodeWidgetState();
}

class _NodeWidgetState extends State<NodeWidget> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class NodeChangeNotifier extends ElementViewChangeNotifier {
  final NodeElement node;

  NodeGeometry _geometry;
  GeometryOperation? _geometryOp;

  NodeChangeNotifier(this.node) : _geometry = node.geometry;

  NodeGeometry get geometry => _geometry;

  @override
  void newSnapshot() {
    if (node.geometry != _geometry) {
      _geometry = node.geometry;
      notifyListeners();
    }
  }

  @override
  GeometryOperation? popGeometryOp() {
    var geometryOp = _geometryOp;
    _geometryOp = null;
    return geometryOp;
  }

  @override
  void checkForBuilder(GeometryOperation geometryOp) {
    var builder = geometryOp.getNodeGeometryBuilder(node);

    if (builder != null) {
      _geometryOp = geometryOp;
      _geometry = builder;
      notifyListeners();
    }
  }
}

// const _unselectedBoxDecoration = BoxDecoration(
//   border: Border.fromBorderSide(BorderSide()),
//   borderRadius: BorderRadius.all(Radius.circular(5)),
// );
// const _selectedBoxDecoration = BoxDecoration(
//   border: Border.fromBorderSide(BorderSide(color: Colors.yellow)),
//   borderRadius: BorderRadius.all(Radius.circular(5)),
// );

// class NodeWidget extends StatefulWidget {
//   final NodeElement node;

//   const NodeWidget({super.key, required this.node});

//   @override
//   State<NodeWidget> createState() => _NodeWidgetState();
// }

// class _NodeWidgetState extends State<NodeWidget> {
//   NodeGeometry geometry = NodeGeometryImpl.uninitialised;

//   _GestureOperation operation = _GestureOperation.noOperation;

//   PointerDownEvent? gestureStart;
//   GeometryOperation? geometryOperation;

//   // For convenience
//   NodeElement get node => widget.node;

//   @override
//   void initState() {
//     super.initState();

//     geometry = node.geometry;

//     node.addListener(
//       this,
//       (event) => setState(() => geometry = event.geometry ?? node.geometry),
//     );
//   }

//   @override
//   void dispose() {
//     super.dispose();

//     node.removeListener(this);
//   }

//   void beginGesture(PointerDownEvent event) {
//     if (event.buttons == gestures.kPrimaryButton) {
//       gestureStart = event;

//       if (node.isSelected) {
//         operation = _GestureOperation.potentialDrag;
//       } else {
//         operation = _GestureOperation.beingSelected;
//       }
//     }
//   }

//   void clearGestureData() {
//     operation = _GestureOperation.noOperation;
//     gestureStart = null;
//     geometryOperation?.cancel();
//     geometryOperation = null;

//     widget.endElementOperation();
//   }

//   void handlePointerMove(PointerMoveEvent event) {
//     switch (operation) {
//       case _GestureOperation.potentialDrag:
//         if (gestureStart != null && !isSimpleClick(gestureStart!, event)) {
//           widget.beginElementOperation();

//           operation = _GestureOperation.activeDrag;
//           geometryOperation = node.beginDrag();
//           geometryOperation!.performOperation(
//             event.localPosition - gestureStart!.localPosition,
//           );
//         }

//       case _GestureOperation.activeDrag:
//         geometryOperation!.performOperation(
//           event.localPosition - gestureStart!.localPosition,
//         );

//       default:
//         break;
//     }
//   }

//   void endGesture(PointerUpEvent event) {
//     switch (operation) {
//       case _GestureOperation.beingSelected:
//       case _GestureOperation.potentialDrag:
//         if (gestureStart != null && isSimpleClick(gestureStart!, event)) {
//           node.selectToggle(!widget.shiftKeyHeld);
//         }

//       case _GestureOperation.activeDrag:
//         geometryOperation!.applyUpdate();

//       default:
//         break;
//     }

//     clearGestureData();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Positioned.fromRect(
//       rect: geometry.rect,
//       child: Listener(
//         onPointerDown: beginGesture,
//         onPointerCancel: (_) => clearGestureData(),
//         onPointerMove: handlePointerMove,
//         onPointerUp: endGesture,
//         child: Container(
//           decoration: node.isSelected
//               ? _selectedBoxDecoration
//               : _unselectedBoxDecoration,
//           child: Center(child: Text(widget.node.toString())),
//         ),
//       ),
//     );
//   }
// }

// enum _GestureOperation { noOperation, beingSelected, potentialDrag, activeDrag }
