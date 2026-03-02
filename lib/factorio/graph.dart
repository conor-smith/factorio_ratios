import 'dart:collection';

import 'package:factorio_ratios/factorio/production_line.dart';

part 'graph/node_and_edge.dart';

enum NodeType { consumer, producer, input, output, productionLine }

enum ItemFlowDirection { parentToChild, childToParent }

enum EdgeType { requestItems, acceptExcess }

class BaseGraph extends ProductionLine {
  final Set<ProdLineNode> _nodes = {};
  final Set<DirectedEdge> _edges = {};
  final Set<ItemData> _allInputs = {};
  final Set<ItemData> _allOutputs = {};
  final Map<ItemData, double> _totalIoPerSecond = const {};

  final Map<ProdLineNode, Set<DirectedEdge>> _parents = {};
  final Map<ProdLineNode, Set<DirectedEdge>> _children = {};

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

  @override
  void update(Map<ItemData, double> requirements) {}
}
