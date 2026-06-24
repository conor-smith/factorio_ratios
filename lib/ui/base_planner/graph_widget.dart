import 'package:factorio_ratios/factorio/base_planner/edge/edge.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/factorio/base_planner/node/node.dart';
import 'package:factorio_ratios/ui/base_planner/edge_widget.dart';
import 'package:factorio_ratios/ui/base_planner/node_widget.dart';
import 'package:flutter/material.dart';

class GraphWidget extends StatefulWidget {
  final Graph graph;
  final Function toggleConsumerMenu;

  const GraphWidget({
    super.key,
    required this.graph,
    required this.toggleConsumerMenu,
  });

  @override
  State<GraphWidget> createState() => _GraphWidgetState();
}

class _GraphWidgetState extends State<GraphWidget> {
  Graph get graph => widget.graph;

  final Map<NodeElement, NodeWidget> nodeWidgets = {};
  final Map<Edge, EdgeWidget> edgeWidgets = {};

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
  }

  void onEvent(GraphEvent event) {
    switch (event.graphEventType) {
      case GraphEventType.updateNodesAndEdges:
        setState(() {
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
        });
      case GraphEventType.childrenGeometryUpdate:
      case GraphEventType.nodeEvent:
        // Do nothing
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => widget.toggleConsumerMenu(),
        ),
        ...nodeWidgets.values,
        ...edgeWidgets.values,
      ],
    );
  }
}
