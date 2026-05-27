import 'dart:developer';

import 'package:factorio_ratios/factorio/graph/geometry/geometry.dart';
import 'package:factorio_ratios/factorio/graph/graph.dart';
import 'package:factorio_ratios/factorio/graph/state/state.dart';
import 'package:factorio_ratios/ui/graph/factorio_base_widget.dart';
import 'package:flutter/material.dart';

class NodeWidget extends StatefulWidget {
  final ProdLineNode node;

  final GraphChangeNotifier graphChangeNotifier;

  const NodeWidget({
    super.key,
    required this.node,
    required this.graphChangeNotifier,
  });

  @override
  State<NodeWidget> createState() => _NodeWidgetState();
}

class _NodeWidgetState extends State<NodeWidget> {
  bool selected = false;
  late NodeGeometry geometry;

  GeometryOperation? geometryOp;
  Offset? startPosition;

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

    geometry = widget.node.geometry;

    widget.node.addListener((event) {
      for (var mutation in event.mutations) {
        switch (mutation) {
          case NodeEventType.selectToggle:
            selected = event.selected!;

          case NodeEventType.tempGeometry:
          case NodeEventType.updateGeometry:
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
    return Positioned.fromRect(
      rect: geometry.minimalRect,
      child: Container(
        decoration: selected ? selectedBoxDecoration : unselectedBoxDecoration,
        child: GestureDetector(
          onTapDown: (details) {
            if (!selected) {
              widget.graphChangeNotifier.selectNode(widget.node);
            }
          },
          onHorizontalDragStart: (details) {
            geometryOp = widget.graphChangeNotifier.drag();
            startPosition = details.globalPosition;
          },
          onHorizontalDragUpdate: (details) {
            geometryOp!.drag(details.globalPosition - startPosition!);
          },
          onHorizontalDragEnd: (details) {
            widget.graphChangeNotifier.finishGeometryOperation(geometryOp!);
            geometryOp = null;
            startPosition = null;
          },
          child: Center(child: Text(widget.node.toString())),
        ),
      ),
    );
  }
}
