import 'dart:collection';

import 'package:factorio_ratios/factorio/factorio.dart';
import 'package:factorio_ratios/factorio/models.dart';
import 'package:factorio_ratios/factorio/production_line.dart';
import 'package:factorio_ratios/state_traversal/mutateable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

part 'graph/edge.dart';
part 'graph/events.dart';
part 'graph/global_state.dart';
part 'graph/node.dart';

/*
 * Maintains a full graph
 * This acts as the state for the application, and the single source of truth
 * 
 * All contained objects are mutateable
 * Mutating state must only be done through specific methods, even within the classes
 * This means that mutations can be rolled back if need be
 * Mutateables are also listenable, and will only notifyListeners when instructed to
 * 
 * As nodes can contain graphs, the entire structure can be thought of as a tree
 * In a tree, there is only one eventHistory object
 * All mutations must be done within eventHistory._mutate(...)
 * An arbitrary number of mutations can occur before committing
 * At commit, all uncommitted events are combined into one single event
 * 
 * The complex nature of the graphs means that updating the state of one object
 * may affect the state of another
 * Eg. Updating nodeType to "output" will result in the node's inputs
 * being added to it's parentGraph's outputs
 * As such, listeners should not be notified until all changes in a transaction
 * are completed
 * 
 * The root graph of a tree will never have requirements
 * This is because requirements determine input and output,
 * and the root graph has nowhere to input or output to
 */
class BaseGraph extends ProductionLine with Mutateable<GraphEvent> {
  // Stores history of entire tree. Responsible for rollbacks, commits, etc
  // All graphs in a tree must use the same eventHistory object
  static const int _maxSavedEvents = 50; // TODO - Revise this value
  final _EventHistory _eventHistory;

  // All following fields are considered part of the mutable graph state
  // They are ONLY to be modified within .apply(...) and .rollback(...)
  final List<ProdLineNode> _nodes = [];
  final List<DirectedEdge> _edges = [];

  final Set<ItemData> _allInputs = {};
  final Set<ItemData> _allOutputs = {};
  ItemIo? _requirements;
  ItemIo? _totalIoPerSecond;

  Offset _topLeft, _bottomRight;
  ProdLineNode? _topNode, _leftNode, _bottomNode, _rightNode;
  bool get _hasPositionalNodes =>
      _topNode != null &&
      _leftNode != null &&
      _bottomNode != null &&
      _rightNode != null;

  ProdLineNode? get topNode => _topNode;
  ProdLineNode? get leftNode => _leftNode;
  ProdLineNode? get bottomNode => _bottomNode;
  ProdLineNode? get rightNode => _rightNode;

  // Accessor fields for nodes and edges
  late final List<ProdLineNode> nodes = UnmodifiableListView(_nodes);
  late final List<DirectedEdge> edges = UnmodifiableListView(_edges);

  // Uses topNode, leftNode, etc to create smallest possible rectangle containing all nodes

  Offset get topLeft => _topLeft;
  Offset get bottomRight => _bottomRight;

  // Used to make decisions about what production lines can be added
  final Surface? surface;

  // Used to track position in tree
  ProdLineNode? _parentNode;

  // Getter fields required for ProductionLine
  @override
  late final Set<ItemData> allInputs = UnmodifiableSetView(_allInputs);
  @override
  late final Set<ItemData> allOutputs = UnmodifiableSetView(_allOutputs);

  @override
  ItemIo? get requirements => _requirements;
  @override
  ItemIo? get totalIoPerSecond => _totalIoPerSecond;

  @override
  bool get immutableIo => false;
  @override
  String get type => 'graph';

  // Constructors
  BaseGraph.root({this.surface})
    : _topLeft = Offset.zero,
      _bottomRight = Offset.zero,
      _parentNode = null,
      _eventHistory = _EventHistory(_maxSavedEvents);

  BaseGraph._addToTree({this.surface, required _EventHistory eventHistory})
    : _topLeft = Offset.zero,
      _bottomRight = Offset.zero,
      _eventHistory = eventHistory;

  // ProductionLine methods
  @override
  void update(ItemIo newRequirements) {
    super.update(newRequirements);

    // TODO
  }

  // Only clears output nodes and direct children
  // Does not clear consumer nodes
  @override
  void clearRequirements() {
    // TODO
  }

  // All changes to state occur in these methods
  @override
  void apply(GraphEvent event) {
    _apply(event);

    _eventHistory.addGraphEvent(event);
  }

  @override
  void redo(GraphEvent event) {
    _apply(event);
  }

  @override
  void rollback(GraphEvent event) {
    _apply(event.reversed);
  }

  void _apply(GraphEvent event) {
    _eventHistory.checkIfMutationPermitted();

    for (var mutationType in event.mutations) {
      switch (mutationType) {
        case GraphEventType.positionalNodesUpdate:
          _topNode = event.newTopNode;
          _leftNode = event.newLeftNode;
          _bottomNode = event.newBottomNode;
          _rightNode = event.newRightNode;

          // TODO - Is this necessary?
          if (_hasPositionalNodes) {
            _topLeft = Offset(_leftNode!.topLeft.dx, _topNode!.topLeft.dy);
            _bottomRight = Offset(
              _rightNode!.bottomRight.dx,
              _bottomNode!.bottomRight.dy,
            );
          }

        case GraphEventType.updateNodes:
          for (var removedNode in event.removedNodes) {
            _nodes.remove(removedNode);
          }
          _nodes.addAll(event.newNodes);

        case GraphEventType.updateEdges:
          for (var removedEdge in event.removedEdges) {
            _edges.remove(removedEdge);
          }
          _edges.addAll(event.newEdges);

        case GraphEventType.updateInput:
          allInputs.removeAll(event.removedInputs);
          allInputs.addAll(event.newInputs);

        case GraphEventType.updateOutput:
          allOutputs.removeAll(event.removedOutputs);
          allOutputs.addAll(event.newOutputs);
      }
    }
  }

  // Will not clear input and output nodes
  void clearAllNodes() {
    // TODO - Create new nodes to supply remaining IO nodes
    _eventHistory.mutate(() {
      var nonIoNodes = _nodes.where((node) => !node.nodeType.isIo).toList();

      for (var node in nonIoNodes) {
        node.removeFromGraph();
      }
    });
  }

  // Uses tree structure and heirarchy to determine node positions
  void treeLayout() {
    _eventHistory.mutate(() {
      var nodeHeights = _getNodeHeights(_nodes);

      for (var y = 0; y < nodeHeights.length; y++) {
        for (var x = 0; x < nodeHeights[y].length; x++) {
          var node = nodeHeights[y][x];
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

          node.updatePosition(topLeft, bottomRight);
        }
      }

      _redoPositionalNodes();
    });
  }

  void addConsumerNodeAndTree(
    ItemData itemData,
    List<CraftingMachine> sortedMachines,
    List<Recipe> recipes,
    List<ItemData> resources,
    List<ItemData> availableFuels,
  ) {
    // Return if consumer node already exists
    if (_nodes.any(
      (node) =>
          node.nodeType == NodeType.consumer &&
          node.allInputs.contains(itemData),
    )) {
      return;
    }

    _eventHistory.mutate(() {
      var newConsumerNode = ProdLineNode.addToGraph(
        parentGraph: this,
        type: NodeType.consumer,
        line: IoLine(inputs: {itemData}),
      );

      // TODO - Cache this somehow
      Map<ItemData, List<ProdLineNode>> producers = {};
      for (var node in _nodes) {
        for (var output in node.allOutputs) {
          producers.update(
            output,
            (pNodes) => pNodes..add(node),
            ifAbsent: () => [node],
          );
        }
      }

      _createRecipeTree(
        newConsumerNode,
        sortedMachines,
        recipes,
        resources,
        availableFuels,
        producers,
      );

      // TODO - Don't use treeLayout for everything
      treeLayout();
    });
  }

  void _createRecipeTree(
    ProdLineNode parentNode,
    List<CraftingMachine> sortedMachines,
    List<Recipe> recipes,
    List<ItemData> resources,
    List<ItemData> availableFuels,
    Map<ItemData, List<ProdLineNode>> producers,
  ) {
    for (var input in parentNode.allInputs) {
      var childNode = producers[input]?.first;

      if (childNode == null) {
        childNode =
            _createResourceNode(input, resources) ??
            _createRecipeNode(input, sortedMachines, recipes, availableFuels) ??
            _createProducerNode(input);

        producers[input] = [childNode];

        _createRecipeTree(
          childNode,
          sortedMachines,
          recipes,
          resources,
          availableFuels,
          producers,
        );
      }

      if (!childNode.parentOf.any((edge) => edge.child == childNode)) {
        DirectedEdge.addToGraph(
          parentGraph: this,
          item: input,
          parent: parentNode,
          child: childNode,
          edgeType: Relationship.requestItems,
        );
      }
    }
  }

  ProdLineNode? _createResourceNode(
    ItemData itemData,
    List<ItemData> resources,
  ) {
    if (resources.contains(itemData)) {
      return ProdLineNode.addToGraph(
        parentGraph: this,
        type: NodeType.producer,
        line: IoLine(outputs: {itemData}),
      );
    } else {
      return null;
    }
  }

  ProdLineNode? _createRecipeNode(
    ItemData itemData,
    List<CraftingMachine> sortedMachines,
    List<Recipe> recipes,
    List<ItemData> availableFuels,
  ) {
    // TODO - account for null surface
    var producerRecipe = recipes
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
        fuel = availableFuels.firstWhere(
          (fuel) => energySource.fuelItems.contains(fuel.item),
        );
      }

      return ProdLineNode.addToGraph(
        parentGraph: this,
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

  ProdLineNode _createProducerNode(ItemData itemData) {
    return ProdLineNode.addToGraph(
      parentGraph: this,
      type: NodeType.producer,
      line: IoLine(outputs: {itemData}),
    );
  }

  List<List<ProdLineNode>> _getNodeHeights(Iterable<ProdLineNode> nodes) {
    Map<ProdLineNode, int> heightMap = {};

    int maxHeight = 0;
    for (var node in nodes) {
      int newMax = _getDescendantsHeight(node, heightMap, 0);

      maxHeight = newMax > maxHeight ? newMax : maxHeight;
    }

    List<List<ProdLineNode>> flippedMap = List.generate(
      maxHeight + 1,
      (_) => [],
    );

    heightMap.forEach((node, height) => flippedMap[height].add(node));

    return flippedMap;
  }

  // Assumes all positional nodes are invalid
  // Scans all nodes for new ones
  void _redoPositionalNodes() {
    if (_nodes.isEmpty) {
      apply(GraphEvent.clearPositionalNodes(this));
    } else {
      apply(
        GraphEvent.newPositionalNodes(
          this,
          newTopNode: _findNewMaxNode(ProdLineNode.topMostNode),
          newLeftNode: _findNewMaxNode(ProdLineNode.leftMostNode),
          newBottomNode: _findNewMaxNode(ProdLineNode.bottomMostNode),
          newRightNode: _findNewMaxNode(ProdLineNode.rightMostNode),
        ),
      );
    }
  }

  ProdLineNode _findNewMaxNode(
    Comparator<ProdLineNode> maxFunction, {
    ProdLineNode? oldMaxNode,
    List<ProdLineNode> removedNodes = const [],
    List<ProdLineNode> newNodes = const [],
  }) {
    ProdLineNode maxNode;
    if (oldMaxNode == null || removedNodes.contains(oldMaxNode)) {
      maxNode = _nodes.first;

      for (var node in _nodes.skip(1)) {
        if (maxFunction(maxNode, node) < 0) {
          maxNode = node;
        }
      }
    } else {
      maxNode = oldMaxNode;

      for (var node in newNodes) {
        if (maxFunction(maxNode, node) < 0) {
          maxNode = node;
        }
      }
    }

    return maxNode;
  }

  // Returns the maximum height
  int _getDescendantsHeight(
    ProdLineNode node,
    Map<ProdLineNode, int> heightMap,
    int currentHeight,
  ) {
    int existingHeight = heightMap[node] ?? -1;
    if (currentHeight > existingHeight) {
      heightMap[node] = currentHeight;
      int maxHeight = currentHeight;

      for (var edge in node.parentOf) {
        int newMax = _getDescendantsHeight(
          edge.child,
          heightMap,
          currentHeight + 1,
        );

        maxHeight = newMax > maxHeight ? newMax : maxHeight;
      }

      return maxHeight;
    } else {
      return existingHeight;
    }
  }
}
