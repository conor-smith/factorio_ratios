import 'package:factorio_ratios/factorio/base_planner/geometry/geometry_operation.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/node_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/node/node.dart';
import 'package:flutter/gestures.dart' as gestures;
import 'package:flutter/material.dart';

class NodeWidget extends StatefulWidget {
  final NodeElement node;
  final Function() disableParentTransform;
  final Function() enableParentTransform;

  const NodeWidget({
    super.key,
    required this.node,
    required this.disableParentTransform,
    required this.enableParentTransform,
  });

  @override
  State<NodeWidget> createState() => _NodeWidgetState();
}

class _NodeWidgetState extends State<NodeWidget> {
  late NodeGeometry geometry;

  _GestureOperation operation = _GestureOperation.noOperation;
  PointerDownEvent? gestureStart;

  GeometryOperation? geometryOperation;

  // For convenience
  NodeElement get node => widget.node;

  static const unselectedBoxDecoration = BoxDecoration(
    border: Border.fromBorderSide(BorderSide()),
    borderRadius: BorderRadius.all(Radius.circular(5)),
  );
  static const selectedBoxDecoration = BoxDecoration(
    border: Border.fromBorderSide(BorderSide(color: Colors.yellow)),
    borderRadius: BorderRadius.all(Radius.circular(5)),
  );

  @override
  void initState() {
    super.initState();

    geometry = node.geometry;

    node.addListener(
      this,
      (event) => setState(() => geometry = event.geometry ?? node.geometry),
    );
  }

  @override
  void dispose() {
    super.dispose();

    node.removeListener(this);
  }

  bool isSimpleClick(PointerEvent event) {
    if (gestureStart != null) {
      var gestureTime = event.timeStamp - gestureStart!.timeStamp;
      var gestureDistance = (event.position - gestureStart!.position).distance
          .abs();

      return gestureTime < const Duration(milliseconds: 100) &&
          gestureDistance < 10;
    } else {
      return false;
    }
  }

  void beginGesture(PointerDownEvent event) {
    if (node.isSelected && event.buttons == gestures.kPrimaryButton) {
      operation = _GestureOperation.potentialDrag;
      widget.disableParentTransform();
      gestureStart = event;
    } else if (!node.isSelected && event.buttons == gestures.kPrimaryButton) {
      operation = _GestureOperation.beingSelected;
    }
  }

  void clearGestureData() {
    operation = _GestureOperation.noOperation;
    widget.enableParentTransform();
    gestureStart = null;
    geometryOperation?.cancel();
    geometryOperation = null;
  }

  void handlePointerMove(PointerMoveEvent event) {
    switch (operation) {
      case _GestureOperation.potentialDrag:
        if (!isSimpleClick(event)) {
          operation = _GestureOperation.activeDrag;
          geometryOperation = node.beginDrag();
          geometryOperation!.performOperation(
            event.localPosition - gestureStart!.localPosition,
          );
        }

      case _GestureOperation.activeDrag:
        geometryOperation!.performOperation(
          event.localPosition - gestureStart!.localPosition,
        );

      default:
        break;
    }
  }

  void endGesture(PointerUpEvent event) {
    switch (operation) {
      case _GestureOperation.beingSelected:
      case _GestureOperation.potentialDrag:
        if (isSimpleClick(event)) {
          node.selectToggle(true);
        }

      case _GestureOperation.activeDrag:
        geometryOperation!.applyUpdate();

      default:
        break;
    }

    clearGestureData();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fromRect(
      rect: geometry.rect,
      child: Listener(
        onPointerDown: beginGesture,
        onPointerCancel: (_) => clearGestureData(),
        onPointerMove: handlePointerMove,
        onPointerUp: endGesture,
        child: Container(
          decoration: node.isSelected
              ? selectedBoxDecoration
              : unselectedBoxDecoration,
          child: Center(child: Text(widget.node.toString())),
        ),
      ),
    );
  }
}

enum _GestureOperation { noOperation, beingSelected, potentialDrag, activeDrag }
