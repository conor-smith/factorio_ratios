import 'package:factorio_ratios/factorio/graph.dart';
import 'package:factorio_ratios/ui/graph/edge_widget.dart';
import 'package:factorio_ratios/ui/graph/node_widget.dart';
import 'package:flutter/material.dart';

class GraphWidget extends StatefulWidget {
  final BaseGraph graph;

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
        case GraphEventType.positionalNodesUpdate:
          resetSize();

        case GraphEventType.updateNodes:
          for (var removedNode in event.removedNodes) {
            removedNode.clearListeners();
            nodeWidgets.remove(removedNode);
          }
          for (var newNode in event.newNodes) {
            nodeWidgets[newNode] = NodeWidget(node: newNode);
          }

        case GraphEventType.updateEdges:
          for (var removedEdge in event.removedEdges) {
            removedEdge.clearListeners();
            edgeWidgets.remove(removedEdge);
          }
          for (var newEdge in event.newEdges) {
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

    widget.graph.addListener((isRollback, event) {
      event = isRollback ? event.reversed : event;
      if (mounted) {
        setState(() => processEvent(event));
      } else {
        processEvent(event);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children;
    if (widget.graph.nodes.isNotEmpty) {
      children = [
        ...nodeWidgets.values,
        ...edgeWidgets.values,
        Positioned(
          left: widget.graph.topLeft.dx,
          top: widget.graph.topLeft.dy,
          child: TextButton(
            onPressed: () => setState(() {
              widget.graph.clearAllNodes();
              nodeWidgets.clear();
              edgeWidgets.clear();
            }),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(),
                borderRadius: BorderRadius.circular(2),
                color: Colors.redAccent,
              ),
              child: const Text('X'),
            ),
          ),
        ),
      ];
    } else {
      children = const [];
    }

    // TODO - Account for nodes existing at negative values
    return SizedBox(
      width: widget.graph.bottomRight.dx,
      height: widget.graph.bottomRight.dy,
      child: Stack(children: children),
    );
  }
}
