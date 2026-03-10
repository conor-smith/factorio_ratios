import 'package:factorio_ratios/factorio/graph.dart';
import 'package:factorio_ratios/factorio/models.dart';
import 'package:factorio_ratios/factorio/production_line.dart';
import 'package:factorio_ratios/ui/factorio_menu.dart';
import 'package:flutter/material.dart';

// TODO - Tweak this. Maybe make dynamic
const double initNodeWidth = 100;
const double initNodeHeight = 100;
const double initOffset = 20;

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
          edgeType: EdgeType.requestItems,
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

    return Stack(children: children);
  }
}

class GraphWidget extends StatelessWidget {
  final BaseGraph graph;

  const GraphWidget({super.key, required this.graph});

  @override
  Widget build(BuildContext context) {
    List<Widget> nodeWidgets = [];

    var graphTreeHeights = graph.getNodeHeights(graph.nodes);
    for (var y = 0; y < graphTreeHeights.length; y++) {
      for (var x = 0; x < graphTreeHeights[y].length; x++) {
        nodeWidgets.add(
          NodeWidget(
            node: graphTreeHeights[y][x],
            x: x * (initNodeWidth + initOffset),
            y: y * (initNodeHeight + initOffset),
          ),
        );
      }
    }

    return InteractiveViewer(child: Stack(children: nodeWidgets));
  }
}

class NodeWidget extends StatelessWidget {
  final ProdLineNode node;

  final double x;
  final double y;

  const NodeWidget({
    super.key,
    required this.node,
    required this.x,
    required this.y,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x,
      top: y,
      child: Container(
        width: initNodeWidth,
        height: initNodeHeight,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Center(child: Text(node.toString())),
      ),
    );
  }
}

// class GraphWidget extends StatefulWidget {
//   final BaseGraph graph;
//   final FactorioDatabase db;
//   final BaseGraph? parentGraph;
//   // TODO - Account for different planets
//   final Surface? surface;

//   const GraphWidget({
//     super.key,
//     required this.graph,
//     required this.db,
//     this.surface,
//     this.parentGraph,
//   });

//   @override
//   State<GraphWidget> createState() => _GraphWidgetState();
// }

// class _GraphWidgetState extends State<GraphWidget> {
//   final Map<ProdLineNode, NodeWidget> nodeWidgets = {};
//   final Map<DirectedEdge, EdgeWidget> edgeWidgets = {};

//   @override
//   void initState() {
//     super.initState();

//     var nodeTree = widget.graph.getNodeHeights(widget.graph.nodes);

//     _createNodeWidgets(nodeTree);

//     for (var edge in widget.graph.edges) {
//       edgeWidgets[edge] = EdgeWidget(edge: edge);
//     }
//   }

//   void addConsumerNode(ItemData item) {
//     var newNode = ProdLineNode.addToGraph(
//       parentGraph: widget.graph,
//       type: NodeType.consumer,
//       line: IoLine(inputs: {item}),
//     );

//     List<ProdLineNode> connectedNodes = [newNode];
//     List<DirectedEdge> newEdges = [];

//     // TODO - Account for more than one recipe tree being positioned
//     _createRecipeTree(newNode, {}, connectedNodes, newEdges);

//     var nodeHeights = widget.graph.getNodeHeights(connectedNodes);

//     _createNodeWidgets(nodeHeights);

//     for (var newEdge in newEdges) {
//       edgeWidgets.putIfAbsent(newEdge, () => EdgeWidget(edge: newEdge));
//     }
//   }

//   void _createRecipeTree(
//     ProdLineNode parentNode,
//     Set<ProdLineNode> visitedNodes,
//     List<ProdLineNode> connectedNodes,
//     List<DirectedEdge> newEdges,
//   ) {
//     visitedNodes.add(parentNode);

//     List<ProdLineNode> childNodes = [];
//     for (var input in parentNode.allInputs) {
//       // Check for existing node
//       var childNode = parentNode.parentGraph.nodes
//           .where((node) => node.allOutputs.contains(input))
//           .firstOrNull;

//       if (childNode != null) {
//         visitedNodes.add(childNode);
//         childNodes.add(childNode);
//       } else {
//         var producerRecipe = input.item.producedBy
//             .where(
//               (recipe) =>
//                   recipe.surfaces.contains(widget.surface) &&
//                   recipe.results.length == 1 &&
//                   recipe.itemIo[input.item]! > 0,
//             )
//             .firstOrNull;

//         if (producerRecipe != null) {
//           // TODO - Cache a list of sorted machines somewhere
//           List<CraftingMachine> sortedMachines = List.from(
//             producerRecipe.craftingMachines,
//           );
//           sortedMachines.sort(
//             (machine1, machine2) =>
//                 machine1.craftingSpeed.compareTo(machine2.craftingSpeed),
//           );

//           var fastestMachine = sortedMachines.first;

//           ItemData? fuel;
//           if (fastestMachine.energySource.type == EnergySourceType.burner) {
//             var energySource =
//                 fastestMachine.energySource as BurnerEnergySource;

//             fuel = ItemData(energySource.fuelItems.first);
//           }

//           childNode = ProdLineNode.addToGraph(
//             parentGraph: widget.graph,
//             type: NodeType.productionLine,
//             line: SingleRecipeLine(
//               MutableModuledMachineAndRecipe(
//                 craftingMachine: fastestMachine,
//                 recipe: producerRecipe,
//                 fuel: fuel,
//               ).makeImmutable(),
//             ),
//           );
//         } else {
//           childNode = ProdLineNode.addToGraph(
//             parentGraph: widget.graph,
//             type: NodeType.producer,
//             line: IoLine(outputs: {input}),
//           );
//         }

//         _createRecipeTree(childNode, visitedNodes, connectedNodes, newEdges);
//       }

//       var newEdge = DirectedEdge.addToGraph(
//         parentGraph: widget.graph,
//         item: input,
//         parent: parentNode,
//         child: childNode,
//         edgeType: EdgeType.requestItems,
//       );

//       connectedNodes.add(childNode);
//       newEdges.add(newEdge);
//     }
//   }

//   void _createNodeWidgets(List<List<ProdLineNode>> nodesAndHeights) {
//     for (var y = 0; y < nodesAndHeights.length; y++) {
//       for (var x = 0; x < nodesAndHeights[y].length; x++) {
//         var node = nodesAndHeights[y][x];
//         nodeWidgets.putIfAbsent(
//           node,
//           () => NodeWidget(
//             node: node,
//             initialX: (initNodeWidth + initOffset) * x,
//             initialY: (initNodeHeight + initOffset) * y,
//           ),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return const Placeholder();
//   }
// }

// class NodeWidget extends StatefulWidget {
//   final ProdLineNode node;
//   final double initialX;
//   final double initialY;

//   const NodeWidget({
//     super.key,
//     required this.node,
//     required this.initialX,
//     required this.initialY,
//   });

//   @override
//   State<NodeWidget> createState() => _NodeWidgetState();
// }

// class _NodeWidgetState extends State<NodeWidget> {
//   late double x = widget.initialX;
//   late double y = widget.initialY;

//   @override
//   Widget build(BuildContext context) {
//     return Placeholder();
//   }
// }

// class EdgeWidget extends StatefulWidget {
//   final DirectedEdge edge;

//   const EdgeWidget({super.key, required this.edge});

//   @override
//   State<EdgeWidget> createState() => _EdgeWidgetState();
// }

// class _EdgeWidgetState extends State<EdgeWidget> {
//   @override
//   Widget build(BuildContext context) {
//     return const Placeholder();
//   }
// }
