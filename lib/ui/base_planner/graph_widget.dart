import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/ui/base_planner/edge_widget.dart';
import 'package:factorio_ratios/ui/base_planner/node_widget.dart';
import 'package:factorio_ratios/ui/base_planner/base_planner_widget.dart';
import 'package:flutter/material.dart';

class GraphWidget extends StatefulWidget {
  final Graph graph;

  const GraphWidget({super.key, required this.graph});

  @override
  State<GraphWidget> createState() => _GraphWidgetState();
}

class _GraphWidgetState extends State<GraphWidget> {
  @override
  Widget build(BuildContext context) {
    // return SizedBox(
    //   width: 1000,
    //   height: 800,
    //   child: Stack(
    //     children: [
    //       GestureDetector(
    //         behavior: HitTestBehavior.opaque,
    //         onTap: () {
    //           widget.graphChangeNotifier.toggleSelectionMenu();
    //         },
    //       ),
    //       ...edgeWidgets.values,
    //       ...nodeWidgets.values,
    //     ],
    //   ),
    // );

    return Placeholder();
  }
}
