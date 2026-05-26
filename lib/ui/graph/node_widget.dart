import 'package:factorio_ratios/factorio/graph/graph.dart';
import 'package:factorio_ratios/factorio/graph/state/state.dart';
import 'package:factorio_ratios/ui/graph/factorio_base_widget.dart';
import 'package:flutter/material.dart';

class NodeWidget extends StatefulWidget {
  final ProdLineNode node;

  final GraphChangeNotifier graphChangeNotifier;

  const NodeWidget({
    super.key,
    required this.node,
    required this.graphChangeNotifier,
  });

  @override
  State<NodeWidget> createState() => _NodeWidgetState();
}

class _NodeWidgetState extends State<NodeWidget> {
  bool selected = false;

  static const unselectedBoxDecoration = BoxDecoration(
    border: Border.fromBorderSide(BorderSide()),
    borderRadius: BorderRadius.all(Radius.circular(5)),
  );
  static const selectedBoxDecoration = BoxDecoration(
    border: Border.fromBorderSide(BorderSide(color: Colors.yellow)),
    borderRadius: BorderRadius.all(Radius.circular(5)),
  );

  @override
  void initState() {
    super.initState();

    widget.node.addListener((event) {
      if (event.mutations.contains(NodeEventType.selectToggle)) {
        selected = event.selected!;
      }

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
        decoration: selected ? selectedBoxDecoration : unselectedBoxDecoration,
        child: GestureDetector(
          onTapUp: (details) =>
              widget.graphChangeNotifier.selectNode(widget.node),
          child: Center(child: Text(widget.node.toString())),
        ),
      ),
    );
  }
}
