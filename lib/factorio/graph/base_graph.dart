part of 'graph.dart';

/// Represents a single base / collections of production lines on a single planet surface.
/// There may be multiple bases per surface.
/// A base may also contain nodes that belong to a different surface.
///
/// Ultimately represents a graph with several [nodes] connected by directed [edges].
/// If this base is contained within a node of a parent graph, inputs and outputs
/// are given by [nodes] of type [NodeType.input] or [NodeType.output].
/// Input and output nodes are not production lines themselves.
/// They merely represent an entry point for inputs or an endpoint for outputs
/// of other production lines.
///
/// Every edge has a parent and a child.
/// However, it should be known that the parent isn't necessarily the consumer
/// of the child's outputs.
/// Rather, relationships are determined by which node can set restraints on another.
/// While the majority of parents will be consumers of their children's outputs,
/// there are certain scenarios the parent is a producer.
///
/// Eg. In the actual game of factorio, producing molten iron from lava also produces stone.
/// If this stone is not disposed of, the production line backs up and iron cannot
/// be produced.
/// In this application, this would be represented by an edge of type
/// [Relationship.acceptExcess], sending excess stone to another node and setting
/// an input constraint.
///
/// When [calculate] is called, the constraints placed on each node is determined
/// by the sum of all requirements of its parents.
/// Only nodes with no parents can set their own constraints.
///
/// [inputRatios] and [outputRatios] can only be calculated when
/// * There exists an unbroken, single directional chain of parent and children nodes with
/// known IO ratios between all existing output and input nodes
/// * This chain starts with only one production line node
/// * No internal nodes have any requirements beyond those provided to them by parents
///
/// All contained objects are muteable.
/// Mutating state must only be done through specific methods, even within the classes.
/// This means that mutations can be rolled back if need be.
/// Mutateables are also listenable, and will only notifyListeners when instructed to.
///
/// This class is also a mutable production line.
/// While [inputItems], [outputItems], [inputRatios] and [outputRatios] are not updated
/// by [calculate], additional nodes may be created to handle excess output of nodes.
///
/// The complex nature of the graphs means that updating the state of one object
/// may affect the state of another.
/// Eg. Updating nodeType to "output" will result in the node's inputs
/// being added to it's parentGraph's outputs.
/// As such, listeners should not be notified until all changes in a transaction
/// are completed.
class PlanetBase with ProductionLine<PlanetBaseIo>, Stateful<GraphEvent> {
  final FactorioBase globalData;

  _EventHistory get _history => globalData._history;

  final Surface? surface;
  final _SurfaceProperties? _surfaceProperties;

  List<ProdLineNode> _nodes;
  List<DirectedEdge> _edges;

  String _name;
  Set<InGameItem> _inputItems;
  Set<InGameItem> _outputItems;
  ItemIo? _inputRatios;
  ItemIo? _outputRatios;

  GraphGeometry _geometry;
  GeometryOperation? _geometryOperation;

  List<ProdLineNode> get nodes => _nodes;
  List<DirectedEdge> get edges => _edges;

  GraphGeometry get geometry => _geometry;

  /* --------------- Constructors --------------- */
  PlanetBase._root({
    required this.globalData,
    this.surface,
    String? name,
    _SurfaceProperties? surfaceProperties,
  }) : _surfaceProperties = surfaceProperties,
       _name = name ?? surface?.name ?? '',
       _geometry = GraphGeometry.uninitialised,
       _nodes = const [],
       _edges = const [],
       _inputItems = const {},
       _outputItems = const {},
       _inputRatios = const {},
       _outputRatios = const {};

  /* ------------ Production Line ------------ */
  @override
  String get name => _name;
  @override
  String get type => 'graph';
  @override
  bool get isImmutable => false;

  @override
  Set<InGameItem> get inputItems => _inputItems;
  @override
  Set<InGameItem> get outputItems => _outputItems;

  @override
  ItemIo? get inputRatios => _inputRatios;
  @override
  ItemIo? get outputRatios => _outputRatios;

  @override
  List<IconData>? get icon => surface?.icons;

  @override
  PlanetBaseIo calculate({
    ItemIo inputConstraints = const {},
    ItemIo outputConstraints = const {},
  }) {
    // TODO
    throw UnimplementedError();
  }

  void _calculateIoRatios() {
    var ioNodes = _nodes.where((node) => node.nodeType.isIo).toList();

    if (ioNodes.isEmpty) {
      // Perform an additional check to see if update actually needs to happen
      if (_inputRatios == null ||
          _inputRatios!.isNotEmpty ||
          _outputRatios!.isNotEmpty) {
        _history.mutate(() {
          apply(
            GraphEvent.newIoRatios(
              this,
              newInputRatios: const {},
              newOutputRatios: const {},
            ),
          );
        });
      }

      return;
    }

    var directChildren = ioNodes
        .map((node) => node._parentOf.map((edge) => edge.child))
        .expand((children) => children)
        .toSet();

    if (directChildren.length != 1) {
      // Perform an additional check to see if update actually needs to happen
      if (_inputRatios != null) {
        _history.mutate(() {
          apply(GraphEvent.clearGeometry(this));
        });
      }

      return;
    }

    // TODO - Calculate ratios
  }

  /* ------------- Stateful methods ------------- */
  @override
  void apply(GraphEvent event) {
    _apply(event);

    _history.addGraphEvent(event);
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
    _history.checkIfMutationPermitted();

    for (var mutationType in event.mutations) {
      switch (mutationType) {
        case GraphEventType.updateNodes:
          _nodes = event.newNodes!;

        case GraphEventType.updateEdges:
          _edges = event.newEdges!;

        case GraphEventType.updateInput:
          _inputItems = event.newInputs!;

        case GraphEventType.updateOutput:
          _outputItems = event.newOutputs!;

        case GraphEventType.updateRatios:
          _inputRatios = event.newInputRatios;
          _outputRatios = event.newOutputRatios;

        case GraphEventType.geometryUpdate:
          _geometry = event.newGeometry!;
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
    _history.mutate(() {
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
    // _throwIfNoGeometricOp();

    // _history.mutate(() {
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
  // Will not clear input and output nodes
  void clearAllNodes() {
    // TODO - Create new nodes to supply remaining IO nodes
    _history.mutate(() {
      var nonIoNodes = _nodes.where((node) => !node.nodeType.isIo).toList();

      for (var node in nonIoNodes) {
        node.removeFromGraph();
      }
    });
  }

  // void addConsumerNodeAndTree(
  //   ItemData itemData,
  //   List<CraftingMachine> sortedMachines,
  //   List<Recipe> recipes,
  //   List<ItemData> resources,
  //   List<ItemData> availableFuels,
  // ) {
  //   // Return if consumer node already exists
  //   if (_nodes.any(
  //     (node) =>
  //         node.nodeType == NodeType.consumer &&
  //         node.allInputs.contains(itemData),
  //   )) {
  //     return;
  //   }

  //   _history.mutate(() {
  //     var newConsumerNode = ProdLineNode.addToGraph(
  //       parentGraph: this,
  //       type: NodeType.consumer,
  //       line: IoLine(inputs: {itemData}),
  //     );

  //     // TODO - Cache this somehow
  //     Map<ItemData, List<ProdLineNode>> producers = {};
  //     for (var node in _nodes) {
  //       for (var output in node.allOutputs) {
  //         producers.update(
  //           output,
  //           (pNodes) => pNodes..add(node),
  //           ifAbsent: () => [node],
  //         );
  //       }
  //     }

  //     _createRecipeTree(
  //       newConsumerNode,
  //       sortedMachines,
  //       recipes,
  //       resources,
  //       availableFuels,
  //       producers,
  //     );

  //     // TODO - Don't use treeLayout for everything
  //     treeLayout();
  //   });
  // }

  // void _createRecipeTree(
  //   ProdLineNode parentNode,
  //   List<CraftingMachine> sortedMachines,
  //   List<Recipe> recipes,
  //   List<ItemData> resources,
  //   List<ItemData> availableFuels,
  //   Map<ItemData, List<ProdLineNode>> producers,
  // ) {
  //   for (var input in parentNode.allInputs) {
  //     var childNode = producers[input]?.first;

  //     if (childNode == null) {
  //       childNode =
  //           _createResourceNode(input, resources) ??
  //           _createRecipeNode(input, sortedMachines, recipes, availableFuels) ??
  //           _createProducerNode(input);

  //       producers[input] = [childNode];

  //       _createRecipeTree(
  //         childNode,
  //         sortedMachines,
  //         recipes,
  //         resources,
  //         availableFuels,
  //         producers,
  //       );
  //     }

  //     if (!childNode.parentOf.any((edge) => edge.child == childNode)) {
  //       DirectedEdge.addToGraph(
  //         parentGraph: this,
  //         item: input,
  //         parent: parentNode,
  //         child: childNode,
  //         edgeType: Relationship.requestItems,
  //       );
  //     }
  //   }
  // }

  // ProdLineNode? _createResourceNode(
  //   ItemData itemData,
  //   List<ItemData> resources,
  // ) {
  //   if (resources.contains(itemData)) {
  //     return ProdLineNode.addToGraph(
  //       parentGraph: this,
  //       type: NodeType.producer,
  //       line: IoLine(outputs: {itemData}),
  //     );
  //   } else {
  //     return null;
  //   }
  // }

  // ProdLineNode? _createRecipeNode(
  //   ItemData itemData,
  //   List<CraftingMachine> sortedMachines,
  //   List<Recipe> recipes,
  //   List<ItemData> availableFuels,
  // ) {
  //   // TODO - account for null surface
  //   var producerRecipe = recipes
  //       .where(
  //         (recipe) =>
  //             itemData.item.producedBy.contains(recipe) &&
  //             (recipe.itemIo[itemData.item] ?? -1) > 0,
  //       )
  //       .firstOrNull;

  //   if (producerRecipe != null) {
  //     // If recipe exists, create production line node
  //     var fastestMachine = sortedMachines.firstWhere(
  //       (machine) => machine.recipes.contains(producerRecipe),
  //     );

  //     ItemData? fuel;
  //     if (fastestMachine.energySource.type == EnergySourceType.burner) {
  //       BurnerEnergySource energySource =
  //           fastestMachine.energySource as BurnerEnergySource;

  //       // TODO - Account for surfaces without available fuel
  //       fuel = availableFuels.firstWhere(
  //         (fuel) => energySource.fuelItems.contains(fuel.item),
  //       );
  //     }

  //     return ProdLineNode.addToGraph(
  //       parentGraph: this,
  //       type: NodeType.productionLine,
  //       line: SingleRecipeLine(
  //         MutableModuledMachineAndRecipe(
  //           craftingMachine: fastestMachine,
  //           recipe: producerRecipe,
  //           fuel: fuel,
  //         ).makeImmutable(),
  //       ),
  //     );
  //   } else {
  //     return null;
  //   }
  // }

  // ProdLineNode _createProducerNode(ItemData itemData) {
  //   return ProdLineNode.addToGraph(
  //     parentGraph: this,
  //     type: NodeType.producer,
  //     line: IoLine(outputs: {itemData}),
  //   );
  // }

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

class PlanetBaseIo extends ProductionLineIo {
  PlanetBaseIo({
    required super.inputConstraints,
    required super.outputConstraints,
    required super.netOutput,
    required super.netInput,
    required super.electricPowerConsumption,
    required super.pollution,
    super.displayData,
  });
}
