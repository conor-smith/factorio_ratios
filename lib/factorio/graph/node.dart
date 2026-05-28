part of 'graph.dart';

/// Represents a single node in the graph.
///
/// Every node contains a [ProductionLine] object in the [productionLine] field.
/// This production line can be swapped as the user sees fit.
/// The exact kinds of production lines permitted is limited by the [nodeType] field,
/// which also specifies the nodes allowed relationships and other behaviour.
///
/// To represent actual IO, the node caches the [ProductionLineIo] produces by [productionLine]
/// in the [ioData] field.
/// As a [ProductionLine] already has a known set of inputs and outputs before
/// [ProductionLine.calculate] is called, we do not need to determine IO to
/// build the graph. As such, [ioData] and the [DirectedEdge.amount] field
/// of all child edges will be null until [calculateAndCache] is called
class ProdLineNode with Stateful<NodeEvent> {
  static const double defaultWidth = 100,
      defaultHeight = 100,
      defaultOffset = 50,
      minSideLength = 20,
      connectionOffset = 8;

  final PlanetBaseGraph parentGraph;
  final NodeType nodeType;

  _EventHistory get _history => parentGraph._history;
  ProductionLine _productionLine;

  ItemAmounts? _internalInputConstraints, _internalOutputConstraints;

  NodeGeometry _geometry;

  List<DirectedEdge> _children;
  List<DirectedEdge> _parents;

  ProductionLineIo? _ioData;

  bool _hasCachedData = false;
  Map<InGameItem, List<DirectedEdge>>? _cachedInputEdges;
  Map<InGameItem, List<DirectedEdge>>? _cachedOutputEdges;

  /* ---------------- Accessors ---------------- */
  List<DirectedEdge> get children => _children;
  List<DirectedEdge> get parents => _parents;

  NodeGeometry get geometry => _geometry;
  Rect get rect => _geometry.minimalRect;

  // TODO - Should this be a local field?
  bool get selected => parentGraph.globalData._selectedNodes.contains(this);

  @override
  String toString() => _productionLine.toString();

  /* --------------- Constructors --------------- */
  ProdLineNode.addToGraph({
    required this.parentGraph,
    required this.nodeType,
    required ProductionLine line,
  }) : _productionLine = line,
       _parents = const [],
       _children = const [],
       _geometry = NodeGeometry.uninitialised {
    if (!_verifyNodeTypeAndLine(nodeType, line)) {
      throw FactorioException(
        'Nodetype $nodeType is incompatible with production line $line',
      );
    }

    // TODO - verify node is compatible with graph
    parentGraph.apply(GraphEvent.newNode(parentGraph, this));
  }

  /* ----------------- Cache ----------------- */
  void _buildEdgeCache() {
    if (!_hasCachedData) {
      _cachedInputEdges = {};
      _cachedOutputEdges = {};

      for (var childEdge in children) {
        if (childEdge.flowDirection == ItemFlowDirection.childToParent) {
          _cachedInputEdges!.update(
            childEdge.item,
            (edges) => edges..add(childEdge),
            ifAbsent: () => [childEdge],
          );
        } else {
          _cachedOutputEdges!.update(
            childEdge.item,
            (edges) => edges..add(childEdge),
            ifAbsent: () => [childEdge],
          );
        }
      }

      for (var parentEdge in parents) {
        if (parentEdge.flowDirection == ItemFlowDirection.childToParent) {
          _cachedOutputEdges!.update(
            parentEdge.item,
            (edges) => edges..add(parentEdge),
            ifAbsent: () => [parentEdge],
          );
        } else {
          _cachedInputEdges!.update(
            parentEdge.item,
            (edges) => edges..add(parentEdge),
            ifAbsent: () => [parentEdge],
          );
        }
      }

      _hasCachedData = true;
    }
  }

  void _clearEdgeCache() {
    if (_hasCachedData) {
      _cachedInputEdges = null;
      _cachedOutputEdges = null;
      _hasCachedData = false;
    }
  }

  /* ------------ Production Line ------------ */
  ProductionLine get productionLine => _productionLine;

  Set<InGameItem> get inputItems => _productionLine.inputItems;
  Set<InGameItem> get outputItems => _productionLine.outputItems;
  ItemAmounts? get inputRatios => _productionLine.inputRatios;
  ItemAmounts? get outputRatios => _productionLine.outputRatios;
  String get productionLineType => _productionLine.type;
  String get productionLineName => _productionLine.name;

  /// Returns true if [internalInputConstraints] and [internalOutputConstraints]
  /// are set
  bool get hasInternalConstraints => _internalInputConstraints != null;

  /// Can only be populated via [setInternalConstraints] if this node has no children
  ItemAmounts? get internalInputConstraints => _internalInputConstraints;

  /// Can only be populated via [setInternalConstraints] if this node has no children
  ItemAmounts? get internalOutputConstraints => _internalOutputConstraints;

  ProductionLineIo? get ioData => _ioData;

  /// Apply constraints to [productionLine] and cache output to [ioData].
  /// DOES NOT affect [internalInputConstraints] or [internalOutputConstraints].
  /// Constraints are saved in the [ioData] field itself
  void calculateAndCache({
    ItemAmounts inputConstraints = const {},
    ItemAmounts outputConstraints = const {},
  }) {
    _history.mutate(() {
      var newIo = _productionLine.calculate(
        inputConstraints: inputConstraints,
        outputConstraints: outputConstraints,
      );

      apply(NodeEvent.newIo(this, newIo));
    });
  }

  /// Sets [internalInputConstraints] and [internalOutputConstraints] but does
  /// not actually actually call [calculateAndCache]. That must be done independently
  void setInternalConstraints({
    ItemAmounts inputConstraints = const {},
    ItemAmounts outputConstraints = const {},
  }) {
    _productionLine.verifyConstraintsAndIo(inputConstraints, outputConstraints);

    if (_parents.isNotEmpty) {
      throw GraphException(
        'Cannot set internal constraints on node $this, as it has parents',
      );
    }

    _history.mutate(
      () => apply(
        NodeEvent.newInternalConstraints(
          this,
          inputConstraints: inputConstraints,
          outputConstraints: outputConstraints,
        ),
      ),
    );
  }

  /* ------------- Stateful methods ------------- */
  @override
  void apply(NodeEvent event) {
    _apply(event);

    _history.addNodeEvent(event);

    if (event.mutations.contains(NodeEventType.parentsUpdate) ||
        event.mutations.contains(NodeEventType.childrenUpdate)) {
      _clearEdgeCache();
    }

    if (event.mutations.contains(NodeEventType.newProductionLine)) {
      parentGraph._clearNodeCache();
    }

    for (var mutation in event.mutations) {
      switch (mutation) {
        case NodeEventType.newProductionLine:
          // TODO - Can this be more efficient?
          parentGraph._clearNodeCache();

        case NodeEventType.childrenUpdate:
        case NodeEventType.parentsUpdate:
          _clearEdgeCache();

        default:
          break;
      }
    }
  }

  @override
  void redo(NodeEvent event) {
    _apply(event);

    _clearEdgeCache();
    parentGraph._clearNodeCache();
  }

  @override
  void rollback(NodeEvent event) {
    _apply(event.reversed);

    _clearEdgeCache();
    parentGraph._clearNodeCache();
  }

  void _apply(NodeEvent event) {
    _history.checkIfMutationPermitted();

    for (var mutationEvent in event.mutations) {
      switch (mutationEvent) {
        case NodeEventType.updateGeometry:
          _geometry = event.newGeometry!;

        case NodeEventType.updateIo:
          _ioData = event.newIo;

        case NodeEventType.updateConstraints:
          _internalInputConstraints = event.newInputConstraints;
          _internalOutputConstraints = event.newOutputConstraints;

        case NodeEventType.newProductionLine:
          _productionLine = event.newProductionLine!;

        case NodeEventType.childrenUpdate:
          _children = event.newChildren!;

        case NodeEventType.parentsUpdate:
          _parents = event.newParents!;

        case NodeEventType.tempGeometry:
        case NodeEventType.selectToggle:
          throw const MutationException('Cannot apply node temp event');
      }
    }
  }

  /* ------------- All other logic ------------- */
  void removeFromGraph() {
    parentGraph.apply(GraphEvent.removeNode(parentGraph, this));
    parentGraph.apply(
      GraphEvent.removeMultipleEdges(parentGraph, [...parents, ...children]),
    );

    for (var childEdge in children) {
      childEdge._removeFromChildOnly();
    }
    for (var parentEdge in parents) {
      parentEdge._removeFromParentOnly();
    }

    apply(NodeEvent.clearParentsAndChildren(this));
  }

  List<DirectedEdge> findRelationships(ProdLineNode other) => children
      .where((childEdge) => childEdge.child == other)
      .followedBy(_parents.where((parentEdge) => parentEdge.parent == other))
      .toList();

  bool _verifyNodeTypeAndLine(NodeType nodeType, ProductionLine line) =>
      switch (nodeType) {
        NodeType.consumer || NodeType.disposal || NodeType.output =>
          line.isImmutable &&
              line.inputItems.isNotEmpty &&
              line.outputItems.isEmpty,
        NodeType.producer || NodeType.input =>
          line.isImmutable &&
              line.inputItems.isEmpty &&
              line.outputItems.isNotEmpty,
        NodeType.productionLine => true,
      };
}

/// Specifies node behaviour
enum NodeType {
  /// Only consumes with no output. Consumer nodes are special as they cannot
  /// have parents and are permitted to set their own constraints via
  /// [ProdLineNode.internalInputConstraints] and [ProdLineNode.internalOutputConstraints]
  consumer(allowsInput: true, allowsOutput: false, isIo: false),

  /// Similar to [consumer], but only exists to represent disposal of excess items
  /// being produced by other nodes. Can only have parents, not children
  disposal(allowsInput: true, allowsOutput: false, isIo: false),

  /// Can only have outputs but no inputs
  producer(allowsInput: false, allowsOutput: true, isIo: false),

  /// Represents an input to a graph
  input(allowsInput: false, allowsOutput: true, isIo: true),

  /// Represents an output to a graph
  output(allowsInput: true, allowsOutput: false, isIo: true),

  /// Represents a production line. Cannot set it's own constraints
  productionLine(allowsInput: true, allowsOutput: true, isIo: false);

  final bool allowsInput;
  final bool allowsOutput;
  final bool isIo;

  const NodeType({
    required this.allowsInput,
    required this.allowsOutput,
    required this.isIo,
  });
}
