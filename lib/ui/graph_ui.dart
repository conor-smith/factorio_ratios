import 'package:factorio_ratios/factorio/graph.dart';
import 'package:factorio_ratios/factorio/models.dart';
import 'package:factorio_ratios/ui/factorio_menu.dart';
import 'package:flutter/material.dart';

// TODO - Tweak this. Maybe make dynamic
const double initNodeWidth = 120;
const double initNodeHeight = 120;

class TopLevelGraphWidget extends StatefulWidget {
  final FactorioDatabase db;
  final BaseGraph topLevelGraph = BaseGraph();

  TopLevelGraphWidget({super.key, required this.db});

  @override
  State<TopLevelGraphWidget> createState() => _TopLevelGraphWidgetState();
}

class _TopLevelGraphWidgetState extends State<TopLevelGraphWidget> {
  FactorioGroupMenuWidget? selectionMenu;

  @override
  Widget build(BuildContext context) {
    return Placeholder();
  }
}

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

    var orderedNodes = widget.graph.getNodeHeights(widget.graph.nodes);

    for (var y = 0; y < orderedNodes.length; y++) {
      for (var x = 0; x < orderedNodes[y].length; x++) {
        var node = orderedNodes[y][x];
        nodeWidgets[node] = NodeWidget(
          node: node,
          initialX: initNodeWidth * x,
          initialY: initNodeHeight * y,
        );
      }
    }

    for (var edge in widget.graph.edges) {
      edgeWidgets[edge] = EdgeWidget(edge: edge);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class NodeWidget extends StatefulWidget {
  final ProdLineNode node;
  final double initialX;
  final double initialY;

  const NodeWidget({
    super.key,
    required this.node,
    required this.initialX,
    required this.initialY,
  });

  @override
  State<NodeWidget> createState() => _NodeWidgetState();
}

class _NodeWidgetState extends State<NodeWidget> {
  late double x = widget.initialX;
  late double y = widget.initialY;

  @override
  Widget build(BuildContext context) {
    return Placeholder();
  }
}

class EdgeWidget extends StatefulWidget {
  final DirectedEdge edge;

  const EdgeWidget({super.key, required this.edge});

  @override
  State<EdgeWidget> createState() => _EdgeWidgetState();
}

class _EdgeWidgetState extends State<EdgeWidget> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
