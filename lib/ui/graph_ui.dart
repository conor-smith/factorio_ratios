import 'package:factorio_ratios/factorio/graph.dart';
import 'package:factorio_ratios/factorio/models.dart';
import 'package:flutter/material.dart';

class GraphUi extends StatefulWidget {
  final BaseGraph base = BaseGraph();
  final FactorioDatabase db;

  GraphUi({super.key, required this.db});

  @override
  State<GraphUi> createState() => _GraphUiState();
}

class _GraphUiState extends State<GraphUi> {
  final List<Widget> children = [];

  double currentX = 0;
  double currentY = 0;
  bool dropDownActive = false;

  @override
  void initState() {
    super.initState();

    Map<String, String> nameToDisplayName = {};
    widget.db.itemMap.forEach((name, item) {
      nameToDisplayName[name] = item.localisedName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: Stack(children: children),
    );
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
      width: 200,
      height: 100,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.lightBlueAccent,
          border: BoxBorder.all(color: Colors.black, width: 1),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Center(child: Text('${widget.node.productionLine}')),
      ),
    );
  }
}
