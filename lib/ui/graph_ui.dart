import 'package:factorio_ratios/factorio/graph.dart';
import 'package:factorio_ratios/factorio/models.dart';
import 'package:factorio_ratios/factorio/production_line.dart';
import 'package:factorio_ratios/ui/item_dropdown.dart';
import 'package:flutter/material.dart';

class GraphUi extends StatefulWidget {
  final PlanetaryBase base = PlanetaryBase();
  final FactorioDatabase db;

  GraphUi({super.key, required this.db});

  @override
  State<GraphUi> createState() => _GraphUiState();
}

class _GraphUiState extends State<GraphUi> {
  final List<Widget> children = [];
  late final SearchableDropDown itemDropdown;

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

    itemDropdown = SearchableDropDown(
      nameToDisplayName: nameToDisplayName,
      onPressed: (name) => setState(() {
        dropDownActive = false;
        children.removeLast();

        var updates = widget.base.addOutputNode({
          ItemData(widget.db.itemMap[name]!),
        });

        addGraphUpdates(updates, x: currentX, y: currentY);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (tapUpDetails) {
        setState(() {
          currentX = tapUpDetails.localPosition.dx;
          currentY = tapUpDetails.localPosition.dy;

          if (dropDownActive) {
            dropDownActive = false;
            children.removeLast();
          } else {
            dropDownActive = true;
            children.add(
              Positioned(
                left: currentX,
                top: currentY,
                width: 200,
                height: 500,
                child: Container(
                  decoration: BoxDecoration(
                    border: BoxBorder.all(color: Colors.black, width: 1),
                  ),
                  child: itemDropdown,
                ),
              ),
            );
          }
        });
      },
      child: Stack(children: children),
    );
  }

  void addGraphUpdates(GraphUpdates updates, {double x = 0, double y = 0}) {
    for (var newNode in updates.newNodes) {
      var newNodeWidget = NodeWidget(node: newNode, initialX: x, initialY: y);

      children.add(newNodeWidget);
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
