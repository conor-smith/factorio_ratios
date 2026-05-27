part of 'graph.dart';

/// Represents a single base on a single surface.
/// In this context, a "base" is just any collection of connected production lines.
/// Not all production lines in a base necessarily need to be connected to eachother.
/// There may be multiple bases per surface.
/// A base may also contain nodes that belong to a different surface.
///
/// A base is ultimately represented by a directed graph.
/// Nodes are of type [ProdLineNode] and can be accessed via [nodes].
/// Edges are of type [DirectedEdge] and can be accessed via [edges].
///
/// There are certain in game production lines that require a loop. Eg.
/// Using [bioflux](https://wiki.factorio.com/Bioflux) to produce
/// [nutrients](https://wiki.factorio.com/Nutrients), then using those same nutrients
/// to power the bioflux machines.
/// As such, loops are permitted, with a small caveat.
/// There exists 2 kinds of edges as given by [DirectedEdge.edgeType] -
/// [Relationship.requestItems] and [Relationship.acceptExcess].
/// While a loop of edges with [Relationship.requestItems] is permitted to exist,
/// edge of type [Relationship.acceptExcess] must not connect back to the graph
/// in a way that forms a loop.
/// For more information on what these relationships mean, see [DirectedEdge].
///
/// This class does use the [ProductionLine] mixin. As such, [inputItems] and
/// [outputItems] are determined by nodes of type [NodeType.input] and [NodeType.output].
/// For each input / output, only one input or output node may exist.
///
/// When [calculate] is called, the constraints placed on each node is determined
/// by the sum of all requirements of its parents.
/// Only nodes with no parents can set their own constraints.
///
/// [inputRatios] and [outputRatios] can only be calculated when
/// * There exists at least one unbroken, single directional path of parent and
/// children nodes linking every input and output node
/// * Every one of these paths at some point passes through though a single
/// node with known IO ratios
/// * There are no producer or consumer nodes connected to any of these paths
/// which might affect the outcome
///
/// This class is also a mutable production line.
/// While [inputItems], [outputItems], [inputRatios] and [outputRatios] are not updated
/// by [calculate], additional nodes may be created to handle excess output of nodes.
///
/// This object also uses the [Stateful] mixin, as does [ProdLineNode] and [DirectedEdge].
/// State update can only be done via [apply], [rollback], and [redo], and even then,
/// restrictions are put in place to ensure that only internal calls to these methods
/// will work. Any other calls will result in a [MutationException] being thrown.
/// This is to ensure tight control over internal state.
///
/// The complex nature of the graphs means that updating the state of one object
/// may affect the state of another.
/// As such, listeners are not notified until all changes in a transaction
/// are completed.
/// Eg. If a particular operation results in multiple new nodes being added,
/// listeners will only receive one update containing all new nodes, rather than
/// one update for each node.
class PlanetBaseGraph with ProductionLine<PlanetBaseIo>, Stateful<GraphEvent> {
  // TODO - support loops
  // TODO - Allow for multiple nodes producing the same item
  final FactorioBase globalData;

  _EventHistory get _history => globalData._history;

  final Surface? surface;
  final SurfaceProperties? surfaceProperties;

  List<ProdLineNode> _nodes;
  List<DirectedEdge> _edges;

  String _name;
  Set<InGameItem> _inputItems;
  Set<InGameItem> _outputItems;
  ItemAmounts? _inputRatios;
  ItemAmounts? _outputRatios;

  GraphGeometry _geometry;

  bool _hasCachedData = false;
  Map<NodeType, Map<InGameItem, List<ProdLineNode>>>? _cachedNodeInputIndex;
  Map<NodeType, Map<InGameItem, List<ProdLineNode>>>? _cachedNodeOutputIndex;

  void _buildNodeCache() {
    if (!_hasCachedData) {
      _cachedNodeInputIndex = {};
      _cachedNodeOutputIndex = {};

      for (var node in _nodes) {
        for (var nodeInput in node.inputItems) {
          _cachedNodeInputIndex!.update(
            node.nodeType,
            (itemNodeMap) => itemNodeMap
              ..update(
                nodeInput,
                (nodeList) => nodeList..add(node),
                ifAbsent: () => [node],
              ),
            ifAbsent: () => {
              nodeInput: [node],
            },
          );
        }

        for (var nodeOutput in node.outputItems) {
          _cachedNodeOutputIndex!.update(
            node.nodeType,
            (itemNodeMap) => itemNodeMap
              ..update(
                nodeOutput,
                (nodeList) => nodeList..add(node),
                ifAbsent: () => [node],
              ),
            ifAbsent: () => {
              nodeOutput: [node],
            },
          );
        }
      }

      _hasCachedData = true;
    }
  }

  void _clearNodeCache() {
    if (_hasCachedData) {
      _cachedNodeInputIndex = null;
      _cachedNodeOutputIndex = null;
      _hasCachedData = false;
    }
  }

  PlanetBaseGraph._root({
    required this.globalData,
    this.surface,
    this.surfaceProperties,
    String? name,
  }) : _name = name ?? surface?.name ?? '',
       _geometry = GraphGeometry.uninitialised,
       _nodes = const [],
       _edges = const [],
       _inputItems = const {},
       _outputItems = const {},
       _inputRatios = const {},
       _outputRatios = const {};

  List<ProdLineNode> get nodes => _nodes;

  /// Full list of all edges currently in graph
  List<DirectedEdge> get edges => _edges;

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
  ItemAmounts? get inputRatios => _inputRatios;
  @override
  ItemAmounts? get outputRatios => _outputRatios;

  @override
  HasIcon? get icon => surface;

  /// Calls [ProdLineNode.calculateAndCache] on all relevant input and output nodes
  /// using [inputConstraints] and [outputConstraints].
  /// Also applies [ProdLineNode.internalInputConstraints] and
  /// [ProdLineNode.internalOutputConstraints] on all consumer nodes.
  ///
  /// From there, the data in [ProdLineNode.ioData] is used to determine the
  /// constraints on all subsequent children and grandchildren nodes recursively
  /// until all affected descendants have their own [ProdLineNode.ioData] fields
  /// appropriately updated.
  ///
  /// If at any point, a node has an input or output not satisfied, they will
  /// be connected to first node of type [NodeType.disposal] or [NodeType.producer]
  /// that satisfies this requirement. If none exists, a new node will be created
  @override
  PlanetBaseIo calculate({
    ItemAmounts inputConstraints = const {},
    ItemAmounts outputConstraints = const {},
  }) {
    // TODO - This method assumes the graph is already 100% verified
    verifyConstraintsAndIo(inputConstraints, outputConstraints);

    PlanetBaseIo? io;
    _history.mutate(() {
      _buildNodeCache();

      Map<ProdLineNode, _IOConstraints> rootNodeConstraints = {};

      inputConstraints.forEach((item, amount) {
        var inputNode = _cachedNodeOutputIndex![NodeType.input]![item]!.first;

        rootNodeConstraints.update(
          inputNode,
          (nodeConstraints) =>
              nodeConstraints..outputConstraints[item] = amount,
          ifAbsent: () => _IOConstraints(outputConstraints: {item: amount}),
        );
      });

      outputConstraints.forEach((item, amount) {
        var outputNode = _cachedNodeOutputIndex![NodeType.output]![item]!.first;

        rootNodeConstraints.update(
          outputNode,
          (nodeConstraints) => nodeConstraints..inputConstraints[item] = amount,
          ifAbsent: () => _IOConstraints(inputConstraints: {item: amount}),
        );
      });

      // Add consumer nodes to rootNodeConstraints graph
      (_cachedNodeInputIndex![NodeType.consumer] ?? const {}).values
          .expand((nodes) => nodes)
          .where((node) => node.hasInternalConstraints)
          .forEach(
            (consumerNode) =>
                rootNodeConstraints[consumerNode] = _IOConstraints(
                  inputConstraints: consumerNode.internalInputConstraints,
                  outputConstraints: consumerNode.internalOutputConstraints,
                ),
          );

      Set<ProdLineNode> solvedNodes = {};
      Map<ProdLineNode, _IOConstraints> unfulfilledIo = {};
      for (var rootNode in rootNodeConstraints.keys) {
        _determineIoAndApplyToChildren(
          solvedNodes,
          rootNodeConstraints,
          unfulfilledIo,
          rootNode,
        );
      }

      if (unfulfilledIo.isNotEmpty) {
        Map<InGameItem, ProdLineNode> disposalNodes = Map.from(
          _cachedNodeInputIndex![NodeType.disposal] ?? {},
        );
        Map<InGameItem, ProdLineNode> producerNodes = Map.from(
          _cachedNodeOutputIndex![NodeType.producer] ?? {},
        );

        List<ProdLineNode> nodesToUpdate = [];

        unfulfilledIo.forEach((node, nodeIo) {
          nodeIo.inputConstraints.forEach((unfulfilledInput, amount) {
            ProdLineNode producerNode;
            if (producerNodes.containsKey(unfulfilledInput)) {
              producerNode = producerNodes[unfulfilledInput]!;
            } else {
              producerNode = ProdLineNode.addToGraph(
                parentGraph: this,
                nodeType: NodeType.producer,
                line: IoLine(
                  name: unfulfilledInput.name,
                  netOutputs: {unfulfilledInput},
                ),
              );

              producerNodes[unfulfilledInput] = producerNode;
            }
            nodesToUpdate.add(producerNode);

            var newEdge = DirectedEdge.addToGraph(
              parentGraph: this,
              item: unfulfilledInput,
              parent: node,
              child: producerNode,
              edgeType: Relationship.requestItems,
              initialAmount: amount,
            );

            apply(GraphEvent.newEdge(this, newEdge));
          });

          nodeIo.outputConstraints.forEach((unfulfilledOutput, amount) {
            ProdLineNode disposalNode;
            if (disposalNodes.containsKey(unfulfilledOutput)) {
              disposalNode = disposalNodes[unfulfilledOutput]!;
            } else {
              disposalNode = ProdLineNode.addToGraph(
                parentGraph: this,
                nodeType: NodeType.disposal,
                line: IoLine(
                  name: unfulfilledOutput.name,
                  netInputs: {unfulfilledOutput},
                ),
              );

              disposalNodes[unfulfilledOutput] = disposalNode;
            }
            nodesToUpdate.add(disposalNode);

            var newEdge = DirectedEdge.addToGraph(
              parentGraph: this,
              item: unfulfilledOutput,
              parent: node,
              child: disposalNode,
              edgeType: Relationship.acceptExcess,
              initialAmount: amount,
            );

            apply(GraphEvent.newEdge(this, newEdge));
          });

          for (var node in nodesToUpdate) {
            // TODO - make this into it's own method somewhere
            for (var edge in node._parents) {
              var edgeAmount = edge._amount ?? 0.0;

              if (edgeAmount > 0) {
                if (edge.flowDirection == ItemFlowDirection.childToParent) {
                  outputConstraints.update(
                    edge.item,
                    (amount) => amount + edgeAmount,
                    ifAbsent: () => edgeAmount,
                  );
                } else {
                  inputConstraints.update(
                    edge.item,
                    (amount) => amount + edgeAmount,
                    ifAbsent: () => edgeAmount,
                  );
                }
              }
            }
          }
        });
      }

      ItemAmounts finalInput = {};
      ItemAmounts finalOutput = {};
      Map<String, double> finalPollution = {};
      double finalPowerConsumption = 0.0;

      for (var node in nodes) {
        switch (node.nodeType) {
          case NodeType.input:
            finalInput.addAll(node.ioData?.netOutput ?? const {});
          case NodeType.output:
            finalOutput.addAll(node.ioData?.netInput ?? const {});
          default:
            finalPowerConsumption +=
                (node.ioData?.electricPowerConsumption ?? 0.0);
            (node.ioData?.emissions ?? const {}).forEach(
              (emission, amount) => finalPollution.update(
                emission,
                (currentAmount) => currentAmount + amount,
                ifAbsent: () => amount,
              ),
            );
        }
      }

      io = PlanetBaseIo(
        inputConstraints: inputConstraints,
        outputConstraints: outputConstraints,
        netOutput: finalOutput,
        netInput: finalInput,
        electricPowerConsumption: finalPowerConsumption,
        pollution: finalPollution,
      );
    });

    return io!;
  }

  // Solves nodes using depth first traversal
  void _determineIoAndApplyToChildren(
    Set<ProdLineNode> solvedNodes,
    Map<ProdLineNode, _IOConstraints> rootNodeConstraints,
    Map<ProdLineNode, _IOConstraints> unfulfilledIo,
    ProdLineNode nodeToSolve,
  ) {
    // TODO - handle loops

    // If node IO has already been determined
    if (solvedNodes.contains(nodeToSolve)) {
      return;
    }

    // If node has no constraints and no parents, leave unsolved
    if (nodeToSolve.parents.isEmpty &&
        !rootNodeConstraints.containsKey(nodeToSolve)) {
      solvedNodes.add(nodeToSolve);

      if (nodeToSolve._ioData != null) {
        nodeToSolve.apply(NodeEvent.clearIo(nodeToSolve));
      }
      for (var childEdge in nodeToSolve.children) {
        if (childEdge._amount != null) {
          childEdge.apply(EdgeEvent.clearAmount(childEdge));
        }
      }

      return;
    }

    // Determine constraints from sum of parent edge amounts, or root node constraints
    ItemAmounts inputConstraints, outputConstraints;
    if (rootNodeConstraints.containsKey(nodeToSolve)) {
      inputConstraints = rootNodeConstraints[nodeToSolve]!.inputConstraints;
      outputConstraints = rootNodeConstraints[nodeToSolve]!.outputConstraints;
    } else {
      inputConstraints = {};
      outputConstraints = {};

      for (var edge in nodeToSolve._parents) {
        // Solve parent if not already solved
        if (!solvedNodes.contains(edge.parent)) {
          _determineIoAndApplyToChildren(
            solvedNodes,
            rootNodeConstraints,
            unfulfilledIo,
            edge.parent,
          );
        }

        var edgeAmount = edge._amount ?? 0.0;

        if (edgeAmount > 0) {
          if (edge.flowDirection == ItemFlowDirection.childToParent) {
            outputConstraints.update(
              edge.item,
              (amount) => amount + edgeAmount,
              ifAbsent: () => edgeAmount,
            );
          } else {
            inputConstraints.update(
              edge.item,
              (amount) => amount + edgeAmount,
              ifAbsent: () => edgeAmount,
            );
          }
        }
      }
    }

    ProductionLineIo newIoData;
    if (nodeToSolve._ioData != null &&
        _compareItemIo(
          nodeToSolve._ioData!.inputConstraints,
          inputConstraints,
        ) &&
        _compareItemIo(
          nodeToSolve._ioData!.outputConstraints,
          outputConstraints,
        )) {
      // If constraints are similar enough to last time, no need to calculate again
      newIoData = nodeToSolve.ioData!;
    } else {
      newIoData = nodeToSolve._productionLine.calculate(
        inputConstraints: inputConstraints,
        outputConstraints: outputConstraints,
      );

      nodeToSolve.apply(NodeEvent.newIo(nodeToSolve, newIoData));
    }

    nodeToSolve._buildEdgeCache();

    newIoData.netInput.forEach((inputItem, amount) {
      var childInputEdge =
          (nodeToSolve._cachedInputEdges![inputItem] ?? const [])
              .where((edge) => edge.edgeType == Relationship.requestItems)
              .firstOrNull;

      var requiredInput = amount - (inputConstraints[inputItem] ?? 0.0).abs();
      requiredInput = requiredInput > 0.001 ? requiredInput : 0.0;

      if (childInputEdge != null) {
        childInputEdge.apply(
          EdgeEvent.newAmount(childInputEdge, requiredInput),
        );
      } else if (requiredInput > 0) {
        unfulfilledIo.update(
          nodeToSolve,
          (ioConstraints) =>
              ioConstraints..inputConstraints[inputItem] = requiredInput,
          ifAbsent: () =>
              _IOConstraints(inputConstraints: {inputItem: requiredInput}),
        );
      }
    });

    newIoData.netOutput.forEach((outputItem, amount) {
      var childOutputEdge =
          (nodeToSolve._cachedInputEdges![outputItem] ?? const [])
              .where((edge) => edge.edgeType == Relationship.acceptExcess)
              .firstOrNull;

      var requiredOutput =
          amount - (outputConstraints[outputItem] ?? 0.0).abs();
      requiredOutput = requiredOutput > 0.001 ? requiredOutput : 0.0;

      if (childOutputEdge != null) {
        childOutputEdge.apply(
          EdgeEvent.newAmount(childOutputEdge, requiredOutput),
        );
      } else if (requiredOutput > 0) {
        unfulfilledIo.update(
          nodeToSolve,
          (ioConstraints) =>
              ioConstraints..outputConstraints[outputItem] = requiredOutput,
          ifAbsent: () =>
              _IOConstraints(outputConstraints: {outputItem: requiredOutput}),
        );
      }
    });

    solvedNodes.add(nodeToSolve);
  }

  // TODO
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
        .map((node) => node._children.map((edge) => edge.child))
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
  }

  /* ------------ User Operations ------------ */

  /// Adds a new [NodeType.consumer] node (or finds an existing one) that
  /// consumes [item].
  /// Then builds a tree of nodes recursively running the following process
  /// on the new node, and on all subsequent descendents.
  ///
  /// For every unfulfilled [InGameItem] input of a selected node (as given by
  /// [ProdLineNode.inputItems]), a new [DirectedEdge] of type
  /// [Relationship.requestItems] will be created.
  /// The child node ([DirectedEdge.child]) will either be selected or created
  /// via the following process
  /// 1. Check existing nodes for one that outputs relevant item
  ///   * Check nodes of type [NodeType.input]
  ///   * Check nodes of type [NodeType.producer]
  ///   * Check nodes of type [NodeType.productionLine]
  /// 2. Create a new node based on the value of [surface]
  ///   * Check [Surface.resources] for item. Create [NodeType.producer] node if item is present.
  ///   * Check [SurfaceProperties.defaultRecipes] for valid [Recipe].
  /// If one exists, create a [NodeType.productionLine] node with a
  /// [SingleRecipeLine] using fastest valid machine
  ///   * Create [NodeType.producer] node with an [IoLine] producing the item
  void addConsumerNodeAndTree(InGameItem item) {
    // Return if consumer node already exists

    if (surface == null) {
      throw GraphException('Cannot build node tree on graph with no surface');
    }

    _history.mutate(() {
      _buildNodeCache();

      // Saving node cache locally as it is wiped every time a new node is added
      var nodeOutputIndex = _cachedNodeOutputIndex!;

      // Either find existing node, or create one
      var rootConsumerNode =
          _cachedNodeInputIndex![NodeType.consumer]?[item]?[0] ??
          ProdLineNode.addToGraph(
            parentGraph: this,
            nodeType: NodeType.consumer,
            line: IoLine(name: '$item consumer', netInputs: {item}),
          );

      _createRecipeTree(rootConsumerNode, nodeOutputIndex, {});

      // TODO - Don't use treeLayout for everything
      treeLayout();
    });
  }

  /// Uses tree structure and heirarchy to determine node positions
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

  /// Completely clears all [nodes] and [edges] with the exception
  /// of input and output nodes
  void clearAllNodes() {
    // TODO - Create new nodes to supply remaining IO nodes
    _history.mutate(() {
      for (var node in nodes) {
        node.apply(NodeEvent.clearParentsAndChildren(node));
      }

      apply(GraphEvent.clearGraph(this));

      _redoGraphGeometry();
    });
  }

  // Creates full tree for parentNode and all descendents
  // Does this by either finding or creating nodes for each input of parentNode
  // Then recursively calls itself on each child node
  // This is still called on nodes that already exist in order to ensure full
  // tree is created
  void _createRecipeTree(
    ProdLineNode inputNode,
    Map<NodeType, Map<InGameItem, List<ProdLineNode>>> nodeOutputIndex,
    Set<ProdLineNode> visitedNodes,
  ) {
    visitedNodes.add(inputNode);

    // Store node cache locally as it gets wiped for every new edge
    inputNode._buildEdgeCache();
    var nodeInputCache = inputNode._cachedInputEdges!;

    // Only add edges where no input edge already exists
    for (var input in inputNode.inputItems) {
      // Find existing children that satisfy input
      var itemInputEdges = nodeInputCache[input];

      if (itemInputEdges == null) {
        // If no children exist, find existing node that can satisfy input
        var producerNode =
            nodeOutputIndex[NodeType.input]?[input]?[0] ??
            nodeOutputIndex[NodeType.producer]?[input]?[0] ??
            nodeOutputIndex[NodeType.productionLine]?[input]?[0];

        if (producerNode == null) {
          // If no node exists, create new node to satisfy input
          producerNode =
              _createResourceNode(input) ??
              _createRecipeNode(input) ??
              _createProducerNode(input);

          nodeOutputIndex.update(
            producerNode.nodeType,
            (itemMap) => itemMap
              ..update(
                input,
                (itemNodes) => itemNodes..add(producerNode!),
                ifAbsent: () => [producerNode!],
              ),
            ifAbsent: () => {
              input: [producerNode!],
            },
          );
        }

        // Create edge between producerNode and parentNode
        itemInputEdges = [
          DirectedEdge.addToGraph(
            parentGraph: this,
            item: input,
            parent: inputNode,
            child: producerNode,
            edgeType: Relationship.requestItems,
          ),
        ];
      }

      // Call _createRecipeTree on all unvisited input nodes
      itemInputEdges
          .map(
            (edge) => switch (edge.flowDirection) {
              ItemFlowDirection.childToParent => edge.child,
              ItemFlowDirection.parentToChild => edge.parent,
            },
          )
          .where((node) => !visitedNodes.contains(node))
          .forEach(
            (node) => _createRecipeTree(node, nodeOutputIndex, visitedNodes),
          );
    }
  }

  ProdLineNode? _createResourceNode(InGameItem item) {
    // TODO - Appropriate resource extraction production line
    if (surfaceProperties!.resources.contains(item)) {
      return ProdLineNode.addToGraph(
        parentGraph: this,
        nodeType: NodeType.productionLine,
        line: IoLine(name: '$item resource', netOutputs: {item}),
      );
    } else {
      return null;
    }
  }

  ProdLineNode? _createRecipeNode(InGameItem item) {
    // TODO - account for null surface
    var producerRecipe = surfaceProperties!.defaultRecipes
        .where((recipe) => item.internalItem.producedBy.contains(recipe))
        .firstOrNull;

    if (producerRecipe != null) {
      // If recipe exists, create production line node
      var fastestMachine = globalData.sortedMachines.firstWhere(
        (machine) => machine.recipes.contains(producerRecipe),
      );

      InGameSolidItem? fuel;
      if (fastestMachine.energySource.type == EnergySourceType.burner) {
        BurnerEnergySource energySource =
            fastestMachine.energySource as BurnerEnergySource;

        fuel = surfaceProperties!.availableSolidFuels
            .where(
              (surfaceFuel) =>
                  energySource.fuelItems.contains(surfaceFuel.internalItem),
            )
            .firstOrNull;

        fuel ??= InGameSolidItem(energySource.fuelItems.first);
      }

      var recipeQuality = item is InGameSolidItem ? item.quality : 1;

      return ProdLineNode.addToGraph(
        parentGraph: this,
        nodeType: NodeType.productionLine,
        line: SingleRecipeLine(
          ProductionLineCraftingMachine(fastestMachine),
          InGameRecipe(producerRecipe, recipeQuality),
          surface: surface,
          fuel: fuel,
        ),
      );
    } else {
      return null;
    }
  }

  ProdLineNode _createProducerNode(InGameItem item) {
    return ProdLineNode.addToGraph(
      parentGraph: this,
      nodeType: NodeType.producer,
      line: IoLine(name: '$item producer', netOutputs: {item}),
    );
  }

  /* ------------- Stateful methods ------------- */
  @override
  void apply(GraphEvent event) {
    _apply(event);

    _history.addGraphEvent(event);

    if (event.mutations.contains(GraphEventType.updateNodes)) {
      _clearNodeCache();
    }
  }

  @override
  void redo(GraphEvent event) {
    _apply(event);

    _clearNodeCache();
  }

  @override
  void rollback(GraphEvent event) {
    _apply(event.reversed);

    _clearNodeCache();
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
  GraphGeometry get geometry => _geometry;

  GeometryOperation beginDragOperation(
    Iterable<ProdLineNode> nodes,
    Iterable<DirectedEdge> edges,
  ) => GeometryOperation.dragOperation(Set.from(nodes), Set.from(edges));

  GeometryOperation beginResizeOperation(
    List<ProdLineNode> nodes,
    ProdLineNode selectedNode,
    RectPoint selectedPoint,
  ) => GeometryOperation.resizeOperation(
    Set.from(nodes),
    selectedNode,
    selectedPoint,
  );

  void finishGeometryOperation(GeometryOperation geometryOperation) {
    _history.mutate(() {
      geometryOperation.applyNewGeometryAndFinish();
      // TODO - Find a more efficient way to do this
      _redoGraphGeometry();
    });
  }

  List<Geometry> _getAllGeometryData() => _nodes
      .map<Geometry>((node) => node.geometry)
      .followedBy(_edges.map((edge) => edge.geometry))
      .toList();

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

      for (var edge in node.children) {
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

// TODO - Move to production_line.dart
class _IOConstraints {
  final ItemAmounts inputConstraints;
  final ItemAmounts outputConstraints;

  _IOConstraints({
    ItemAmounts? inputConstraints,
    ItemAmounts? outputConstraints,
  }) : inputConstraints = inputConstraints ?? {},
       outputConstraints = outputConstraints ?? {};
}

// TODO - Move to production_line.dart
bool _compareItemIo(ItemAmounts io1, ItemAmounts io2) =>
    io1 == io2 ||
    (io1.length == io2.length &&
        io1.entries.every((entry) {
          var io2Value = io2[entry.key];

          return io2Value != null &&
              (io2Value == entry.value ||
                  (entry.value - io2Value).abs() < 0.001);
        }));
