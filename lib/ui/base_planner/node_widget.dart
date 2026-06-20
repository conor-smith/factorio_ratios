import 'dart:developer';

import 'package:factorio_ratios/factorio/base_planner/node/node.dart';
import 'package:factorio_ratios/ui/base_planner/base_planner_widget.dart';
import 'package:flutter/material.dart';

class NodeWidget extends StatefulWidget {
  final NodeElement node;

  const NodeWidget({super.key, required this.node});

  @override
  State<NodeWidget> createState() => _NodeWidgetState();
}

class _NodeWidgetState extends State<NodeWidget> {
  @override
  Widget build(BuildContext context) {
    // return Positioned.fromRect(
    //   rect: geometry.minimalRect,
    //   child: Container(
    //     decoration: selected ? selectedBoxDecoration : unselectedBoxDecoration,
    //     child: GestureDetector(
    //       onTapDown: (details) {
    //         if (!selected) {
    //           widget.graphChangeNotifier.selectNode(widget.node);
    //         }
    //       },
    //       onHorizontalDragStart: (details) {
    //         geometryOp = widget.graphChangeNotifier.drag();
    //         startPosition = details.globalPosition;
    //       },
    //       onHorizontalDragUpdate: (details) {
    //         geometryOp!.drag(details.globalPosition - startPosition!);
    //       },
    //       onHorizontalDragEnd: (details) {
    //         widget.graphChangeNotifier.finishGeometryOperation(geometryOp!);
    //         geometryOp = null;
    //         startPosition = null;
    //       },
    //       child: Center(child: Text(widget.node.toString())),
    //     ),
    //   ),
    // );

    return Placeholder();
  }
}
