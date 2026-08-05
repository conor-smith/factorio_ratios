import 'dart:collection';

import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/ui/base_planner/graph_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BasePlannerWidget extends StatefulWidget {
  final BasePlanner basePlanner;

  const BasePlannerWidget({super.key, required this.basePlanner});

  @override
  State<BasePlannerWidget> createState() => _BasePlannerWidgetState();
}

class _BasePlannerWidgetState extends State<BasePlannerWidget> {
  BasePlanner get basePlanner => widget.basePlanner;

  FocusNode focusNode = FocusNode();

  final Queue<GraphWidgetPersistentState> graphStack = Queue();
  late GraphWidget graphWidget;

  Widget? overlayMenu;

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
    focusNode.dispose();
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

    if (overlayMenu != null) {
      setState(() {
        overlayMenu = null;
        focusNode.unfocus(
          disposition: UnfocusDisposition.previouslyFocusedChild,
        );
      });
    }
  }

  void pushOverlayMenu(Widget newMenu) => setState(() {
    focusNode.requestFocus();
    overlayMenu = newMenu;
  });

  void clearOverlayMenu() {
    if (overlayMenu != null) {
      setState(() {
        overlayMenu = null;
        focusNode.unfocus(
          disposition: UnfocusDisposition.previouslyFocusedChild,
        );
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
    List<Widget> children = [graphWidget];

    if (overlayMenu != null) {
      children
        ..add(
          Listener(
            behavior: HitTestBehavior.opaque,
            onPointerUp: (_) => clearOverlayMenu(),
          ),
        )
        ..add(overlayMenu!);
    }

    return KeyboardListener(
      focusNode: focusNode,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          clearOverlayMenu();
        }
      },
      child: Stack(fit: StackFit.expand, children: children),
    );
  }
}

_BasePlannerWidgetState _getStateOrThrow(BuildContext context) {
  var state = context.findAncestorStateOfType<_BasePlannerWidgetState>();

  if (state == null) {
    throw const BasePlannerException('BasePlannerWidget not found in tree');
  }

  return state;
}

void pushOverlayMenu(BuildContext context, Widget newMenu) =>
    _getStateOrThrow(context).pushOverlayMenu(newMenu);
void clearOverlayMenu(BuildContext context) =>
    _getStateOrThrow(context).clearOverlayMenu();
