import 'dart:collection';

import 'package:factorio_ratios/factorio/factorio.dart';
import 'package:factorio_ratios/factorio/production_line.dart';

part 'graph/node_and_edge.dart';

class BaseGraph extends ProductionLine {
  final Set<ProdLineNode> _nodes = {};
  final Set<DirectedEdge> _edges = {};
  final Map<ItemData, double> _totalIoPerSecond = {};

  final Map<ProdLineNode, Set<DirectedEdge>> _parents = {};
  final Map<ProdLineNode, Set<DirectedEdge>> _children = {};

  late final List<ProdLineNode> nodes = UnmodifiableListView(_nodes);
  late final List<DirectedEdge> edges = UnmodifiableListView(_edges);

  @override
  late final Map<ItemData, double> totalIoPerSecond = UnmodifiableMapView(
    _totalIoPerSecond,
  );

  @override
  Set<ItemData> get allInputs => throw UnimplementedError();
  @override
  Set<ItemData> get allOutputs => throw UnimplementedError();

  @override
  void update(Map<ItemData, double> newRequirements) {
    super.update(newRequirements);
  }

  @override
  void reset() {
    for (var node in _nodes) {
      node.reset();
    }

    _totalIoPerSecond.clear();
  }
}
