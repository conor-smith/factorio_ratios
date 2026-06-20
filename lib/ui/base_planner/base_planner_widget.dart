import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/factorio/models/models.dart';
import 'package:factorio_ratios/ui/factorio_menu.dart';
import 'package:factorio_ratios/ui/base_planner/graph_widget.dart';
import 'package:flutter/material.dart';

class BasePlannerWidget extends StatefulWidget {
  final BasePlanner base;

  const BasePlannerWidget({super.key, required this.base});

  @override
  State<BasePlannerWidget> createState() => _BasePlannerWidgetState();
}

class _BasePlannerWidgetState extends State<BasePlannerWidget> {
  @override
  Widget build(BuildContext context) {
    // List<Widget> children = [
    //   graphWidgets.putIfAbsent(
    //     activeGraph,
    //     () => GraphWidget(
    //       graph: activeGraph,
    //       graphChangeNotifier: graphChangeNotifier,
    //     ),
    //   ),
    // ];

    // if (selectionMenuActive) {
    //   children.add(Center(child: menuWidget));
    // }

    // return Stack(children: children);

    return Placeholder();
  }
}
