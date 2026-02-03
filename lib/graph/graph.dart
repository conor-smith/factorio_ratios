import 'dart:collection';

import 'package:factorio_ratios/factorio/models.dart';

part 'production_lines/infinite_lines.dart';
part 'production_lines/single_recipe.dart';

class GraphException implements Exception {

}

class Graph {
  final List<GraphVertex> _vertices = [];
  final List<GraphEdge> _edges = [];

  // These two lists do result in some duplication, but make looking up much quicker
  final Map<GraphVertex, List<GraphEdge>> _parents = {};
  final Map<GraphVertex, List<GraphEdge>> _children = {};

  final Map<GraphCondition, GraphVertex> _conditions = {};

  late final List<GraphVertex> vertices = UnmodifiableListView(_vertices);
  late final List<GraphEdge> edges = UnmodifiableListView(_edges);
  late final Map<GraphCondition, GraphVertex> conditions = UnmodifiableMapView(
    _conditions,
  );
}

class GraphEdge {
  final GraphVertex parent;
  final GraphVertex child;
  final ItemAmount flow;

  GraphEdge._(this.parent, this.child, this.flow);
}

class GraphVertex implements ProductionLine {
  final Graph _graph;

  ProductionLine _containedLine;

  GraphVertex._(this._graph, this._containedLine);

  ProductionLine get containedLine => _containedLine;

  List<GraphEdge> get children =>
      UnmodifiableListView(_graph._parents[this] ?? const []);
  List<GraphEdge> get parents =>
      UnmodifiableListView(_graph._children[this] ?? const []);

  @override
  List<ItemAmount> get ingredientsPerSecond =>
      _containedLine.ingredientsPerSecond;
  @override
  List<ItemAmount> get resultsPerSecond => _containedLine.resultsPerSecond;

  @override
  List<CraftingMachineAmount> get craftingMachines =>
      _containedLine.craftingMachines;

  @override
  List<ItemAmount> get solidFuelPerSecond => _containedLine.solidFuelPerSecond;
  @override
  List<ItemAmount> get burntOutputPerSecond =>
      _containedLine.burntOutputPerSecond;
  @override
  List<ItemAmount> get fluidFuelPerSecond => _containedLine.fluidFuelPerSecond;

  @override
  Map<String, double> get emissionsPerMinute =>
      _containedLine.emissionsPerMinute;

  @override
  double get electricityW => _containedLine.electricityW;
  @override
  double get solidFuelW => _containedLine.solidFuelW;
  @override
  double get fluidFuelW => _containedLine.fluidFuelW;
  @override
  double get heatW => _containedLine.heatW;
}

class GraphCondition {
  final ItemAmount requiredOutput;

  GraphCondition._(this.requiredOutput);
}

abstract interface class ProductionLine {
  List<ItemAmount> get ingredientsPerSecond;
  List<ItemAmount> get resultsPerSecond;

  List<CraftingMachineAmount> get craftingMachines;

  List<ItemAmount> get solidFuelPerSecond;
  List<ItemAmount> get burntOutputPerSecond;
  List<ItemAmount> get fluidFuelPerSecond;

  Map<String, double> get emissionsPerMinute;

  double get electricityW;
  double get solidFuelW;
  double get fluidFuelW;
  double get heatW;
}

class ItemAmount {
  final Item item;
  double _amount;

  ItemAmount._(this.item, {double amount = 0}) : this._amount = amount;

  double get amount => _amount;
}

class CraftingMachineAmount {
  final CraftingMachine craftingMachine;
  double _amount = 0;

  double _electricityW = 0;
  double _solidFuelW = 0;
  double _fluidFuelW = 0;
  double _heatW = 0;

  ItemAmount? _solidFuelPerSecond;
  ItemAmount? _fluidFuelPerSecond;

  CraftingMachineAmount._(this.craftingMachine);

  double get amount => _amount;

  double get electricityW => _electricityW;
  double get solidFuelW => _solidFuelW;
  double get fluidFuelW => _fluidFuelW;
  double get heatW => _heatW;

  ItemAmount? get solidFuelPerSecond => _solidFuelPerSecond;
  ItemAmount? get fluidFuelPerSecond => _fluidFuelPerSecond;

  ItemAmount? get burntFuelPerSecond {
    Item? burntResult = (_solidFuelPerSecond?.item as SolidItem?)?.burntResult;

    if (burntResult == null) {
      return null;
    } else {
      return ItemAmount._(burntResult, amount: _amount);
    }
  }
}
