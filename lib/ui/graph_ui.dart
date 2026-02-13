import 'package:factorio_ratios/factorio/graph.dart';
import 'package:factorio_ratios/factorio/models.dart';
import 'package:flutter/material.dart';

class GraphUi extends StatefulWidget {
  final PlanetaryBase base = PlanetaryBase();
  final FactorioDatabase db;

  GraphUi({super.key, required this.db});

  @override
  State<GraphUi> createState() => _GraphUiState();
}

class _GraphUiState extends State<GraphUi> {

  Map<ProdLineNode, NodeWidget> nodeWidgets = {};
  Map<DirectedEdge, EdgeWidget> edgeWidgets = {};

  @override
  Widget build(BuildContext context) {
    return Placeholder();
  }
}

class NodeWidget extends StatefulWidget {
  final ProdLineNode node;

  const NodeWidget({super.key, required this.node});

  @override
  State<NodeWidget> createState() => _NodeWidgetState();
}

class _NodeWidgetState extends State<NodeWidget> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
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
