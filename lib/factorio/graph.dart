import 'dart:collection';
import 'dart:ui';

import 'package:factorio_ratios/factorio/factorio.dart';
import 'package:factorio_ratios/factorio/graph/geometry.dart';
import 'package:factorio_ratios/factorio/graph/state.dart';
import 'package:factorio_ratios/factorio/models.dart';
import 'package:factorio_ratios/factorio/production_line.dart';

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
  final EventHistory _eventHistory;

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

  GeometryOperation? _geometryOperation;

  /* --------------- Constructors --------------- */
  BaseGraph.root({this.surface})
    : _parentNode = null,
      _eventHistory = EventHistory(_maxSavedEvents),
      _geometry = GraphGeometry.uninitialised;

  BaseGraph._addToTree({this.surface, required EventHistory eventHistory})
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
          allInputs.removeAll(event.removedInputs);
          allInputs.addAll(event.newInputs);

        case GraphEventType.updateOutput:
          allOutputs.removeAll(event.removedOutputs);
          allOutputs.addAll(event.newOutputs);
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

class ProdLineNode with Stateful<NodeEvent> {
  static const double defaultWidth = 100,
      defaultHeight = 100,
      defaultOffset = 50,
      minSideLength = 20,
      connectionOffset = 8;

  /* ------------- Immutable fields ------------- */
  final BaseGraph parentGraph;
  final EventHistory _eventHistory;

  /* -------------- Mutable fields -------------- */
  // Node type determines how parent valid operations and how parent graph is affected
  NodeType _nodeType;
  // True if part of a graph. False otherwise
  bool _active;

  ProductionLine _line;

  NodeGeometry _geometry;

  // Edges that this node is a parent of
  final Set<DirectedEdge> _parentOf = {};
  // Edges that this node is a child of
  final Set<DirectedEdge> _childOf = {};

  /* ---------------- Accessors ---------------- */
  late final Set<DirectedEdge> parentOf = UnmodifiableSetView(_parentOf);
  late final Set<DirectedEdge> childOf = UnmodifiableSetView(_childOf);

  NodeType get nodeType => _nodeType;

  NodeGeometry get geometry => _geometry;
  Rect get rect => _geometry.minimalRect;

  // Accessors for production line
  Set<ItemData> get allOutputs => _line.allOutputs;
  Set<ItemData> get allInputs => _line.allInputs;
  bool get immutableIo => _line.immutableIo;
  ItemIo? get totalIoPerSecond => _line.totalIoPerSecond;
  ItemIo? get requirements => _line.requirements;
  String get type => _line.type;

  ProductionLine get line => _line;

  @override
  String toString() => _line.toString();

  /* --------------- Constructors --------------- */
  ProdLineNode.addToGraph({
    required this.parentGraph,
    required NodeType type,
    required ProductionLine line,
  }) : _eventHistory = parentGraph._eventHistory,
       _nodeType = type,
       _line = line,
       _geometry = NodeGeometry.uninitialised,
       _active = false {
    if (!_verifyNodeTypeAndLine(type, line)) {
      throw FactorioException(
        'Nodetype $type is incompatible with production line $line',
      );
    }

    parentGraph.apply(GraphEvent.newNode(parentGraph, this));
    apply(NodeEvent.addToGraph(this));

    if (line is BaseGraph) {
      line._parentNode = this;
    }
  }

  /* ------------- Stateful methods ------------- */
  @override
  void apply(NodeEvent event) {
    _apply(event);

    _eventHistory.addNodeEvent(event);
  }

  @override
  void redo(NodeEvent event) {
    _apply(event);
  }

  @override
  void rollback(NodeEvent event) {
    _apply(event.reversed);
  }

  void _apply(NodeEvent event) {
    _eventHistory.checkIfMutationPermitted();

    for (var mutationEvent in event.mutations) {
      switch (mutationEvent) {
        case NodeEventType.updateGeometry:
          _geometry = event.newGeometry!;

        case NodeEventType.newRequirements:
          if (event.newRequirements == null) {
            _line.clearRequirements();
          } else {
            _line.update(event.newRequirements!);
          }

        case NodeEventType.newNodeType:
          _nodeType = event.newNodeType!;

        case NodeEventType.newProductionLine:
          _line = event.newProductionLine!;

          if (_line is BaseGraph) {
            (_line as BaseGraph)._parentNode = this;
          }

        case NodeEventType.parentOfUpdate:
          _parentOf.removeAll(event.removedParentOf);
          _parentOf.addAll(event.newParentOf);

        case NodeEventType.childOfUpdate:
          _childOf.removeAll(event.removedChildOf);
          _childOf.addAll(event.newChildOf);

        case NodeEventType.addedToGraph:
          _active = true;

        case NodeEventType.removedFromGraph:
          _active = false;

        case NodeEventType.tempGeometry:
          throw const MutationException(
            'Cannot apply event of type tempGeometry',
          );
      }
    }
  }

  /* ----------- Geometry Operations ----------- */
  void beginDragging() {
    parentGraph.beginMultiNodeDrag([this], const []);
  }

  void beginResize(RectPoint selectedPoint) {
    parentGraph.beginMultiNodeResize([this], this, selectedPoint);
  }

  void drag(Offset offset) {
    parentGraph._throwIfNoGeometricOp();
    parentGraph._geometryOperation!.drag(offset);
  }

  void resize({
    double leftOffset = 0,
    double topOffset = 0,
    double rightOffset = 0,
    double bottomOffset = 0,
  }) {
    parentGraph._throwIfNoGeometricOp();
    parentGraph._geometryOperation!.resizeNodes(
      leftOffset,
      topOffset,
      rightOffset,
      bottomOffset,
    );
  }

  void finishDragOrResize() {}

  /* ------------- All other logic ------------- */
  void removeFromGraph() {
    parentGraph.apply(GraphEvent.removeNode(parentGraph, this));
    for (var edge in [...parentOf, ...childOf]) {
      edge.removeFromGraph();
    }
    apply(NodeEvent.removeFromGraph(this));
  }

  List<DirectedEdge> findRelationships(ProdLineNode other) => parentOf
      .where((childEdge) => childEdge.child == other)
      .followedBy(_childOf.where((parentEdge) => parentEdge.parent == other))
      .toList();

  bool _verifyNodeTypeAndLine(
    NodeType nodeType,
    ProductionLine line,
  ) => switch (nodeType) {
    NodeType.consumer || NodeType.disposal || NodeType.output =>
      line.immutableIo && line.allOutputs.isEmpty && line.allInputs.isNotEmpty,
    NodeType.producer || NodeType.input =>
      line.immutableIo && line.allOutputs.isNotEmpty && line.allInputs.isEmpty,
    NodeType.productionLine => true,
  };
}

class DirectedEdge with Stateful<EdgeEvent> {
  /* ------------- Immutable fields ------------- */
  final BaseGraph parentGraph;
  final EventHistory _eventHistory;

  final ProdLineNode parent;
  final ProdLineNode child;
  final ItemData item;

  final Relationship edgeType;

  /* -------------- Mutable fields -------------- */
  bool _active;

  double? _amount;

  EdgeGeometry _geometry;

  /* ---------------- Accessors ---------------- */
  double? get amount => _amount;
  ItemFlowDirection get flowDirection => edgeType.flowDirection;

  EdgeGeometry get geometry => _geometry;
  LineType get lineType => _geometry.lineType;
  List<Line> get lines => _geometry.lines;

  bool get active => _active;

  /* --------------- Constructors --------------- */
  DirectedEdge.addToGraph({
    required this.parentGraph,
    required this.item,
    required this.parent,
    required this.child,
    double? initialAmount,
    required this.edgeType,
  }) : _eventHistory = parentGraph._eventHistory,
       _amount = initialAmount,
       _geometry = EdgeGeometry.uninitialised,
       _active = false {
    // TODO - fix up
    // Confirm both parent and child are valid
    if (parentGraph != parent.parentGraph || parentGraph != child.parentGraph) {
      throw const FactorioException(
        'Cannot connect two nodes from different graphs',
      );
    } else if (parent.parentOf.contains(this)) {
      throw const FactorioException('Cannot create duplicate edge');
    }

    // Ensure no loops are created
    // TODO - Allow loops
    Set<ProdLineNode> visitedNodes = {};
    List<ProdLineNode> nodesToVisit = child.parentOf
        .map((edge) => edge.child)
        .toList();
    while (nodesToVisit.isNotEmpty) {
      ProdLineNode node = nodesToVisit.removeLast();
      if (node == parent) {
        throw const FactorioException('Cannot create loop');
      } else if (!visitedNodes.contains(node)) {
        visitedNodes.add(node);
        nodesToVisit.addAll(node.parentOf.map((edge) => edge.child));
      }
    }

    parentGraph.apply(GraphEvent.newEdge(parentGraph, this));
    parent.apply(NodeEvent.newChildEdge(parent, this));
    child.apply(NodeEvent.newParentEdge(child, this));
    apply(EdgeEvent.addToGraph(this));
  }

  /* ------------- Stateful methods ------------- */
  @override
  void apply(EdgeEvent event) {
    _apply(event);

    _eventHistory.addEdgeEvent(event);
  }

  @override
  void redo(EdgeEvent event) {
    _apply(event);
  }

  @override
  void rollback(EdgeEvent event) {
    _apply(event.reversed);
  }

  void _apply(EdgeEvent event) {
    _eventHistory.checkIfMutationPermitted();

    for (var mutationEvent in event.mutations) {
      switch (mutationEvent) {
        case EdgeEventType.newAmount:
          _amount = event.newAmount;

        case EdgeEventType.newGeometry:
          _geometry = event.newGeometry!;

        case EdgeEventType.addedToGraph:
          _active = true;

        case EdgeEventType.removedFromGraph:
          _active = false;

        case EdgeEventType.tempGeometry:
          throw const MutationException(
            'Cannot apply event of type tempGeometry',
          );
      }
    }
  }

  /* ------------- All other logic ------------- */
  void removeFromGraph() {
    parentGraph.apply(GraphEvent.removeEdge(parentGraph, this));
    parent.apply(NodeEvent.removeChildEdge(parent, this));
    child.apply(NodeEvent.removeParentEdge(child, this));
    apply(EdgeEvent.removeFromGraph(this));
  }

  void _shortestLineBetweenNodes() {
    apply(EdgeEvent.updateGeometry(this, EdgeGeometry.shortestPath(this)));
  }
}

enum NodeType {
  consumer(allowsInput: true, allowsOutput: false, isIo: false),
  disposal(allowsInput: true, allowsOutput: false, isIo: false),
  producer(allowsInput: false, allowsOutput: true, isIo: false),
  input(allowsInput: false, allowsOutput: true, isIo: true),
  output(allowsInput: true, allowsOutput: false, isIo: true),
  productionLine(allowsInput: true, allowsOutput: true, isIo: false);

  final bool allowsInput;
  final bool allowsOutput;
  final bool isIo;

  const NodeType({
    required this.allowsInput,
    required this.allowsOutput,
    required this.isIo,
  });

  bool canChangeTo(NodeType changeTo) =>
      this == changeTo ||
      switch (this) {
        consumer => const {output, productionLine, disposal}.contains(changeTo),
        disposal => const {output, productionLine, producer}.contains(changeTo),
        producer => const {input, productionLine}.contains(changeTo),
        input => false,
        output => false,
        productionLine => false,
      };
}

// TODO - Add more linetypes
enum LineType { shortestPath }

enum ItemFlowDirection { parentToChild, childToParent }

enum Relationship {
  requestItems(ItemFlowDirection.childToParent),
  acceptExcess(ItemFlowDirection.parentToChild);

  final ItemFlowDirection flowDirection;

  const Relationship(this.flowDirection);
}

class GraphException implements Exception {
  final String message;

  const GraphException(this.message);

  @override
  String toString() => 'GraphException: $message';
}
