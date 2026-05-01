part of 'graph.dart';

/// Maintains a full graph
/// This acts as the state for the application, and the single source of truth
///
/// All contained objects are mutateable
/// Mutating state must only be done through specific methods, even within the classes
/// This means that mutations can be rolled back if need be
/// Mutateables are also listenable, and will only notifyListeners when instructed to
///
/// As nodes can contain graphs, the entire structure can be thought of as a tree
/// In a tree, there is only one eventHistory object
/// All mutations must be done within eventHistory._mutate(...)
/// An arbitrary number of mutations can occur before committing
/// At commit, all uncommitted events are combined into one single event
///
/// The complex nature of the graphs means that updating the state of one object
/// may affect the state of another
/// Eg. Updating nodeType to "output" will result in the node's inputs
/// being added to it's parentGraph's outputs
/// As such, listeners should not be notified until all changes in a transaction
/// are completed
///
/// The root graph of a tree will never have requirements
/// This is because requirements determine input and output,
/// and the root graph has nowhere to input or output to
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

  GraphGeometry _geometry;

  /* ---------------- Accessors ---------------- */
  late final List<ProdLineNode> nodes = UnmodifiableListView(_nodes);
  late final List<DirectedEdge> edges = UnmodifiableListView(_edges);

  GraphGeometry get geometry => _geometry;

  @override
  late final Set<ItemData> netInputs = UnmodifiableSetView(_allInputs);
  @override
  late final Set<ItemData> netOutputs = UnmodifiableSetView(_allOutputs);

  @override
  ItemIo? get requirements => _requirements;
  @override
  ItemIo? get totalIoPerSecond => _totalIoPerSecond;

  @override
  bool get immutableIo => false;
  @override
  String get type => 'graph';

  GeometryOperation? _geometryOperation;

  /* --------------- Constructors --------------- */
  BaseGraph.root({this.surface})
    : _parentNode = null,
      _eventHistory = _EventHistory(_maxSavedEvents),
      _geometry = GraphGeometry.uninitialised;

  BaseGraph._addToTree({this.surface, required _EventHistory eventHistory})
    : _eventHistory = eventHistory,
      _geometry = GraphGeometry.uninitialised;

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
        case GraphEventType.geometryUpdate:
          _geometry = event.newGeometry!;

        case GraphEventType.updateNodes:
          _nodes.removeAll(event.removedNodes);
          _nodes.addAll(event.newNodes);

        case GraphEventType.updateEdges:
          _edges.removeAll(event.removedEdges);
          _edges.addAll(event.newEdges);

        case GraphEventType.updateInput:
          netInputs.removeAll(event.removedInputs);
          netInputs.addAll(event.newInputs);

        case GraphEventType.updateOutput:
          netOutputs.removeAll(event.removedOutputs);
          netOutputs.addAll(event.newOutputs);
      }
    }
  }

  /* ----------- Geometry Operations ----------- */
  void _throwIfNoGeometricOp() {
    if (_geometryOperation == null) {
      throw const GraphException('No geometry operation taking place');
    }
  }

  void _throwIfGeometricOp() {
    if (_geometryOperation != null) {
      throw const GraphException('Geometry operation currently taking place');
    }
  }

  List<Geometry> _getAllGeometryData() => _nodes
      .map<Geometry>((node) => node.geometry)
      .followedBy(_edges.map((edge) => edge.geometry))
      .toList();

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

          node.apply(NodeEvent.updateGeometry(node, NodeGeometry(newRect)));
        }
      }

      for (var edge in _edges) {
        edge._shortestLineBetweenNodes();
      }

      _redoGraphGeometry();
    });
  }

  void beginMultiNodeDrag(List<ProdLineNode> nodes, List<DirectedEdge> edges) {
    _throwIfGeometricOp();

    _geometryOperation = GeometryOperation.dragOperation(
      Set.from(nodes),
      Set.from(edges),
    );
  }

  void beginMultiNodeResize(
    List<ProdLineNode> nodes,
    ProdLineNode selectedNode,
    RectPoint selectedPoint,
  ) {
    _throwIfGeometricOp();

    _geometryOperation = GeometryOperation.resizeOperation(
      Set.from(nodes),
      selectedNode,
      selectedPoint,
    );
  }

  void _finishGeometricOp() {
    _throwIfNoGeometricOp();

    // _eventHistory.mutate(() {
    //   var nodeEvents = _geometryOperation!.nodeGeometry
    //       .map((data) => NodeEvent.updateGeometry(data.node, data.finish()))
    //       .toList();

    //   var edgeEvents = _geometryOperation!.edgeGeometry
    //       .followedBy(_geometryOperation!.affectedEdgeGeometry)
    //       .map((data) => EdgeEvent.updateGeometry(data.edge, data.finish()));

    //   List<Geometry> removedGeometry = [];
    //   List<Geometry> newGeometry = [];
    //   for (var nodeEvent in nodeEvents) {
    //     nodeEvent.node.apply(nodeEvent);
    //     removedGeometry.add(nodeEvent.oldGeometry!);
    //     newGeometry.add(nodeEvent.newGeometry!);
    //   }
    //   for (var edgeEvent in edgeEvents) {
    //     edgeEvent.edge.apply(edgeEvent);
    //     removedGeometry.add(edgeEvent.oldGeometry!);
    //     newGeometry.add(edgeEvent.newGeometry!);
    //   }

    //   var allGeometryData = _getAllGeometryData();

    //   Geometry? left = _findNewMaxGeometry(
    //         allGeometryData,
    //         Geometry.leftMost,
    //         oldMaxGeometry: _geometry.left,
    //         removedGeometry: removedGeometry,
    //         newGeometry: newGeometry,
    //       ),
    //       top = _findNewMaxGeometry(
    //         allGeometryData,
    //         Geometry.topMost,
    //         oldMaxGeometry: _geometry.top,
    //         removedGeometry: removedGeometry,
    //         newGeometry: newGeometry,
    //       ),
    //       right = _findNewMaxGeometry(
    //         allGeometryData,
    //         Geometry.rightMost,
    //         oldMaxGeometry: _geometry.right,
    //         removedGeometry: removedGeometry,
    //         newGeometry: newGeometry,
    //       ),
    //       bottom = _findNewMaxGeometry(
    //         allGeometryData,
    //         Geometry.bottomMost,
    //         oldMaxGeometry: _geometry.bottom,
    //         removedGeometry: removedGeometry,
    //         newGeometry: newGeometry,
    //       );

    //   if (left != null || top != null || right != null || bottom != null) {
    //     apply(
    //       GraphEvent.updateGeometry(
    //         this,
    //         GraphGeometry.fromLTRB(
    //           left ?? _geometry.left!,
    //           top ?? _geometry.top!,
    //           right ?? _geometry.top!,
    //           bottom ?? _geometry.bottom!,
    //         ),
    //       ),
    //     );
    //   }

    //   _geometryOperation = null;
    // });
  }

  // Must be called after all geometry objects have been updated
  Geometry? _findNewMaxGeometry(
    List<Geometry> allCurrentGeometry,
    Comparator<Geometry> comparator, {
    Geometry? oldMaxGeometry,
    List<Geometry> removedGeometry = const [],
    List<Geometry> newGeometry = const [],
  }) {
    Geometry? newMaxGeometry;

    if (allCurrentGeometry.isEmpty) {
      return null;
    } else if (oldMaxGeometry == null ||
        removedGeometry.contains(oldMaxGeometry)) {
      newMaxGeometry = allCurrentGeometry.first;
      for (var geometry in allCurrentGeometry.skip(1)) {
        if (comparator(geometry, newMaxGeometry!) > 0) {
          newMaxGeometry = geometry;
        }
      }
    } else {
      for (var geometry in newGeometry) {
        if (comparator(geometry, oldMaxGeometry) > 0) {
          newMaxGeometry = geometry;
        }
      }
    }

    return newMaxGeometry;
  }

  // Assumes all positional data objects are invalid
  // Scans all nodes and edge objects for new ones
  void _redoGraphGeometry() {
    if (_nodes.isEmpty) {
      apply(GraphEvent.clearGeometry(this));
    } else {
      var allGeometryData = _getAllGeometryData();

      Geometry top = _findNewMaxGeometry(allGeometryData, Geometry.topMost)!,
          left = _findNewMaxGeometry(allGeometryData, Geometry.leftMost)!,
          bottom = _findNewMaxGeometry(allGeometryData, Geometry.bottomMost)!,
          right = _findNewMaxGeometry(allGeometryData, Geometry.rightMost)!;

      apply(
        GraphEvent.updateGeometry(
          this,
          GraphGeometry.fromLTRB(left, top, right, bottom),
        ),
      );
    }
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
