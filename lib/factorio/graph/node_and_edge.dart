part of '../graph.dart';

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
    required Map<ItemData, double>? initialRequirements,
    required ProductionLine line,
  }) : _type = type,
       _line = line {
    parentGraph._nodes.add(this);

    parentGraph._parents[this] = {};
    parentGraph._children[this] = {};
  }

  void removeFromGraph() {
    parentGraph._nodes.remove(this);

    for (var childEdge in parentGraph._children[this]!) {
      var childNode = childEdge.child;
      childEdge.removeFromGraph();

      if (parentGraph._parents[childNode]!.isEmpty) {
        childNode.removeFromGraph();
      }
    }
    for (var parentEdge in parentGraph._parents[this]!) {
      parentEdge.removeFromGraph();
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
  void update(Map<ItemData, double> requirements) => _line.update(requirements);
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
  ItemFlowDirection _flowDirection;
  EdgeType _edgeType;

  double? get amount => _amount;
  ItemFlowDirection get flowDirection => _flowDirection;
  EdgeType get edgeType => _edgeType;

  DirectedEdge.addToGraph({
    required this.parentGraph,
    required this.item,
    required this.parent,
    required this.child,
    double initialAmount = 0,
    required ItemFlowDirection flowDirection,
    required EdgeType edgeType,
  }) : _amount = initialAmount,
       _flowDirection = flowDirection,
       _edgeType = edgeType {
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
