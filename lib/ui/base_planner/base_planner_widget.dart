import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/ui/base_planner/graph_widget.dart';
import 'package:flutter/material.dart';

class BasePlannerWidget extends StatefulWidget {
  final BasePlanner basePlanner;

  const BasePlannerWidget({super.key, required this.basePlanner});

  @override
  State<BasePlannerWidget> createState() => _BasePlannerWidgetState();
}

class _BasePlannerWidgetState extends State<BasePlannerWidget> {
  late Graph activeGraph;

  BasePlanner get basePlanner => widget.basePlanner;

  @override
  void initState() {
    super.initState();

    activeGraph = basePlanner.activeGraph;

    basePlanner.addListener(
      this,
      (_) => setState(() => activeGraph = basePlanner.activeGraph),
    );
  }

  @override
  void dispose() {
    super.dispose();

    basePlanner.removeListener(this);
  }

  @override
  Widget build(BuildContext context) {
    return GraphWidget(graph: activeGraph);
  }
}
