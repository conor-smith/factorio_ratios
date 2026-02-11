part of '../production_line.dart';

class PlanetaryBase extends ProductionLine {
  final List<ProdLineNode> _nodes = [];
  final List<DirectedEdge> _edges = [];
  final Map<ItemData, double> _totalIoPerSecond = {};
  final Set<ItemData> _allInputs = {};
  final Set<ItemData> _allOutputs = {};

  GraphUpdates _graphUpdates = GraphUpdates._();

  late final List<ProdLineNode> nodes = UnmodifiableListView(_nodes);
  late final List<DirectedEdge> edges = UnmodifiableListView(_edges);
  @override
  late final Map<ItemData, double> totalIoPerSecond = UnmodifiableMapView(
    _totalIoPerSecond,
  );
  @override
  late final Set<ItemData> allInputs = UnmodifiableSetView(_allInputs);
  @override
  late final Set<ItemData> allOutputs = UnmodifiableSetView(_allOutputs);

  GraphUpdates get updates {
    GraphUpdates toReturn = _graphUpdates;
    _graphUpdates = GraphUpdates._();
    return toReturn;
  }

  @override
  void update(Map<ItemData, double> requirements) {
    // TODO
  }

  void addOutputNodes(Set<ItemData> itemD) {
    // TODO
  }
}

enum NodeType { resource, disposal, input, output, productionLine }

enum ItemFlowDirection { parentToChild, childToParent }

enum EdgeType { requestItems, acceptExcess }

class ProdLineNode {
  final PlanetaryBase parentBase;
  NodeType _type;
  ProductionLine? _line;
  Map<ItemData, double> _requirements;

  ProdLineNode._(
    this.parentBase,
    this._type, {
    ProductionLine? line,
    Map<ItemData, double>? requirements,
  }) : _line = line,
       _requirements = requirements ?? {};

  void makeSingleRecipe(ImmutableModuledMachineAndRecipe mmr) {
    // TODO
  }
}

class DirectedEdge {
  final ItemData flow;
  final ProdLineNode parent;
  final ProdLineNode child;
  double _amount;
  ItemFlowDirection _flowDirection;
  EdgeType _edgeType;

  double get amount => _amount;
  ItemFlowDirection get flowDirection => _flowDirection;
  EdgeType get edgeType => _edgeType;

  DirectedEdge._({
    required this.flow,
    required this.parent,
    required this.child,
    double initialAmount = 0,
    required ItemFlowDirection flowDirection,
    required EdgeType edgeType,
  }) : _amount = initialAmount,
       _flowDirection = flowDirection,
       _edgeType = edgeType;
}

class GraphUpdates {
  final List<ProdLineNode> newNodes = [];
  final List<ProdLineNode> removedNodes = [];
  final List<DirectedEdge> newEdges = [];
  final List<DirectedEdge> removedEdges = [];

  GraphUpdates._();
}
