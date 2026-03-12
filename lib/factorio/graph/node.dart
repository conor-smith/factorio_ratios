part of '../graph.dart';

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

class ProdLineNode implements ProductionLine {
  static const double defaultWidth = 100,
      defaultHeight = 100,
      defaultOffset = 50;

  final BaseGraph parentGraph;

  NodeType _type;
  ProductionLine _line;

  Offset _topLeft;
  Offset _bottomRight;

  late final Set<DirectedEdge> parents = UnmodifiableSetView(
    parentGraph._parents[this]!,
  );
  late final Set<DirectedEdge> children = UnmodifiableSetView(
    parentGraph._children[this]!,
  );

  Function? _callbackOnChange;
  Function? _callbackOnDelete;

  NodeType get nodeType => _type;

  Offset get topLeft => _topLeft;
  Offset get bottomRight => _bottomRight;

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

  // TODO - better error message
  @override
  void update(ItemIo newRequirements) =>
      throw const FactorioException('Do not call this method');

  // TODO - better error message
  @override
  void reset() => throw const FactorioException('Do not call this method');

  ProdLineNode.addToGraph({
    required this.parentGraph,
    required NodeType type,
    required ProductionLine line,
    Offset topLeft = const Offset(0, 0),
    Offset bottomRight = const Offset(defaultWidth, defaultHeight),
  }) : _bottomRight = bottomRight,
       _topLeft = topLeft,
       _type = type,
       _line = line {
    if (!_verifyNodeTypeAndLine(type, line)) {
      throw FactorioException(
        'Nodetype $type is incompatible with production line $line',
      );
    }

    if (type.isIo && !_verifyAndAddIo(type, line)) {
      throw const FactorioException('Could not add IO');
    }

    parentGraph._nodes.add(this);

    parentGraph._parents[this] = {};
    parentGraph._children[this] = {};

    _callbackOnDelete = () => parentGraph._callBackOnChange!(
      const [],
      const [],
      [this],
      [...parents, ...children],
    );
  }

  void removeFromGraph({bool updateListener = false}) {
    if (_type.isIo) {
      _removeIo(_type, _line);
    }

    parentGraph._nodes.remove(this);

    for (var edge in [...parents, ...children]) {
      edge.removeFromGraph();
    }

    parentGraph._parents.remove(this);
    parentGraph._children.remove(this);

    if (updateListener) {
      _callbackOnDelete!();
    }
  }

  void updateSelfAndDescendants(
    ItemIo newRequirements, {
    bool updateListeners = false,
  }) {
    parentGraph.updateNodesAndDescendants({
      this: newRequirements,
    }, updateListeners: updateListeners);
  }

  void updateSelfOnly(ItemIo newRequirements, {bool updateListeners = false}) {
    _line.update(newRequirements);

    if (updateListeners) {
      _callbackOnChange!();
    }
  }

  void updateOffsets(
    Offset newTopLeft,
    Offset newBottomRight, {
    bool updateListeners = false,
  }) {
    _topLeft = newTopLeft;
    _bottomRight = newBottomRight;

    for (var parent in parents) {
      parent._childUpdate(updateListeners);
    }
    for (var child in children) {
      child._parentUpdate(updateListeners);
    }

    if (updateListeners) {
      _callbackOnChange!();
    }
  }

  void setChangeCallback(Function changeCallback) {
    _callbackOnChange = changeCallback;
  }

  void addDeletionCallback(Function deletionCallback) {
    _callbackOnDelete = deletionCallback;
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

  bool _verifyAndAddIo(NodeType type, ProductionLine line) {
    bool canAddIo = false;
    // Cannot add output/input if already exists
    if (type == NodeType.output) {
      canAddIo = line.allInputs.every(
        (lineInput) => !parentGraph._allOutputs.contains(lineInput),
      );

      if (canAddIo) {
        parentGraph._allOutputs.addAll(line.allInputs);
      }
    } else if (type == NodeType.input) {
      canAddIo = line.allOutputs.every(
        (lineOutput) => !parentGraph._allInputs.contains(lineOutput),
      );

      if (canAddIo) {
        parentGraph._allInputs.addAll(line.allOutputs);
      }
    }

    return canAddIo;
  }

  void _removeIo(NodeType type, ProductionLine line) {
    if (type == NodeType.output) {
      parentGraph._allOutputs.removeAll(line.allInputs);
    } else if (type == NodeType.input) {
      parentGraph._allInputs.removeAll(line.allOutputs);
    }
  }

  @override
  String toString() => _line.toString();
}
