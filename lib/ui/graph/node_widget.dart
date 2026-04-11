import 'package:factorio_ratios/factorio/graph.dart';
import 'package:flutter/material.dart';

class NodeWidget extends StatefulWidget {
  final ProdLineNode node;

  const NodeWidget({super.key, required this.node});

  @override
  State<NodeWidget> createState() => _NodeWidgetState();
}

class _NodeWidgetState extends State<NodeWidget> {
  @override
  void initState() {
    super.initState();

    // All relevant state is stored within node object
    widget.node.addListener((isRollback, event) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fromRect(
      rect: widget.node.rect,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Center(child: Text(widget.node.toString())),
      ),
    );
  }
}
