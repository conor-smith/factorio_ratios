import 'package:factorio_ratios/factorio/graph/graph.dart';
import 'package:factorio_ratios/factorio/graph/state/state.dart';
import 'package:factorio_ratios/ui/graph/edge_widget.dart';
import 'package:factorio_ratios/ui/graph/node_widget.dart';
import 'package:factorio_ratios/ui/graph/factorio_base_widget.dart';
import 'package:flutter/material.dart';

class GraphWidget extends StatefulWidget {
  final PlanetBaseGraph graph;

  const GraphWidget({super.key, required this.graph});

  @override
  State<GraphWidget> createState() => _GraphWidgetState();
}

class _GraphWidgetState extends State<GraphWidget> {
  final Map<ProdLineNode, NodeWidget> nodeWidgets = {};
  final Map<DirectedEdge, EdgeWidget> edgeWidgets = {};

  void processEvent(GraphEvent event) {
    for (var mutation in event.mutations) {
      switch (mutation) {
        case GraphEventType.geometryUpdate:
          resetSize();

        case GraphEventType.updateNodes:
          for (var removedNode in event.removedNodes) {
            removedNode.clearListeners();
            nodeWidgets.remove(removedNode);
          }
          for (var newNode in event.addedNodes) {
            nodeWidgets[newNode] = NodeWidget(node: newNode);
          }

        case GraphEventType.updateEdges:
          for (var removedEdge in event.removedEdges) {
            removedEdge.clearListeners();
            edgeWidgets.remove(removedEdge);
          }
          for (var newEdge in event.addedEdges) {
            edgeWidgets[newEdge] = EdgeWidget(edge: newEdge);
          }

        default:
          break;
      }
    }
  }

  void resetSize() {
    // TODO
  }

  @override
  void initState() {
    super.initState();

    for (var node in widget.graph.nodes) {
      nodeWidgets[node] = NodeWidget(node: node);
    }

    for (var edge in widget.graph.edges) {
      edgeWidgets[edge] = EdgeWidget(edge: edge);
    }

    widget.graph.addListener((event) {
      if (mounted) {
        setState(() => processEvent(event));
      } else {
        processEvent(event);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1000,
      height: 800,
      child: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              var overlayNotifier = FactorioBaseWidget.getOverlayNotifier(
                context,
              );
              overlayNotifier.toggleSelectionMenu();
            },
          ),
          ...edgeWidgets.values,
          ...nodeWidgets.values,
        ],
      ),
    );
  }
}
