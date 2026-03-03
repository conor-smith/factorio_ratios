part of '../graph.dart';

enum NodeType {
  consumer(allowsInput: true, allowsOutput: false),
  producer(allowsInput: false, allowsOutput: true),
  input(allowsInput: false, allowsOutput: true),
  output(allowsInput: true, allowsOutput: false),
  productionLine(allowsInput: true, allowsOutput: true);

  final bool allowsInput;
  final bool allowsOutput;

  const NodeType({required this.allowsInput, required this.allowsOutput});

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
    parentGraph._nodes.add(this);

    parentGraph._parents[this] = {};
    parentGraph._children[this] = {};
  }

  void removeFromGraph() {
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
  Map<ItemData, double> get totalIoPerSecond => _line.totalIoPerSecond;
  @override
  Map<ItemData, double> get requirements => _line.requirements;
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
    required ItemFlowDirection flowDirection,
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
