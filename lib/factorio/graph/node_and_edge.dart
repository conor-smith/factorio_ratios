part of '../graph.dart';

class ProdLineNode {
  final PlanetaryBase parentGraph;
  NodeType _type;
  ProductionLine _line;
  final Map<ItemData, double> _requirements;

  late final Map<ItemData, double> requirements = UnmodifiableMapView(
    _requirements,
  );

  late final Set<DirectedEdge> parents = UnmodifiableSetView(
    parentGraph._parents[this]!,
  );
  late final Set<DirectedEdge> children = UnmodifiableSetView(
    parentGraph._children[this]!,
  );

  ProdLineNode._addToGraph({
    required this.parentGraph,
    required NodeType type,
    required Map<ItemData, double>? initialRequirements,
    required ProductionLine line,
  }) : _type = type,
       _line = line,
       _requirements = initialRequirements ?? {} {
    parentGraph._nodes.add(this);

    parentGraph._parents[this] = {};
    parentGraph._children[this] = {};
  }

  NodeType get type => _type;
  ProductionLine get productionLine => _line;

  Set<ItemData> get allOutputs => _line.allOutputs;
  Set<ItemData> get allInputs => _line.allInputs;
  Map<ItemData, double> get totalIoPerSecond => _line.totalIoPerSecond;
  void update(Map<ItemData, double> requirements) => _line.update(requirements);

  GraphUpdates updateInternals({NodeType? newType, ProductionLine? newLine}) {
    newType ??= _type;
    newLine ??= _line;

    // Validate update
    if (newType != _type) {
      switch (_type) {
        case NodeType.output:
          if (newType != NodeType.output) {
            throw const FactorioException(
              'Cannot convert output node to other node type',
            );
          }
        case NodeType.resource:
        case NodeType.input:
        case NodeType.productionLine:
          if (newType == NodeType.output) {
            throw const FactorioException(
              'Cannot convert non output node to to output node',
            );
          }
      }
    }

    if (newLine != _line) {
      var requiredOutputs = parents
          .where(
            (edge) => edge.flowDirection == ItemFlowDirection.childToParent,
          )
          .map((edge) => edge.item);

      if (!newLine.allOutputs.containsAll(requiredOutputs)) {
        throw const FactorioException(
          'New production line does not output all required items',
        );
      }
    }

    _line = newLine;
    _type = newType;

    return parentGraph._updateEdgesForNode(this);
  }

  void _removeFromGraph() {
    parentGraph._nodes.remove(this);

    for (var childEdge in parentGraph._children[this]!) {
      var childNode = childEdge.child;
      childEdge._removeFromGraph();

      if (parentGraph._parents[childNode]!.isEmpty) {
        childNode._removeFromGraph();
      }
    }
    for (var parentEdge in parentGraph._parents[this]!) {
      parentEdge._removeFromGraph();
    }
    parentGraph._parents.remove(this);
    parentGraph._children.remove(this);
  }
}

class DirectedEdge {
  final PlanetaryBase parentGraph;
  final ItemData item;
  final ProdLineNode parent;
  final ProdLineNode child;
  double _amount;
  ItemFlowDirection _flowDirection;
  EdgeType _edgeType;

  double get amount => _amount;
  ItemFlowDirection get flowDirection => _flowDirection;
  EdgeType get edgeType => _edgeType;

  DirectedEdge._addToGraph({
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

  void _removeFromGraph() {
    parentGraph._edges.remove(this);

    parentGraph._parents[child]!.remove(this);
    parentGraph._children[parent]!.remove(this);
  }
}
