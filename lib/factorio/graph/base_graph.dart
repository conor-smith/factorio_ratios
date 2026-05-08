part of 'graph.dart';

/// Represents a single base / collections of production lines on a single planet surface.
/// There may be multiple bases per surface.
/// A base may also contain nodes that belong to a different surface.
///
/// This class ultimately represents a directed graph.
/// Nodes are of type [ProdLineNode] and can be accessed via [nodes].
/// Edges are of type [DirectedEdge] and can be accessed via [edges].
/// An edge represents a flow of items from one node to another.
/// For every item flow between 2 nodes, there may only be one edge per item.
///
/// There are certain in game production lines that require a loop. Eg.
/// Producing nutrients via bioflux and using those nutrients to produce bioflux.
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

  /* --------------- Constructors --------------- */
  PlanetBaseGraph._root({
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

  /* ------- Node and Edge Operations ------- */
  /// Full list of all nodes currently in graph
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
  ItemIo? get inputRatios => _inputRatios;
  @override
  ItemIo? get outputRatios => _outputRatios;

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
    ItemIo inputConstraints = const {},
    ItemIo outputConstraints = const {},
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
              producerNode = ProdLineNode(
                parentGraph: this,
                nodeType: NodeType.producer,
                line: IoLine(
                  name: unfulfilledInput.name,
                  netOutputs: {unfulfilledInput},
                ),
              );

              producerNodes[unfulfilledInput] = producerNode;

              apply(GraphEvent.newNode(this, producerNode));
            }
            nodesToUpdate.add(producerNode);

            var newEdge = DirectedEdge(
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
              disposalNode = ProdLineNode(
                parentGraph: this,
                nodeType: NodeType.disposal,
                line: IoLine(
                  name: unfulfilledOutput.name,
                  netInputs: {unfulfilledOutput},
                ),
              );

              disposalNodes[unfulfilledOutput] = disposalNode;

              apply(GraphEvent.newNode(this, disposalNode));
            }
            nodesToUpdate.add(disposalNode);

            var newEdge = DirectedEdge(
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

      ItemIo finalInput = {};
      ItemIo finalOutput = {};
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
    ItemIo inputConstraints, outputConstraints;
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
  final ItemIo inputConstraints;
  final ItemIo outputConstraints;

  _IOConstraints({ItemIo? inputConstraints, ItemIo? outputConstraints})
    : inputConstraints = inputConstraints ?? {},
      outputConstraints = outputConstraints ?? {};
}

// TODO - Move to production_line.dart
bool _compareItemIo(ItemIo io1, ItemIo io2) =>
    io1 == io2 ||
    (io1.length == io2.length &&
        io1.entries.every((entry) {
          var io2Value = io2[entry.key];

          return io2Value != null &&
              (io2Value == entry.value ||
                  (entry.value - io2Value).abs() < 0.001);
        }));
