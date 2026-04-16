part of '../graph.dart';

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
class BaseGraph extends ProductionLine with Stateful<GraphEvent> {
  // Stores history of entire tree. Responsible for rollbacks, commits, etc
  // All graphs in a tree must use the same eventHistory object
  static const int _maxSavedEvents = 50; // TODO - Revise this value

  /* ------------- Immutable fields ------------- */
  final _EventHistory _eventHistory;

  final Surface? surface;

  // Used to track position in tree. Should only be set once
  ProdLineNode? _parentNode;

  /* -------------- Mutable fields -------------- */
  final Set<ProdLineNode> _nodes = {};
  final Set<DirectedEdge> _edges = {};

  final Set<ItemData> _allInputs = {};
  final Set<ItemData> _allOutputs = {};

  ItemIo? _requirements;
  ItemIo? _totalIoPerSecond;

  GraphCartesianData _cartesianData;

  /* ----------- Cartesian Operation ----------- */
  _CartesianOperation? _cartOp;
  void _throwIfNoCartOp() {
    if (_cartOp == null) {
      throw const GraphException('No cartesian operation taking place');
    }
  }

  void _throwIfCartOp() {
    if (_cartOp != null) {
      throw const GraphException('Cartesian operation currently taking place');
    }
  }

  /* ---------------- Accessors ---------------- */
  late final List<ProdLineNode> nodes = UnmodifiableListView(_nodes);
  late final List<DirectedEdge> edges = UnmodifiableListView(_edges);

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

  /* --------------- Constructors --------------- */
  BaseGraph.root({this.surface})
    : _parentNode = null,
      _eventHistory = _EventHistory(_maxSavedEvents),
      _cartesianData = const GraphCartesianData.uninitialised();

  BaseGraph._addToTree({this.surface, required _EventHistory eventHistory})
    : _eventHistory = eventHistory,
      _cartesianData = GraphCartesianData.uninitialised();

  /* ------------- Stateful methods ------------- */
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
        case GraphEventType.cartesianDataUpdate:
          _cartesianData = event.newCartesianData!;

        case GraphEventType.updateNodes:
          _nodes.removeAll(event.removedNodes);
          _nodes.addAll(event.newNodes);

        case GraphEventType.updateEdges:
          _edges.removeAll(event.removedEdges);
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

  /* ----------- Cartesian Operations ----------- */
  void beginDrag(List<ProdLineNode> nodes, List<DirectedEdge> edges) {
    _throwIfCartOp();

    _cartOp = _CartesianOperation.dragOperation(
      Set.from(nodes),
      Set.from(edges),
    );
  }

  void beginResize(
    List<ProdLineNode> nodes,
    ProdLineNode selectedNode,
    RectPoint selectedPoint,
  ) {
    _throwIfCartOp();

    _cartOp = _CartesianOperation.resizeOperation(
      nodes,
      selectedNode,
      selectedPoint,
    );
  }

  /* ------------- All other logic ------------- */
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

          var left =
              x * (ProdLineNode.defaultWidth + ProdLineNode.defaultOffset) +
              ProdLineNode.defaultOffset;
          var top =
              y * (ProdLineNode.defaultHeight + ProdLineNode.defaultOffset) +
              ProdLineNode.defaultOffset;

          Rect newRect = Rect.fromLTWH(
            left,
            top,
            ProdLineNode.defaultWidth,
            ProdLineNode.defaultHeight,
          );

          node.apply(
            NodeEvent.updatePosition(node, NodeCartesianData(newRect)),
          );
        }
      }

      for (var edge in _edges) {
        edge._shortestLineBetweenNodes();
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
      apply(GraphEvent.clearCartesianData(this));
    } else {
      var allCartesianData = _nodes
          .map<CartesianData>((node) => node._cartesianData)
          .followedBy(_edges.map((edge) => edge._cartesianData))
          .toList();

      CartesianData top = _findNewMaxNode(
            CartesianData.topMost,
            allCartesianData,
          ),
          left = _findNewMaxNode(CartesianData.leftMost, allCartesianData),
          bottom = _findNewMaxNode(CartesianData.bottomMost, allCartesianData),
          right = _findNewMaxNode(CartesianData.rightMost, allCartesianData);

      apply(
        GraphEvent.newCartesianData(
          this,
          GraphCartesianData.fromLTRB(left, top, right, bottom),
        ),
      );
    }
  }

  CartesianData _findNewMaxNode(
    Comparator<CartesianData> maxFunction,
    List<CartesianData> allCartesianData, {
    CartesianData? oldMax,
    List<CartesianData> removedData = const [],
    List<CartesianData> newData = const [],
  }) {
    CartesianData max;

    if (oldMax == null || removedData.contains(oldMax)) {
      max = allCartesianData.first;

      for (var data in allCartesianData.skip(1)) {
        if (maxFunction(max, data) < 0) {
          max = data;
        }
      }
    } else {
      max = oldMax;

      for (var data in newData) {
        if (maxFunction(max, data) < 0) {
          max = data;
        }
      }
    }

    return max;
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

class GraphCartesianData extends CartesianData {
  final CartesianData? top, left, bottom, right;

  GraphCartesianData.fromLTRB(
    CartesianData this.left,
    CartesianData this.top,
    CartesianData this.right,
    CartesianData this.bottom,
  ) : super(
        Rect.fromLTRB(
          left.minimalRect.left,
          top.minimalRect.top,
          right.minimalRect.right,
          bottom.minimalRect.bottom,
        ),
      );

  const GraphCartesianData.uninitialised()
    : top = null,
      left = null,
      bottom = null,
      right = null,
      super(Rect.zero);
}

class _CartesianOperation {
  // All of these elements are affected by drag operations
  final List<_MutableNodeCartesianData> nodeCartesianData;
  final List<_MutableEdgeCartesianData> edgeCartesianData;

  // These elements are only affected their connected nodes
  final List<_MutableEdgeCartesianData> affectedEdgeCartesianData;

  final bool isDragOperation;

  factory _CartesianOperation.dragOperation(
    Set<ProdLineNode> nodes,
    Set<DirectedEdge> edges,
  ) {
    Map<ProdLineNode, _MutableNodeCartesianData> nodeData = {};
    Set<DirectedEdge> affectedEdges = {};

    for (var node in nodes) {
      nodeData[node] = _MutableNodeCartesianData.from(node);
      affectedEdges.addAll([...node.parentOf, ...node.childOf]);
    }

    affectedEdges.removeAll(edges);
    var affectedEdgeData = buildEdgeData(affectedEdges, nodeData);
    var edgeData = buildEdgeData(edges, nodeData);

    return _CartesianOperation._(
      nodeData.values.toList(),
      edgeData,
      affectedEdgeData,
      true,
    );
  }

  factory _CartesianOperation.resizeOperation(
    Set<ProdLineNode> nodes,
    ProdLineNode selectedNode,
    RectPoint selectedPoint,
  ) {
    Map<ProdLineNode, _MutableNodeCartesianData> nodeData = {};
    Set<DirectedEdge> affectedEdges = {};
    var opposite = selectedPoint.opposite;

    for (var node in nodes) {
      if (node == selectedNode) {
        nodeData[node] = _MutableNodeCartesianData.from(node);
      } else {
        var offset =
            opposite.getPoint(node.rect) - opposite.getPoint(selectedNode.rect);
        var newBaseRect = selectedNode.rect.shift(offset);
        nodeData[node] = _MutableNodeCartesianData.from(
          node,
          baseRect: newBaseRect,
        );
      }
      affectedEdges.addAll([...node.parentOf, ...node.childOf]);
    }

    var affectedEdgeData = buildEdgeData(affectedEdges, nodeData);

    return _CartesianOperation._(
      nodeData.values.toList(),
      const [],
      affectedEdgeData,
      false,
    );
  }

  _CartesianOperation._(
    this.nodeCartesianData,
    this.edgeCartesianData,
    this.affectedEdgeCartesianData,
    this.isDragOperation,
  );

  static List<_MutableEdgeCartesianData> buildEdgeData(
    Iterable<DirectedEdge> edges,
    Map<ProdLineNode, _MutableNodeCartesianData> nodeData,
  ) => edges
      .map(
        (edge) => _MutableEdgeCartesianData.from(
          edge,
          nodeData[edge.parent] ?? edge.parent.cartesianData,
          nodeData[edge.child] ?? edge.child.cartesianData,
        ),
      )
      .toList();

  void drag(Offset offset) {
    if (!isDragOperation) {
      throw const GraphException(
        'Current cartesian operation is not a drag operation',
      );
    }

    for (var nodeData in nodeCartesianData) {
      nodeData.shift(offset);
    }

    for (var edgeData in edgeCartesianData) {
      edgeData.shiftAllLines(offset);
    }

    for (var edgeData in affectedEdgeCartesianData) {
      edgeData.update();
    }
  }

  void resizeNodes(
    double topOffset,
    double leftOffset,
    double bottomOffset,
    double rightOffset,
  ) {
    for (var nodeData in nodeCartesianData) {
      nodeData.resize(leftOffset, topOffset, rightOffset, bottomOffset);
    }

    for (var edgeData in affectedEdgeCartesianData) {
      edgeData.update();
    }
  }

  void _updateAll() {
    for (var nodeData in nodeCartesianData) {
      nodeData.node.notifyListeners(
        NodeEvent.tempPosition(nodeData.node, nodeData),
      );
    }

    for (var edgeData in edgeCartesianData.followedBy(
      affectedEdgeCartesianData,
    )) {
      edgeData.edge.notifyListeners(
        EdgeEvent.tempCartesianData(edgeData.edge, edgeData),
      );
    }
  }
}

enum RectPoint {
  topLeft,
  top,
  topRight,
  right,
  bottomRight,
  bottom,
  bottomLeft,
  left;

  Offset getPoint(Rect rect) => switch (this) {
    topLeft => rect.topLeft,
    top => rect.topCenter,
    topRight => rect.topRight,
    right => rect.centerRight,
    bottomRight => rect.bottomRight,
    bottom => rect.bottomCenter,
    bottomLeft => rect.bottomLeft,
    left => rect.centerLeft,
  };

  RectPoint get opposite => switch (this) {
    topLeft => bottomRight,
    top => bottom,
    topRight => bottomLeft,
    right => left,
    bottomRight => topLeft,
    bottom => top,
    bottomLeft => topRight,
    left => right,
  };
}
