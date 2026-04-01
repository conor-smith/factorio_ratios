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

  @override
  void initState() {
    super.initState();

    for (var node in widget.graph.nodes) {
      nodeWidgets[node] = NodeWidget(node: node);
    }

    for (var edge in widget.graph.edges) {
      edgeWidgets[edge] = EdgeWidget(edge: edge);
    }

    widget.graph.addListener(
      () => setState(() {
        var stateUpdate = widget.graph.value;

        for (var newNode in stateUpdate.newNodes) {
          nodeWidgets[newNode] = NodeWidget(node: newNode);
        }
        for (var oldNode in stateUpdate.removedNodes) {
          nodeWidgets.remove(oldNode);
        }

        for (var newEdge in stateUpdate.newEdges) {
          edgeWidgets[newEdge] = EdgeWidget(edge: newEdge);
        }
        for (var oldEdge in stateUpdate.removedEdges) {
          edgeWidgets.remove(oldEdge);
        }

        // TODO - this is temporary
        widget.graph.treeLayout(updateNodeListeners: true);
      }),
    );
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
              widget.graph.clear();
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
