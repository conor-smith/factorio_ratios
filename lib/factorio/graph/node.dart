part of '../graph.dart';

class ProdLineNode extends ChangeNotifier implements ProductionLine {
  static const double defaultWidth = 100,
      defaultHeight = 100,
      defaultOffset = 50;

  final BaseGraph parentGraph;

  NodeType _type;
  ProductionLine _line;

  Offset _topLeft;
  Offset _bottomRight;
  bool _isBeingDragged;

  late final Set<DirectedEdge> parentOf = UnmodifiableSetView(
    parentGraph._parentOfMap[this]!,
  );
  late final Set<DirectedEdge> childOf = UnmodifiableSetView(
    parentGraph._childOfMap[this]!,
  );

  NodeType get nodeType => _type;

  Offset get topLeft => _topLeft;
  Offset get bottomRight => _bottomRight;
  bool get isBeingDragged => _isBeingDragged;

  double get width => (bottomRight.dx - topLeft.dx);
  double get height => (bottomRight.dy - topLeft.dy);

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
       _isBeingDragged = false,
       _type = type,
       _line = line {
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

  void startDragging() {
    parentGraph._setDraggableNode(this);
  }

  void endDragging() {
    parentGraph._clearDraggableNode(this);
  }

  void updatePosition(
    Offset newTopLeft,
    Offset newBottomRight, {
    bool updateListeners = true,
  }) {
    _topLeft = newTopLeft;
    _bottomRight = newBottomRight;

    for (var edge in parentOf) {
      edge._updateParentPosition(updateListeners: updateListeners);
    }
    for (var edge in childOf) {
      edge._updateChildPosition(updateListeners: updateListeners);
    }

    if (updateListeners) {
      notifyListeners();
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
