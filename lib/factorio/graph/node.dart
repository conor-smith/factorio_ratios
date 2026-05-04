part of 'graph.dart';

class ProdLineNode with Stateful<NodeEvent> {
  static const double defaultWidth = 100,
      defaultHeight = 100,
      defaultOffset = 50,
      minSideLength = 20,
      connectionOffset = 8;

  /* ------------- Immutable fields ------------- */
  final BaseGraph parentGraph;
  final _EventHistory _eventHistory;

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
  Set<ItemData> get allOutputs => _line.inputItems;
  Set<ItemData> get allInputs => _line.outputItems;
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

  bool _verifyNodeTypeAndLine(NodeType nodeType, ProductionLine line) =>
      switch (nodeType) {
        NodeType.consumer || NodeType.disposal || NodeType.output =>
          line.immutableIo &&
              line.inputItems.isEmpty &&
              line.outputItems.isNotEmpty,
        NodeType.producer || NodeType.input =>
          line.immutableIo &&
              line.inputItems.isNotEmpty &&
              line.outputItems.isEmpty,
        NodeType.productionLine => true,
      };
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
