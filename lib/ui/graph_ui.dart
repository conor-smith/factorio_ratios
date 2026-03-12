import 'package:factorio_ratios/factorio/graph.dart';
import 'package:factorio_ratios/factorio/models.dart';
import 'package:factorio_ratios/factorio/production_line.dart';
import 'package:factorio_ratios/ui/factorio_menu.dart';
import 'package:flutter/material.dart';

class TopLevelGraphWidget extends StatefulWidget {
  final FactorioDatabase db;
  final BaseGraph topLevelGraph = BaseGraph();

  TopLevelGraphWidget({super.key, required this.db});

  @override
  State<TopLevelGraphWidget> createState() => _TopLevelGraphWidgetState();
}

class _TopLevelGraphWidgetState extends State<TopLevelGraphWidget> {
  final List<CraftingMachine> sortedMachines = [];
  final Map<Surface, List<Recipe>> defaultSurfaceRecipes = {};
  final Map<Surface, List<Item>> surfaceFuels = {};

  bool selectionMenuActive = false;
  late BaseGraph currentGraph = widget.topLevelGraph;
  // TODO - Account for multiple surfaces
  late Map<BaseGraph, Surface?> graphToSurface = {
    widget.topLevelGraph: widget.db.surfaceMap['nauvis'],
  };

  @override
  void initState() {
    super.initState();

    sortedMachines.addAll(widget.db.craftingMachineMap.values);
    sortedMachines.sort(
      (machine1, machine2) =>
          machine1.craftingSpeed.compareTo(machine2.craftingSpeed),
    );

    for (var surface in widget.db.surfaceMap.values) {
      defaultSurfaceRecipes[surface] = surface.recipes
          .where(
            (recipe) =>
                !recipe.categories.contains('recycling') &&
                recipe.itemIo.entries
                        .where((entry) => entry.value > 0)
                        .length ==
                    1,
          )
          .toList();

      List<SolidItem> surfaceResourceFuels = surface.resourceItems
          .whereType<SolidItem>()
          .where((item) => item.fuelValue != null)
          .toList();
      surfaceResourceFuels.sort(
        (fuel1, fuel2) => fuel1.fuelValue!.compareTo(fuel2.fuelValue!),
      );

      surfaceFuels[surface] = surfaceResourceFuels;
    }
  }

  void addConsumerNode(Item item) {
    setState(() {
      selectionMenuActive = false;

      var newNode = ProdLineNode.addToGraph(
        parentGraph: currentGraph,
        type: NodeType.consumer,
        line: IoLine(inputs: {ItemData(item)}),
      );

      _createRecipeTree(newNode);
    });
  }

  void _createRecipeTree(ProdLineNode parentNode) {
    for (var input in parentNode.allInputs) {
      var childNode = findExistingNode(input);

      if (childNode == null) {
        var surface = graphToSurface[currentGraph]!;

        childNode =
            createResourceNode(input, surface) ??
            createRecipeNode(input, surface) ??
            createProducerNode(input);

        _createRecipeTree(childNode);
      }

      if (!childNode.children.any((edge) => edge.child == childNode)) {
        DirectedEdge.addToGraph(
          parentGraph: currentGraph,
          item: input,
          parent: parentNode,
          child: childNode,
          edgeType: Relationship.requestItems,
        );
      }
    }
  }

  ProdLineNode? findExistingNode(ItemData itemData) {
    return currentGraph.nodes
        .where((node) => node.allOutputs.contains(itemData))
        .firstOrNull;
  }

  ProdLineNode? createResourceNode(ItemData itemData, Surface surface) {
    if (surface.resourceItems.contains(itemData.item)) {
      return ProdLineNode.addToGraph(
        parentGraph: currentGraph,
        type: NodeType.producer,
        line: IoLine(outputs: {itemData}),
      );
    } else {
      return null;
    }
  }

  ProdLineNode? createRecipeNode(ItemData itemData, Surface surface) {
    // TODO - account for null surface
    var producerRecipe = defaultSurfaceRecipes[surface]!
        .where(
          (recipe) =>
              itemData.item.producedBy.contains(recipe) &&
              (recipe.itemIo[itemData.item] ?? -1) > 0,
        )
        .firstOrNull;

    if (producerRecipe != null) {
      // If recipe exists, create production line node
      var fastestMachine = sortedMachines.firstWhere(
        (machine) => machine.recipes.contains(producerRecipe),
      );

      ItemData? fuel;
      if (fastestMachine.energySource.type == EnergySourceType.burner) {
        BurnerEnergySource energySource =
            fastestMachine.energySource as BurnerEnergySource;

        // TODO - Account for surfaces without available fuel
        fuel = ItemData(
          surfaceFuels[surface]!.firstWhere(
            (fuel) => energySource.fuelItems.contains(fuel),
          ),
        );
      }

      return ProdLineNode.addToGraph(
        parentGraph: currentGraph,
        type: NodeType.productionLine,
        line: SingleRecipeLine(
          MutableModuledMachineAndRecipe(
            craftingMachine: fastestMachine,
            recipe: producerRecipe,
            fuel: fuel,
          ).makeImmutable(),
        ),
      );
    } else {
      return null;
    }
  }

  ProdLineNode createProducerNode(ItemData itemData) {
    return ProdLineNode.addToGraph(
      parentGraph: currentGraph,
      type: NodeType.producer,
      line: IoLine(outputs: {itemData}),
    );
  }

  @override
  Widget build(BuildContext context) {
    var graphWidget = GraphWidget(graph: currentGraph);

    List<Widget> children;
    if (selectionMenuActive) {
      children = [
        graphWidget,
        Center(
          child: FactorioGroupMenuWidget<Item>(
            items: widget.db.itemMap.values
                .where((item) => !item.hidden && item.producedBy.isNotEmpty)
                .toList(),
            onSelected: addConsumerNode,
          ),
        ),
      ];
    } else {
      children = [
        GestureDetector(
          onTap: () => setState(() {
            selectionMenuActive = true;
          }),
          child: graphWidget,
        ),
      ];
    }

    children.add(
      Positioned(
        left: 0,
        top: 0,
        child: TextButton(
          onPressed: () => setState(() {
            for (var node in List.from(currentGraph.nodes)) {
              node.removeFromGraph();
            }
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
    );

    return Stack(children: children);
  }
}

class GraphWidget extends StatelessWidget {
  final BaseGraph graph;

  GraphWidget({super.key, required this.graph}) {
    var nodeHeights = graph.getNodeHeights(graph.nodes);

    for (var y = 0; y < nodeHeights.length; y++) {
      for (var x = 0; x < nodeHeights[y].length; x++) {
        Offset topLeft = Offset(
          (ProdLineNode.defaultWidth + ProdLineNode.defaultOffset) * x +
              ProdLineNode.defaultOffset,
          (ProdLineNode.defaultHeight + ProdLineNode.defaultOffset) * y +
              ProdLineNode.defaultOffset,
        );
        Offset bottomRight = Offset(
          topLeft.dx + ProdLineNode.defaultWidth,
          topLeft.dy + ProdLineNode.defaultHeight,
        );
        nodeHeights[y][x].updateOffsets(topLeft, bottomRight);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var edgeWidgets = graph.edges
        .map((edge) => EdgeWidget(edge: edge))
        .toList();
    var nodeWidgets = graph.nodes
        .map((node) => NodeWidget(node: node))
        .toList();

    return InteractiveViewer(
      child: Stack(children: [...edgeWidgets, ...nodeWidgets]),
    );
  }
}

class NodeWidget extends StatelessWidget {
  final ProdLineNode node;

  const NodeWidget({super.key, required this.node});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: node.topLeft.dx,
      top: node.topLeft.dy,
      width: node.bottomRight.dx - node.topLeft.dx,
      height: node.bottomRight.dy - node.topLeft.dy,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Center(child: Text(node.toString())),
      ),
    );
  }
}

class EdgeWidget extends StatelessWidget {
  final DirectedEdge edge;

  const EdgeWidget({super.key, required this.edge});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: LinesPainter(start: edge.lines[0], end: edge.lines[1]),
    );
  }
}

class LinesPainter extends CustomPainter {
  final Offset start, end;

  LinesPainter({required this.start, required this.end});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      start,
      end,
      Paint()
        ..strokeWidth = 2
        ..color = Colors.black,
    );
  }

  @override
  bool shouldRepaint(covariant LinesPainter oldDelegate) {
    return oldDelegate.start != start || oldDelegate.end != end;
  }
}
