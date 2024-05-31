import 'dart:collection';

import 'package:factorio_ratios/backend/base/moduled_building.dart';
import 'package:factorio_ratios/backend/factorio_objects/objects.dart';

class FactorioGraphException implements Exception {
  final String message;

  const FactorioGraphException(this.message);
}

abstract class GraphNode {
  final FactorioGraph graph;

  GraphNode({required this.graph});

  void generateDependencies();
  Map<Item, double> get netIo;
}

abstract class CrafterNode extends GraphNode {
  CrafterNode({required super.graph});

  Map<Recipe, ImmutableModuledBuilding> get crafters;
}

class FactorioGraph {
  final ItemContext itemContext;
  final Map<GraphNode, GraphDependency> _fullGraph = {};

  late final Map<GraphNode, GraphDependency> fullGraph =
      UnmodifiableMapView(_fullGraph);

  FactorioGraph(this.itemContext);

  void calculate() {
    throw UnimplementedError();
  }

  Map<Item, double> get netIo {
    throw UnimplementedError();
  }
}

class GraphDependency {
  final Item item;
  final Map<GraphNode, double> _sources;

  late final Map<GraphNode, double> sources = UnmodifiableMapView(_sources);

  GraphDependency(this.item, Map<GraphNode, double> sources)
      : _sources = Map.from(sources) {
    throw UnimplementedError();
  }

  GraphDependency.singleSource(this.item, GraphNode source)
      : _sources = {source: 1.0};
}
