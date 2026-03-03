part of '../graph.dart';

enum NodeType {
  consumer(allowsInput: true, allowsOutput: false, isIo: false),
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

  bool canChangeTo(NodeType changeTo) => switch (this) {
    consumer => const {output, productionLine}.contains(changeTo),
    producer => const {input, productionLine}.contains(changeTo),
    input => changeTo == producer,
    output => changeTo == consumer,
    productionLine => const {producer, consumer}.contains(changeTo),
  };
}

enum ItemFlowDirection { parentToChild, childToParent }

enum EdgeType {
  requestItems(ItemFlowDirection.childToParent),
  acceptExcess(ItemFlowDirection.childToParent);

  final ItemFlowDirection flowDirection;

  const EdgeType(this.flowDirection);
}

class ProdLineNode implements ProductionLine {
  // Implementing ProductionLine is arguably unnecessary
  // Primarily for convenenience
  final BaseGraph parentGraph;

  NodeType _type;
  ProductionLine _line;

  late final Set<DirectedEdge> parents = UnmodifiableSetView(
    parentGraph._parents[this]!,
  );
  late final Set<DirectedEdge> children = UnmodifiableSetView(
    parentGraph._children[this]!,
  );

  ProdLineNode.addToGraph({
    required this.parentGraph,
    required NodeType type,
    required ProductionLine line,
  }) : _type = type,
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
  }

  void removeFromGraph() {
    if (_type.isIo) {
      _removeIo(_type, _line);
    }

    parentGraph._nodes.remove(this);

    for (var edge in [...parents, ...children]) {
      edge.removeFromGraph();
    }

    parentGraph._parents.remove(this);
    parentGraph._children.remove(this);
  }

  NodeType get type => _type;
  ProductionLine get productionLine => _line;

  @override
  Set<ItemData> get allOutputs => _line.allOutputs;
  @override
  Set<ItemData> get allInputs => _line.allInputs;
  @override
  bool get immutableIo => _line.immutableIo;
  @override
  Map<ItemData, double>? get totalIoPerSecond => _line.totalIoPerSecond;
  @override
  Map<ItemData, double>? get requirements => _line.requirements;
  @override
  void update(Map<ItemData, double> newRequirements) =>
      _line.update(newRequirements);

  @override
  void reset() {
    _line.reset();

    for (var child in children) {
      child._amount = null;
    }
  }

  void updateSelfAndChildren(Map<ItemData, double> newRequirements) {
    parentGraph._updateNodesAndChildren({this: newRequirements});
  }

  bool _verifyNodeTypeAndLine(
    NodeType nodeType,
    ProductionLine line,
  ) => switch (nodeType) {
    NodeType.consumer || NodeType.output =>
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
}

class DirectedEdge {
  final BaseGraph parentGraph;
  final ItemData item;
  final ProdLineNode parent;
  final ProdLineNode child;
  double? _amount;
  EdgeType _edgeType;

  double? get amount => _amount;
  ItemFlowDirection get flowDirection => _edgeType.flowDirection;
  EdgeType get edgeType => _edgeType;

  DirectedEdge.addToGraph({
    required this.parentGraph,
    required this.item,
    required this.parent,
    required this.child,
    double? initialAmount,
    required EdgeType edgeType,
  }) : _amount = initialAmount,
       _edgeType = edgeType {
    // Confirm both parent and child are valid
    if (parentGraph != parent.parentGraph || parentGraph != child.parentGraph) {
      throw const FactorioException(
        'Cannot connect two nodes from different graphs',
      );
    }

    // Ensure no loops are created
    Set<ProdLineNode> visitedNodes = {};
    List<ProdLineNode> nodesToVisit = List.from(
      child.children.map((childEdge) => childEdge.child),
    );
    while (nodesToVisit.isNotEmpty) {
      ProdLineNode node = nodesToVisit.removeLast();
      if (node == parent) {
        throw const FactorioException('Cannot create loop');
      } else if (!visitedNodes.contains(node)) {
        visitedNodes.add(node);
        nodesToVisit.addAll(node.children.map((childEdge) => childEdge.child));
      }
    }

    parentGraph._edges.add(this);

    parentGraph._parents[child]!.add(this);
    parentGraph._children[parent]!.add(this);
  }

  void removeFromGraph() {
    parentGraph._edges.remove(this);

    parentGraph._parents[child]!.remove(this);
    parentGraph._children[parent]!.remove(this);
  }
}
