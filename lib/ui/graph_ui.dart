import 'package:factorio_ratios/factorio/graph.dart';
import 'package:factorio_ratios/factorio/models.dart';
import 'package:factorio_ratios/factorio/production_line.dart';
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (tapUpDetails) {
        Item sciencePack = widget.db.itemMap['automation-science-pack']!;

        widget.base.addOutputNode(ItemData(sciencePack));

        setState(() {
          addGraphUpdates(
            widget.base.updates,
            x: tapUpDetails.localPosition.dx,
            y: tapUpDetails.localPosition.dy,
          );
        });
      },
      child: Stack(
        children: nodeWidgets.values.toList(),
      ),
    );
  }

  void addGraphUpdates(GraphUpdates updates, {double x = 0, double y = 0}) {
    for (var newNode in updates.newNodes) {
      var newNodeWidget = NodeWidget(
        node: newNode, 
        initialX: x,
        initialY: y);
      
      nodeWidgets[newNode] = newNodeWidget;
      y += 120;
    }
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
    return Positioned(
      left: x,
      top: y,
      child: SizedBox(
        width: 100,
        height: 100,
        child: Center(
          child: const Text('Test'),
        ),
      ));
  }
}
