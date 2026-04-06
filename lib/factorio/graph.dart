import 'dart:collection';
import 'dart:math';

import 'package:factorio_ratios/factorio/factorio.dart';
import 'package:factorio_ratios/factorio/models.dart';
import 'package:factorio_ratios/factorio/production_line.dart';
import 'package:factorio_ratios/state_traversal/mutateable.dart';
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
  // TODO - Create toggle that only allows mutations under correct circumstances
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

  // Accessor fields for nodes and edges
  late final List<ProdLineNode> nodes = UnmodifiableListView(_nodes);
  late final List<DirectedEdge> edges = UnmodifiableListView(_edges);

  // Uses topNode, leftNode, etc to create smallest possible rectangle containing all nodes

  Offset get topLeft => _topLeft;
  Offset get bottomRight => _bottomRight;

  // Used to make decisions about what production lines can be added
  final Surface? surface;

  // Used to track position in tree
  final BaseGraph? parentGraph;

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
      parentGraph = null,
      _eventHistory = _EventHistory(_maxSavedEvents);

  BaseGraph._addToTree({this.surface, required BaseGraph this.parentGraph})
    : _topLeft = Offset.zero,
      _bottomRight = Offset.zero,
      _eventHistory = parentGraph._eventHistory;

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

  // All state mutations must occur through these methods
  @override
  void apply(GraphEvent event) {
    _apply(event, true);

    if (event.mutations.contains(GraphEventType.updateNodes)) {
      _checkForPositionalNodesUpdate(event.removedNodes, event.newNodes);
    }
  }

  @override
  void redo(GraphEvent event) {
    _apply(event, false);
  }

  @override
  void rollback(GraphEvent event) {
    _apply(event.reversed, false);
  }

  void _apply(GraphEvent event, bool saveEvent) {
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

    if (saveEvent) {
      _eventHistory.addGraphEvent(event);
    }
  }

  void _checkForPositionalNodesUpdate(
    List<ProdLineNode> removedNodes,
    List<ProdLineNode> newNodes,
  ) {
    if (_nodes.isEmpty) {
      _apply(GraphEvent._(this, [GraphEventType.positionalNodesUpdate]), true);
    } else {
      ProdLineNode top = _findNewMaxNode(
        _topNode!,
        removedNodes,
        newNodes,
        ProdLineNode.topMostNode,
      );
      ProdLineNode left = _findNewMaxNode(
        _leftNode!,
        removedNodes,
        newNodes,
        ProdLineNode.leftMostNode,
      );
      ProdLineNode bottom = _findNewMaxNode(
        _bottomNode!,
        removedNodes,
        newNodes,
        ProdLineNode.bottomMostNode,
      );
      ProdLineNode right = _findNewMaxNode(
        _rightNode!,
        removedNodes,
        newNodes,
        ProdLineNode.rightMostNode,
      );

      if (top != _topNode ||
          left != _leftNode ||
          bottom != _bottomNode ||
          right != _rightNode) {
        _apply(
          GraphEvent._(
            this,
            [GraphEventType.positionalNodesUpdate],
            newTopNode: top,
            newLeftNode: left,
            newBottomNode: bottom,
            newRightNode: right,
          ),
          true,
        );
      }
    }
  }

  ProdLineNode _findNewMaxNode(
    ProdLineNode oldMaxNode,
    List<ProdLineNode> removedNodes,
    List<ProdLineNode> newNodes,
    Comparator<ProdLineNode> maxFunction,
  ) {
    ProdLineNode maxNode;
    if (removedNodes.contains(oldMaxNode)) {
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

  // Will not clear input and output nodes
  void clearAllNodes() {
    // TODO
  }

  // Uses tree structure and heirarchy to determine node positions
  void treeLayout() {
    _eventHistory.mutate(() {
      var nodeHeights = _getNodeHeights(_nodes);

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
          nodeHeights[y][x].updatePosition(topLeft, bottomRight);
        }
      }

      _updateGraphArea();
    });
  }

  void updateNodesAndDescendants(
    Map<ProdLineNode, ItemIo> nodesAndRequirements,
  ) {
    var nodeHeights = _getNodeHeights(nodesAndRequirements.keys);

    // Only possible if one node is a descendant of another
    if (nodeHeights[0].length != nodesAndRequirements.length) {
      throw const FactorioException(
        'Cannot give requirements to child and parent node',
      );
    }

    var allOrderedNodes = nodeHeights.expand((entry) => entry).toList();

    Map<ItemData, ProdLineNode> disposalNodes = {};
    for (var disposalNode in _nodes.where(
      (node) => node._nodeType == NodeType.disposal,
    )) {
      for (var input in disposalNode.allInputs) {
        disposalNodes[input] = disposalNode;
      }
    }

    // Exists so changes can be rolled back if exception occurs
    Map<ProdLineNode, ItemIo?> oldRequirementsMap = {};
    Map<DirectedEdge, double?> oldAmountMap = {};
    List<ProdLineNode> newDisposalNodes = [];
    List<DirectedEdge> newEdges = [];

    try {
      for (var node in allOrderedNodes) {
        ItemIo requirements;
        if (nodesAndRequirements.containsKey(node)) {
          requirements = nodesAndRequirements[node]!;
        } else {
          requirements = node._determineRequirementsFromParents();
        }

        oldRequirementsMap[node] = node.requirements;
        for (var edge in node.parentOf) {
          oldAmountMap[edge] = edge.amount;
        }

        _updateNodeAndChildEdges(
          node,
          requirements,
          disposalNodes,
          newDisposalNodes,
          newEdges,
        );
      }

      for (var node in newDisposalNodes) {
        node.update(node._determineRequirementsFromParents());
      }
    } catch (e) {
      oldRequirementsMap.forEach((node, oldRequirements) {
        if (oldRequirements == null) {
          node.clearRequirements();
        } else {
          node.update(oldRequirements);
        }
      });

      oldAmountMap.forEach((edge, oldAmount) {
        edge._amount = oldAmount;
      });

      for (var newNode in newDisposalNodes) {
        newNode.removeFromGraph();
      }

      rethrow;
    }
  }

  void addConsumerNodeAndTree(
    ItemData itemData,
    List<CraftingMachine> sortedMachines,
    List<Recipe> recipes,
    List<ItemData> resources,
    List<ItemData> availableFuels,
  ) {
    // TODO - Check if consumer node already exists
    var newNode = ProdLineNode.addToGraph(
      parentGraph: this,
      type: NodeType.consumer,
      line: IoLine(inputs: {itemData}),
    );

    // TODO - Cache this
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

    List<ProdLineNode> newNodes = [newNode];
    List<DirectedEdge> newEdges = [];

    _createRecipeTree(
      newNode,
      sortedMachines,
      recipes,
      resources,
      availableFuels,
      producers,
      newNodes,
      newEdges,
    );
  }

  void _createRecipeTree(
    ProdLineNode parentNode,
    List<CraftingMachine> sortedMachines,
    List<Recipe> recipes,
    List<ItemData> resources,
    List<ItemData> availableFuels,
    Map<ItemData, List<ProdLineNode>> producers,
    List<ProdLineNode> newNodes,
    List<DirectedEdge> newEdges,
  ) {
    for (var input in parentNode.allInputs) {
      var childNode = producers[input]?.first;

      if (childNode == null) {
        childNode =
            _createResourceNode(input, resources) ??
            _createRecipeNode(input, sortedMachines, recipes, availableFuels) ??
            _createProducerNode(input);

        producers[input] = [childNode];
        newNodes.add(childNode);

        _createRecipeTree(
          childNode,
          sortedMachines,
          recipes,
          resources,
          availableFuels,
          producers,
          newNodes,
          newEdges,
        );
      }

      if (!childNode.parentOf.any((edge) => edge.child == childNode)) {
        var newEdge = DirectedEdge.addToGraph(
          parentGraph: this,
          item: input,
          parent: parentNode,
          child: childNode,
          edgeType: Relationship.requestItems,
        );

        newEdges.add(newEdge);
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

  // TODO - Account for edges potentially taking paths beyond limits
  // TODO - Make more efficient? Maybe
  // Returns true if graph area is updated
  void _updateGraphArea() {
    double left, top, right, bottom;

    if (_nodes.isEmpty) {
      left = 0;
      top = 0;
      right = 0;
      bottom = 0;
    } else {
      var firstNode = _nodes.first;
      left = firstNode._topLeft.dx;
      top = firstNode._topLeft.dy;
      right = firstNode._bottomRight.dx;
      bottom = firstNode._bottomRight.dy;

      for (var node in _nodes.skip(1)) {
        var nodeLeft = node._topLeft.dx;
        var nodeTop = node._topLeft.dy;
        var nodeRight = node._bottomRight.dx;
        var nodeBottom = node._bottomRight.dy;

        left = nodeLeft < left ? nodeLeft : left;
        top = nodeTop < top ? nodeTop : top;
        right = nodeRight > right ? nodeRight : right;
        bottom = nodeBottom > bottom ? nodeBottom : bottom;
      }
    }

    if (left != _topLeft.dx ||
        top != _topLeft.dy ||
        right != _bottomRight.dx ||
        bottom != _bottomRight.dy) {
      _topLeft = Offset(left, top);
      _bottomRight = Offset(right, bottom);
    }
  }

  void _addNewNodeData(ProdLineNode newNode) {
    if (newNode.nodeType.isIo) {
      _addIo(newNode);
    }

    _nodes.add(newNode);

    _parentOfMap[newNode] = {};
    _childOfMap[newNode] = {};
  }

  void _addNewEdgeData(DirectedEdge newEdge) {
    _edges.add(newEdge);

    // Add edge to relevant parentOf and childOf entries
    _parentOfMap[newEdge.parent]!.add(newEdge);
    _childOfMap[newEdge.child]!.add(newEdge);
  }

  void _removeNodeData(ProdLineNode node, bool updateIo) {
    _nodes.remove(node);

    List<DirectedEdge> edgesToRemove = [];

    // Remove all edges in which this node is parent
    for (var edge in node.parentOf) {
      edgesToRemove.add(edge);
      _childOfMap[edge.child]!.remove(edge);
    }
    // Remove all edges in which this node is child
    for (var edge in node.childOf) {
      edgesToRemove.add(edge);
      _parentOfMap[edge.parent]!.remove(edge);
    }

    // Removed parentOf and childOf entries
    _parentOfMap.remove(node);
    _childOfMap.remove(node);

    for (var edge in edgesToRemove) {
      _edges.remove(edge);
    }

    // Update IO if necessary
    if (updateIo && node.nodeType.isIo) {
      _removeIo(node);
    }
  }

  void _removeEdgeData(DirectedEdge edge) {
    _edges.remove(edge);

    _parentOfMap[edge.parent]!.remove(edge);
    _childOfMap[edge.child]!.remove(edge);
  }

  // Calls .update(...) a single node according to requirements
  // Then updates all child edge amounts
  void _updateNodeAndChildEdges(
    ProdLineNode node,
    ItemIo newRequirements,
    Map<ItemData, ProdLineNode> disposalNodes,
    List<ProdLineNode> newDisposalNodes,
    List<DirectedEdge> newEdges,
  ) {
    node.update(newRequirements);

    ItemIo io = node.totalIoPerSecond!;

    for (var output in node.allOutputs) {
      double amount = io[output]!;

      double totalRequested = node.childOf
          .where((edge) => edge.item == output)
          .map((edge) => edge._amount!)
          .reduce((amount1, amount2) => amount1 + amount2);

      double difference = totalRequested - amount;
      // Account for floating point issues
      bool withinBounds = difference.abs() < totalRequested * 0.01;

      // Create or use existing disposal node if excess production
      if (!withinBounds && difference < 0) {
        throw FactorioException(
          'Could not produce required amount of "$output"',
        );
      } else if (!withinBounds) {
        /*
         * In order
         * Find existing acceptExcess edge
         * If not available, find existing disposal node and create edge
         * If not available, create disposal node and edge
         */
        DirectedEdge? acceptExcessEdge = node.parentOf
            .where(
              (edge) =>
                  edge.item == output &&
                  edge.edgeType == Relationship.acceptExcess,
            )
            .firstOrNull;

        if (acceptExcessEdge != null) {
          // acceptExcess edge and disposal node already exist
          acceptExcessEdge._amount = difference;
        } else {
          // Check if a disposal node exists for this output
          var disposalNode = disposalNodes[output];

          if (disposalNode == null) {
            // No disposal node exists. Create new one
            disposalNode = ProdLineNode.addToGraph(
              parentGraph: this,
              type: NodeType.disposal,
              line: IoLine(inputs: {output}),
            );

            newDisposalNodes.add(disposalNode);
            disposalNodes[output] = disposalNode;
          }

          // Create new edge between this node and disposal node
          acceptExcessEdge = DirectedEdge.addToGraph(
            parentGraph: this,
            item: output,
            parent: node,
            child: disposalNode,
            initialAmount: difference,
            edgeType: Relationship.acceptExcess,
          );

          newEdges.add(acceptExcessEdge);
        }
      }
    }

    for (var input in node.allInputs) {
      // TODO - Account for multiple producers of single item
      DirectedEdge? inputEdge = [
        ...node.parentOf,
        ...node.childOf,
      ].where((edge) => edge.item == input).firstOrNull;

      if (inputEdge == null) {
        throw FactorioException('No input provided for item "$input"');
      } else if (inputEdge.edgeType == Relationship.requestItems) {
        inputEdge._amount = io[input]!;
      }
    }
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
