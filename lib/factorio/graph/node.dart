part of '../graph.dart';

class ProdLineNode with Mutateable<NodeEvent> implements ProductionLine {
  static const double defaultWidth = 100,
      defaultHeight = 100,
      defaultOffset = 50;

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

  // Constructors
  ProdLineNode._addToGraph({
    required this.parentGraph,
    required NodeType type,
    required ProductionLine line,
    Offset topLeft = Offset.zero,
    Offset bottomRight = Offset.zero,
  }) : _nodeType = type,
       _line = line,
       _topLeft = topLeft,
       _bottomRight = bottomRight,
       _active = true {
    if (!_verifyNodeTypeAndLine(type, line)) {
      throw FactorioException(
        'Nodetype $type is incompatible with production line $line',
      );
    }

    parentGraph._addNewNodeData(this);
  }

  // Accessor getters, setters and methods for production line
  @override
  Set<ItemData> get allOutputs => _line.allOutputs;
  @override
  Set<ItemData> get allInputs => _line.allInputs;
  @override
  bool get immutableIo => _line.immutableIo;
  @override
  ItemIo? get totalIoPerSecond => _line.totalIoPerSecond;
  @override
  ItemIo? get requirements => _line.requirements;
  @override
  String get type => _line.type;

  @override
  void update(ItemIo newRequirements) => _line.update(newRequirements);

  @override
  void clearRequirements() => _line.clearRequirements();

  ProdLineNode.addToGraph({
    required this.parentGraph,
    required NodeType type,
    required ProductionLine line,
    Offset topLeft = Offset.zero,
    Offset bottomRight = Offset.zero,
  }) : _topLeft = topLeft,
       _bottomRight = bottomRight,
       _nodeType = type,
       _line = line,
       _active = false {
    // TODO - fix up
    if (!_verifyNodeTypeAndLine(type, line)) {
      throw FactorioException(
        'Nodetype $type is incompatible with production line $line',
      );
    }
    parentGraph._addNewNodeData(this);
  }

  void removeFromGraph({bool updateIo = true}) {
    parentGraph._removeNodeData(this, updateIo);
  }

  void updateSelfAndDescendants(ItemIo newRequirements) {
    parentGraph.updateNodesAndDescendants({this: newRequirements});
  }

  void updateSelfOnly(ItemIo newRequirements) {
    _line.update(newRequirements);
  }

  void updatePosition(Offset newTopLeft, Offset newBottomRight) {
    _topLeft = newTopLeft;
    _bottomRight = newBottomRight;

    for (var edge in parentOf) {
      edge._updateParentPosition();
    }
    for (var edge in childOf) {
      edge._updateChildPosition();
    }
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

  ItemIo _determineRequirementsFromParents() {
    ItemIo requirements = {};
    for (var edge in childOf) {
      double itemAmount = edge._amount ?? 0.0;
      itemAmount = edge.flowDirection == ItemFlowDirection.childToParent
          ? itemAmount
          : -itemAmount;

      requirements.update(
        edge.item,
        (existingAmount) => existingAmount + itemAmount,
        ifAbsent: () => itemAmount,
      );
    }

    return requirements;
  }

  @override
  String toString() => _line.toString();

  @override
  void apply(NodeEvent event) {
    _apply(event, true);
  }

  @override
  void redo(NodeEvent event) {
    _apply(event, false);
  }

  @override
  void rollback(NodeEvent event) {
    _apply(event.reversed, false);
  }

  void _apply(NodeEvent event, bool saveEvent) {
    parentGraph._eventHistory.checkIfMutationPermitted();

    for (var mutationEvent in event.mutations) {
      switch (mutationEvent) {
        case NodeEventType.newPosition:
          _topLeft = event.newTopLeft!;
          _bottomRight = event.newBottomRight!;

        case NodeEventType.requirementsUpdate:
          if (event.newRequirements == null) {
            clearRequirements();
          } else {
            update(event.newRequirements!);
          }

        case NodeEventType.newNodeType:
          _nodeType = event.newNodeType!;

        case NodeEventType.newProductionLine:
          _line = event.newProductionLine!;

        case NodeEventType.parentOfUpdate:
          for (var removed in event.removedParentOf) {
            _parentOf.remove(removed);
          }
          _parentOf.addAll(event.newParentOf);

        case NodeEventType.childrenOfUpdate:
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

    if (saveEvent) {
      parentGraph._eventHistory.addNodeEvent(event);
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
