import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/ui/base_planner/base_planner_widget.dart';
import 'package:factorio_ratios/ui/base_planner/edge_widget.dart';
import 'package:factorio_ratios/ui/base_planner/node_widget.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class GraphWidget extends StatefulWidget {
  final Graph graph;

  // Made part of widget so it persists even when graph is not active
  final TransformationController _controller = TransformationController();

  GraphWidget({super.key, required this.graph});

  @override
  State<GraphWidget> createState() => _GraphWidgetState();
}

class _GraphWidgetState extends State<GraphWidget> {
  Rect minBounds = Rect.zero;
  PointerDownEvent? gestureStart;

  bool transformEnabled = true;

  Graph get graph => widget.graph;
  TransformationController get controller => widget._controller;

  @override
  void initState() {
    super.initState();

    graph.addListener(this, onEvent);
    updateMinBounds();
  }

  @override
  void dispose() {
    super.dispose();

    graph.removeListener(this);
  }

  void onEvent(GraphEvent event) {
    switch (event.graphEventType) {
      case GraphEventType.update:
        setState(() {});
      case GraphEventType.childrenGeometryUpdate:
        setState(() {
          updateMinBounds();
        });
      case GraphEventType.nodeEvent:
        // Do nothing
        break;
    }
  }

  void addNewElements(GraphEvent event) {}

  void disableTransform() {
    if (transformEnabled) {
      setState(() => transformEnabled = false);
    }
  }

  void enableTransform() {
    if (!transformEnabled) {
      setState(() => transformEnabled = true);
    }
  }

  void updateMinBounds() {
    // var allGeometry = Iterable<BasePlannerElement>.empty()
    //     .followedBy(graph.allNodes)
    //     .followedBy(graph.edges)
    //     .map((element) => element.geometry.rect);

    // if (allGeometry.isEmpty) {
    //   minBounds = Rect.zero;
    // } else {
    //   var first = allGeometry.first;
    //   double left = first.left;
    //   double top = first.top;
    //   double right = first.right;
    //   double bottom = first.bottom;

    //   for (var rect in allGeometry.skip(1)) {
    //     left = rect.left < left ? rect.left : left;
    //     top = rect.top < top ? rect.top : top;
    //     right = rect.right > right ? rect.right : right;
    //     bottom = rect.bottom > bottom ? rect.bottom : bottom;
    //   }

    //   minBounds = Rect.fromLTRB(left, top, right, bottom);
    // }
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: controller,
      panEnabled: transformEnabled,
      scaleEnabled: transformEnabled,
      child: Stack(
        children: [
          Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (event) {
              gestureStart = event;
            },
            onPointerCancel: (event) => gestureStart = null,
            onPointerUp: (event) {
              if (gestureStart?.buttons == kSecondaryButton) {
                BasePlannerGlobalState.of(
                  context,
                ).toggleContextMenu(event.position);
              }

              gestureStart = null;
            },
          ),
          ...graph.allNodes.map(
            (node) => NodeWidget(
              key: BasePlannerElementKey(node),
              node: node,
              disableParentTransform: disableTransform,
              enableParentTransform: enableTransform,
            ),
          ),
          ...graph.edges.map(
            (edge) => EdgeWidget(key: BasePlannerElementKey(edge), edge: edge),
          ),
        ],
      ),
    );
  }
}

class BasePlannerElementKey extends LocalKey {
  final BasePlannerElement element;

  const BasePlannerElementKey(this.element);

  @override
  bool operator ==(Object other) =>
      super == other ||
      (other is BasePlannerElementKey && other.element == element);

  @override
  int get hashCode => element.hashCode;
}
