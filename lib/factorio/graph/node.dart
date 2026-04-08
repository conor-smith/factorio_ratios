part of '../graph.dart';

class ProdLineNode with Mutateable<NodeEvent> {
  static const double defaultWidth = 100,
      defaultHeight = 100,
      defaultOffset = 50,
      connectionOffset = 8;

  // Fields used to determine nodes position in tree
  final BaseGraph parentGraph;
  bool _active;

  // Node type determines how parent graph's state is affected by this node
  NodeType _nodeType;
  NodeType get nodeType => _nodeType;

  // Node is mostly a wrapper for production line
  ProductionLine _line;

  // Fields and getters used to determine nodes position in graph
  Offset _topLeft;
  Offset _bottomRight;

  Offset get topLeft => _topLeft;
  Offset get bottomRight => _bottomRight;

  double get width => (bottomRight.dx - topLeft.dx);
  double get height => (bottomRight.dy - topLeft.dy);

  // Find related edges. This data is managed by the parent graph
  final List<DirectedEdge> _parentOf = [];
  final List<DirectedEdge> _childOf = [];

  late final List<DirectedEdge> parentOf = UnmodifiableListView(_parentOf);
  late final List<DirectedEdge> childOf = UnmodifiableListView(_childOf);

  List<DirectedEdge> get allRelationships =>
      List.unmodifiable([..._parentOf, ..._childOf]);

  // Accessor getters, setters and methods for production line
  Set<ItemData> get allOutputs => _line.allOutputs;
  Set<ItemData> get allInputs => _line.allInputs;
  bool get immutableIo => _line.immutableIo;
  ItemIo? get totalIoPerSecond => _line.totalIoPerSecond;
  ItemIo? get requirements => _line.requirements;
  String get type => _line.type;

  // Constructors
  ProdLineNode.addToGraph({
    required this.parentGraph,
    required NodeType type,
    required ProductionLine line,
    Offset topLeft = Offset.zero,
    Offset bottomRight = Offset.zero,
  }) : _nodeType = type,
       _line = line,
       _topLeft = topLeft,
       _bottomRight = bottomRight,
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

  void removeFromGraph() {
    parentGraph.apply(GraphEvent.removeNode(parentGraph, this));
    for (var edge in [...parentOf, ...childOf]) {
      edge.removeFromGraph();
    }
    apply(NodeEvent.removeFromGraph(this));
  }

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

  @override
  String toString() => _line.toString();

  @override
  void apply(NodeEvent event) {
    _apply(event);

    parentGraph._eventHistory.addNodeEvent(event);
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
    parentGraph._eventHistory.checkIfMutationPermitted();

    for (var mutationEvent in event.mutations) {
      switch (mutationEvent) {
        case NodeEventType.newPosition:
          _topLeft = event.newTopLeft!;
          _bottomRight = event.newBottomRight!;

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
          for (var removed in event.removedParentOf) {
            _parentOf.remove(removed);
          }
          _parentOf.addAll(event.newParentOf);

        case NodeEventType.childOfUpdate:
          for (var removed in event.removedChildOf) {
            _childOf.remove(removed);
          }
          _childOf.addAll(event.newChildOf);

        case NodeEventType.addedToGraph:
          _active = true;

        case NodeEventType.removedFromGraph:
          _active = false;
      }
    }
  }

  void updatePosition(Offset newTopLeft, Offset newBottomRight) {
    apply(NodeEvent.updatePosition(this, newTopLeft, newBottomRight));

    for (var edge in parentOf) {
      edge.updateParentPosition();
    }
    for (var edge in childOf) {
      edge.updateChildPosition();
    }
  }

  static int topMostNode(ProdLineNode node1, ProdLineNode node2) =>
      -node1.topLeft.dy.compareTo(node2.topLeft.dy);
  static int leftMostNode(ProdLineNode node1, ProdLineNode node2) =>
      -node1.topLeft.dx.compareTo(node2.topLeft.dx);
  static int bottomMostNode(ProdLineNode node1, ProdLineNode node2) =>
      node1.bottomRight.dy.compareTo(node2.bottomRight.dy);
  static int rightMostNode(ProdLineNode node1, ProdLineNode node2) =>
      node1.bottomRight.dx.compareTo(node2.bottomRight.dx);
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
