import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/edge/edge.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/factorio/base_planner/node/node.dart';
import 'package:factorio_ratios/ui/base_planner/base_planner_widget.dart';
import 'package:factorio_ratios/ui/base_planner/edge_widget.dart';
import 'package:factorio_ratios/ui/base_planner/node_widget.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class GraphWidget extends StatefulWidget {
  final Graph graph;

  const GraphWidget({super.key, required this.graph});

  @override
  State<GraphWidget> createState() => _GraphWidgetState();
}

class _GraphWidgetState extends State<GraphWidget> {
  final Map<NodeElement, NodeWidget> nodeWidgets = {};
  final Map<Edge, EdgeWidget> edgeWidgets = {};
  final TransformationController controller = TransformationController();

  Rect minBounds = Rect.zero;
  int? pointerDownButton;

  Graph get graph => widget.graph;

  @override
  void initState() {
    super.initState();

    for (var node in graph.allNodes) {
      nodeWidgets[node] = NodeWidget(node: node);
    }
    for (var edge in graph.edges) {
      edgeWidgets[edge] = EdgeWidget(edge: edge);
    }

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
      case GraphEventType.updateNodesAndEdges:
        setState(() {
          addNewElements(event);
          updateMinBounds();
        });
      case GraphEventType.childrenGeometryUpdate:
        setState(() {
          updateMinBounds();
        });
      case GraphEventType.nodeEvent:
        // Do nothing
        break;
    }
  }

  void addNewElements(GraphEvent event) {
    for (var newNode in event.newNodes) {
      nodeWidgets[newNode] = NodeWidget(node: newNode);
    }
    for (var newEdge in event.newEdges) {
      edgeWidgets[newEdge] = EdgeWidget(edge: newEdge);
    }

    for (var removedNode in event.removedNodes) {
      nodeWidgets.remove(removedNode);
    }
    for (var removedEdge in event.removedEdges) {
      edgeWidgets.remove(removedEdge);
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
      child: Stack(
        children: [
          ...nodeWidgets.values,
          ...edgeWidgets.values,
          Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (event) {
              pointerDownButton = event.buttons;
            },
            onPointerCancel: (event) => pointerDownButton = null,
            onPointerUp: (event) {
              if (pointerDownButton == kSecondaryButton) {
                BasePlannerGlobalState.of(
                  context,
                ).toggleContextMenu(event.position);
              }

              pointerDownButton = null;
            },
          ),
        ],
      ),
    );
  }
}
