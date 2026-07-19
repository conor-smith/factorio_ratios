import 'package:factorio_ratios/factorio/base_planner/geometry/node_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/node/node.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class NodeWidget extends StatefulWidget {
  final NodeElement node;

  const NodeWidget({super.key, required this.node});

  @override
  State<NodeWidget> createState() => _NodeWidgetState();
}

class _NodeWidgetState extends State<NodeWidget> {
  late NodeGeometry geometry;

  int? pointerDownButton;

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
        onPointerDown: (event) => pointerDownButton = event.buttons,
        onPointerCancel: (_) => pointerDownButton = null,
        onPointerUp: (_) {
          if (pointerDownButton == kPrimaryButton) {
            node.selectToggle(true);
          }
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
