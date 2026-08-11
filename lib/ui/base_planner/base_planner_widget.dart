import 'dart:collection';

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
  BasePlanner get basePlanner => widget.basePlanner;

  final Queue<GraphWidgetPersistentState> graphStack = Queue();
  late GraphWidget graphWidget;

  @override
  void initState() {
    super.initState();

    basePlanner.addListener(onSnapshot);

    graphStack.add(GraphWidgetPersistentState(basePlanner.rootGraph));
    graphWidget = GraphWidget(persistentState: graphStack.last);
  }

  @override
  void dispose() {
    super.dispose();

    basePlanner.removeListener(onSnapshot);
  }

  void onSnapshot() {
    if (!basePlanner.activeSnapshot.containsKey(graphStack.last.graph)) {
      graphStack.removeLast();

      while (!basePlanner.activeSnapshot.containsKey(graphStack.last.graph)) {
        graphStack.removeLast();
      }

      setState(() {
        graphWidget = GraphWidget(persistentState: graphStack.last);
      });
    }
  }

  void pushGraph(Graph graph) {
    setState(() {
      var newState = GraphWidgetPersistentState(graph);
      graphStack.addLast(newState);
      graphWidget = GraphWidget(persistentState: newState);
    });
  }

  void popGraph() {
    if (graphStack.length > 1) {
      setState(() {
        graphStack.removeLast();
        graphWidget = GraphWidget(persistentState: graphStack.last);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return graphWidget;
  }
}
