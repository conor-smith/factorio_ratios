import 'dart:collection';

import 'package:factorio_ratios/factorio/factorio.dart';
import 'package:factorio_ratios/factorio/models.dart';
import 'package:factorio_ratios/factorio/production_line.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

part 'graph/edge.dart';
part 'graph/node.dart';

/*
 * Maintains a full graph
 * This acts as the state for the application, and the single source of truth
 * Every graph, edge, and widget will have a listener in the form of a widget
 * The widget will be the "owner" of it's respective element
 * 
 * Widgets are still largely responsible for their own state
 * As such, they can update their own state as they need
 * A callback only needs to occur when the one component affects the state of another
 * eg. If a node's position is changed, the positions of connected edges
 * will also be updated
 * 
 * If a graph is updated, there is no need to update states of node and edge widgets
 * as a graph update means a full rebuild of all widgets
 * 
 * Only the active graph and it's nodes and edges need to worry about updating state
 * 
 * The graph itself must have a size in order to be appropriately displayed
 * As such, the positions of topLeft and bottomRight create a rectangle
 * capable of containing all nodes present in the graph
 */
class BaseGraph extends ValueNotifier<GraphStateUpdate> with ProductionLine {
  final List<ProdLineNode> _nodes = [];
  final List<DirectedEdge> _edges = [];
  final Map<ProdLineNode, Set<DirectedEdge>> _parentOfMap = {};
  final Map<ProdLineNode, Set<DirectedEdge>> _childOfMap = {};

  // Is not null if this graph is contained within a node of a parent graph
  final ProdLineNode? parent;

  final Surface? surface;

  late final List<ProdLineNode> nodes = UnmodifiableListView(_nodes);
  late final List<DirectedEdge> edges = UnmodifiableListView(_edges);

  final Set<ItemData> _allInputs = {};
  final Set<ItemData> _allOutputs = {};
  ItemIo? _requirements;
  ItemIo? _totalIoPerSecond;

  // These two variables contain a rectangle
  Offset _topLeft;
  Offset _bottomRight;

  // This contains the node currently being dragged
  // Only one node may be dragged at a time
  ProdLineNode? _draggableNode;

  @override
  late final Set<ItemData> allInputs = UnmodifiableSetView(_allInputs);
  @override
  late final Set<ItemData> allOutputs = UnmodifiableSetView(_allOutputs);
  @override
  ItemIo? get requirements => _requirements;
  @override
  ItemIo? get totalIoPerSecond => _totalIoPerSecond;
  @override
  String get type => 'graph';

  @override
  bool get immutableIo => false;

  Offset get topLeft => _topLeft;
  Offset get bottomRight => _bottomRight;

  BaseGraph({this.surface, this.parent})
    : _topLeft = Offset.zero,
      _bottomRight = Offset.zero,
      super(GraphStateUpdate.emptyUpdate);

  @override
  void update(ItemIo newRequirements) {
    super.update(newRequirements);

    // TODO
  }

  @override
  void reset() {
    for (var node in _nodes) {
      node.reset();
    }

    _totalIoPerSecond = null;
    _requirements = null;
  }

  // Method is public to allow UI to use when displaying tree
  // 'Height' of a node is the length of the longest path from the input nodes
  // Nodes with the same value can be updated in any order
  List<List<ProdLineNode>> getNodeHeights(Iterable<ProdLineNode> nodes) {
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

  void clear() {
    value = GraphStateUpdate(
      removedNodes: List.from(_nodes),
      removedEdges: List.from(edges),
    );

    _nodes.clear();
    _edges.clear();
    _parentOfMap.clear();
    _childOfMap.clear();
    _allInputs.clear();
    _allOutputs.clear();
  }

  void treeLayout({
    bool updateListeners = false,
    bool updateNodeListeners = false,
  }) {
    var nodeHeights = getNodeHeights(_nodes);

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
        nodeHeights[y][x].updatePosition(
          topLeft,
          bottomRight,
          updateListeners: updateNodeListeners,
        );
      }
    }

    _updateGraphArea(updateListeners: updateListeners);
  }

  void updateNodesAndDescendants(
    Map<ProdLineNode, ItemIo> nodesAndRequirements,
  ) {
    var nodeHeights = getNodeHeights(nodesAndRequirements.keys);

    // Only possible if one node is a descendant of another
    if (nodeHeights[0].length != nodesAndRequirements.length) {
      throw const FactorioException(
        'Cannot give requirements to child and parent node',
      );
    }

    var allOrderedNodes = nodeHeights.expand((entry) => entry).toList();

    Map<ItemData, ProdLineNode> disposalNodes = {};
    for (var disposalNode in _nodes.where(
      (node) => node._type == NodeType.disposal,
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
          node.reset();
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
    List<ItemData> availableFuels, {
    bool updateListeners = false,
  }) {
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

    if (updateListeners) {
      value = GraphStateUpdate(newNodes: newNodes, newEdges: newEdges);
    }
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

  // TODO - Account for edges potentially taking paths beyond limits
  // TODO - Make more efficient? Maybe
  // Returns true if graph area is updated
  void _updateGraphArea({bool updateListeners = false}) {
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

      if (updateListeners) {
        value = GraphStateUpdate(topLeft: _topLeft, bottomRight: _bottomRight);
      }
    }
  }

  void _setDraggableNode(ProdLineNode node) {
    // None of these conditions should ever happen. But best be safe
    if (node.parentGraph != this) {
      throw const FactorioException(
        'Draggable node provided is not from this graph',
      );
    } else if (_draggableNode != null) {
      throw const FactorioException(
        'Cannot set new draggable node until old draggable node is cleared',
      );
    }

    node._isBeingDragged = true;
    _draggableNode = node;
  }

  void _clearDraggableNode(ProdLineNode node) {
    if (_draggableNode != node) {
      throw const FactorioException(
        'Draggable node to be cleared is incorrect',
      );
    }

    node._isBeingDragged = false;
    _draggableNode = null;
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

  void _addIo(ProdLineNode newIoNode) {
    if (newIoNode.nodeType == NodeType.output) {
      // Verify that output does not already exist
      if (newIoNode.allInputs.every(
        (nodeInput) => !_allOutputs.contains(nodeInput),
      )) {
        throw const FactorioException('Duplicate IO added');
      } else {
        _allOutputs.addAll(newIoNode.allInputs);
      }
    } else if (newIoNode.nodeType == NodeType.input) {
      // Verify input does not already exist
      if (newIoNode.allOutputs.every(
        (nodeOutput) => !_allInputs.contains(nodeOutput),
      )) {
        throw const FactorioException('Duplicate IO added');
      } else {
        _allInputs.addAll(newIoNode.allOutputs);
      }
    }
  }

  void _removeIo(ProdLineNode oldIoNode) {
    if (oldIoNode.nodeType == NodeType.output) {
      _allOutputs.removeAll(oldIoNode.allInputs);
    } else if (oldIoNode.nodeType == NodeType.input) {
      _allInputs.removeAll(oldIoNode.allOutputs);
    }
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

/*
 * Used by widget to determine whether to rebuild whole graph or just nodes
 * .update will only be true if
 * * Graph dimensions (offsets) are updated
 * * New nodes or edges are added
 * * Existing nodes or edges are removed
 * If .update is true, GraphWidget and all child widgets must be rebuilt
 * If not, only affected node widgets will be rebuilt
 * 
 * This object is only used in situations where it is not immediately clear
 * what exactly needs to be updated
 * eg. A call to node.updateSelfAndDependants will result in multiple
 * nodes being updated, and some potential new nodes being created
 * A call to node.updateSelfOnly does not need to return this object
 */
class GraphStateUpdate {
  final Offset? topLeft;
  final Offset? bottomRight;
  final List<ProdLineNode> newNodes;
  final List<ProdLineNode> updatedNodes;
  final List<ProdLineNode> removedNodes;
  final List<DirectedEdge> newEdges;
  final List<DirectedEdge> updatedEdges;
  final List<DirectedEdge> removedEdges;
  final ProdLineNode? selectedNode;

  const GraphStateUpdate({
    this.topLeft,
    this.bottomRight,
    this.newNodes = const [],
    this.updatedNodes = const [],
    this.removedNodes = const [],
    this.newEdges = const [],
    this.updatedEdges = const [],
    this.removedEdges = const [],
    this.selectedNode,
  });

  static const GraphStateUpdate emptyUpdate = GraphStateUpdate();

  @override
  bool operator ==(Object other) {
    return other is GraphStateUpdate &&
        other.topLeft == topLeft &&
        other.bottomRight == bottomRight &&
        other.newNodes == newNodes &&
        other.updatedNodes == updatedNodes &&
        other.removedNodes == removedNodes &&
        other.newEdges == newEdges &&
        other.updatedEdges == updatedEdges &&
        other.removedEdges == removedEdges &&
        other.selectedNode == selectedNode;
  }
}
