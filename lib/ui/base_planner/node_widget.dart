import 'package:factorio_ratios/factorio/base_planner/geometry/geometry_operation.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/node_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/node/node.dart';
import 'package:flutter/gestures.dart';
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

  _PointerOperation operation = _PointerOperation.noOperation;
  PointerDownEvent? dragOperationStart;

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

  @override
  Widget build(BuildContext context) {
    var selected = node.isSelected;

    return Positioned.fromRect(
      rect: geometry.rect,
      child: Listener(
        onPointerDown: (event) {
          // TODO - Clean up
          if (selected && event.buttons == kPrimaryButton) {
            operation = _PointerOperation.potentialDrag;
            widget.disableParentTransform();
            dragOperationStart = event;
          } else if (!selected && event.buttons == kPrimaryButton) {
            operation = _PointerOperation.beingSelected;
          }
        },
        onPointerCancel: (_) {
          operation = _PointerOperation.noOperation;
          widget.enableParentTransform();
          dragOperationStart = null;
          geometryOperation?.cancel();
          geometryOperation = null;
        },
        onPointerMove: (event) {
          if (operation == _PointerOperation.potentialDrag) {
            var timeSinceStart =
                event.timeStamp - dragOperationStart!.timeStamp;
            var distanceOnScreen =
                (event.position - dragOperationStart!.position).distance.abs();

            if (timeSinceStart > const Duration(milliseconds: 100) ||
                distanceOnScreen > 10) {
              operation = _PointerOperation.activeDrag;
              geometryOperation = node.beginDrag();
              geometryOperation!.performOperation(
                event.localPosition - dragOperationStart!.localPosition,
              );
            }
          } else if (operation == _PointerOperation.activeDrag) {
            geometryOperation!.performOperation(
              event.localPosition - dragOperationStart!.localPosition,
            );
          }
        },
        onPointerUp: (_) {
          switch (operation) {
            case _PointerOperation.beingSelected:
            case _PointerOperation.potentialDrag:
              node.selectToggle(true);

            case _PointerOperation.activeDrag:
              geometryOperation!.applyUpdate();

            default:
              break;
          }

          operation = _PointerOperation.noOperation;
          widget.enableParentTransform();
          dragOperationStart = null;
          geometryOperation = null;
        },
        child: Container(
          decoration: selected
              ? selectedBoxDecoration
              : unselectedBoxDecoration,
          child: Center(child: Text(widget.node.toString())),
        ),
      ),
    );
  }
}

enum _PointerOperation { noOperation, beingSelected, potentialDrag, activeDrag }
