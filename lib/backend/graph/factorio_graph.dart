import 'dart:collection';

import 'package:factorio_ratios/backend/graph/moduled_machine.dart';
import 'package:factorio_ratios/backend/factorio_objects/objects.dart';
import 'package:sorted_list/sorted_list.dart';

class FactorioGraph {
  final ItemContext itemContext;
  final Map<GraphNode, GraphEdge> _fullGraph = {};

  Map<Item, double> _netIo = {};
  double _totalPowerConsumption = 0;
  double _totalPowerDrain = 0;
  double _totalPollutionPerMin = 0;
  double _rocketCompletionPerSecond = 0;

  late final Map<GraphNode, GraphEdge> fullGraph =
      UnmodifiableMapView(_fullGraph);
  late final List<ImmutableModuledMachine> defaultMachines =
      UnmodifiableListView(_defaultMachines);
  late final List<ImmutableModuledMachine> _defaultMachines =
      _createDefaultMachinesList();

  FactorioGraph(this.itemContext);

  void updateDefaultMachine(
      ImmutableModuledMachine oldMachine, ImmutableModuledMachine newMachine,
      [bool updateExistingNodes = false]) {
    // TODO
    throw UnimplementedError();
  }

  void addProductionLineNodeAndDeps({required Recipe recipe,
      required NodeConstraint constraint,
      required dynamic constraintSpec,
      ImmutableModuledMachine? craftingMachine}) {
    // TODO
    throw UnimplementedError();
  }

  void addRocketSiloNodeAndDeps({required Recipe recipe,
      required NodeConstraint constraint,
      required dynamic constraintSpec,
      ImmutableModuledMachine? craftingMahcine,
      Item? cargo}) {
    // TODO
    throw UnimplementedError();
  }

  void replaceNodesWithProductionLine({
    required List<GraphNode> nodesToReplace,
    required List
  })

  void _updateFromNode(GraphNode node) {
    // TODO
    throw UnimplementedError();
  }

  List<ImmutableModuledMachine> _createDefaultMachinesList() {
    // TODO
    throw UnimplementedError();
  }

  ImmutableModuledMachine _getDefaultMachine(Recipe recipe) {
    // TODO
    throw UnimplementedError();
  }

  Map<Item, double> get netIo => _netIo;
  double get totalPowerConsumption => _totalPowerConsumption;
  double get totalPowerDrain => _totalPowerDrain;
  double get totalPollutionPerMin => _totalPollutionPerMin;
}

class Crafter {
  final Recipe recipe;
  final ImmutableModuledMachine craftingMachine;

  final double totalBuildings;
  final double totalPowerConsumption;
  final double totalPowerDrain;
  final double totalPollutionPerMin;

  final Map<Item, double> netIo;
  final Map<Item, double> buildingInput;
  final Map<Item, double> buildingOutput;

  Crafter._(
      {required this.recipe,
      required this.craftingMachine,
      required this.totalBuildings,
      required this.totalPowerConsumption,
      required this.totalPowerDrain,
      required this.totalPollutionPerMin,
      required this.netIo,
      required this.buildingInput,
      required this.buildingOutput});

  factory Crafter.totalBuildings(
      {required Recipe recipe,
      required ImmutableModuledMachine craftingMachine,
      required int totalBuildings}) {
    // TODO
    throw UnimplementedError();
  }

  factory Crafter.requiredOutput(
      {required Recipe recipe,
      required ImmutableModuledMachine craftingMachine,
      required Map<Item, double> requiredOutput}) {
    // TODO
    throw UnimplementedError();
  }
}

class GraphEdge {
  final GraphNode source;
  final GraphNode dest;

  double _requiredAmount;
  bool _isBottleNeck;

  GraphEdge(
      {required this.source,
      required this.dest,
      required double initialAmount,
      bool isBottleNeck = false})
      : _requiredAmount = initialAmount,
        _isBottleNeck = isBottleNeck;

  double get requiredAmount => _requiredAmount;
  bool get isBottleNeck => _isBottleNeck;
}

enum NodeConstraint {
  requiredBuildings(false),
  requiredOutputExplicit(false),
  requiredOutputDependency(true);

  final bool isDependency;

  const NodeConstraint(this.isDependency);
}

enum NodeType { resource, productionLine, rocketSilo }

class GraphNodeException implements Exception {
  final String message;

  const GraphNodeException(this.message);
}

abstract class GraphNode {
  final FactorioGraph factorioGraph;

  GraphNode({required this.factorioGraph});

  void modifyPrimaryCrafter(Recipe recipe, ImmutableModuledMachine newMachine) {
    _addOrModifyPrimaryCrafters({recipe: newMachine});

    factorioGraph._updateFromNode(this);
  }

  void modifySecondaryCrafter(
      Recipe recipe, ImmutableModuledMachine newMachine) {
    _addOrModifySecondaryCrafters({recipe: newMachine});

    factorioGraph._updateFromNode(this);
  }

  void setConstraint(NodeConstraint nodeConstraint, dynamic constraintSpec) {
    _setConstraint(nodeConstraint, constraintSpec);

    factorioGraph._updateFromNode(this);
  }

  void _addOrModifyPrimaryCrafters(
      Map<Recipe, ImmutableModuledMachine> toModify);
  void _addOrModifySecondaryCrafters(
      Map<Recipe, ImmutableModuledMachine> toModify);
  void _setConstraint(NodeConstraint nodeConstraint, dynamic constraintSpec);

  NodeType get nodeType;
  NodeConstraint get constraint;
  dynamic get constraintSpec;
  Map<Item, double> get netIo;
  List<Crafter> get primaryCrafters;
  List<Crafter> get secondaryCrafters;
  double get totalPowerConsumption;
  double get totalPowerDrain;
  double get totalPollutionPerMin;
}

class ResourceNode extends GraphNode {
  @override
  NodeType get nodeType => NodeType.resource;

  static const GraphNodeException _resourceNodeException =
      GraphNodeException("Cannot add crafter to resource node");

  final Item _resource;
  double _amount;

  ResourceNode(
      {required super.factorioGraph,
      required Item resource,
      required double requiredAmount})
      : _resource = resource,
        _amount = requiredAmount {
    // TODO
    throw UnimplementedError();
  }

  @override
  NodeConstraint get constraint => NodeConstraint.requiredOutputDependency;

  @override
  dynamic get constraintSpec => {_resource: _amount};

  @override
  void _setConstraint(NodeConstraint nodeConstraint, dynamic constraintSpec) {
    // TODO
    throw UnimplementedError();
  }

  @override
  Map<Item, double> get netIo => {_resource: _amount};

  @override
  List<Crafter> get primaryCrafters => const [];
  @override
  List<Crafter> get secondaryCrafters => const [];

  @override
  void _addOrModifyPrimaryCrafters(
          Map<Recipe, ImmutableModuledMachine> toModify) =>
      throw _resourceNodeException;

  @override
  void _addOrModifySecondaryCrafters(
          Map<Recipe, ImmutableModuledMachine> toModify) =>
      throw _resourceNodeException;

  @override
  double get totalPowerConsumption => 0;
  @override
  double get totalPowerDrain => 0;
  @override
  double get totalPollutionPerMin => 0;
}

// Used in sorted lists
int Function(Crafter, Crafter) _compareCrafters = (crafter1, crafter2) =>
    crafter1.recipe.name.compareTo(crafter2.recipe.name);

class ProductionLineNode extends GraphNode {
  @override
  NodeType get nodeType => NodeType.resource;

  NodeConstraint _constraint;
  dynamic _constraintSpec;

  // Initially set to 0 / empty to stop dart from yelling at me
  Map<Item, double> _netIo = {};
  double _totalPowerConsumption = 0;
  double _totalPowerDrain = 0;
  double _totalPollutionPerMin = 0;

  final SortedList<Crafter> _primaryCrafters = SortedList(_compareCrafters);
  final SortedList<Crafter> _secondaryCrafters = SortedList(_compareCrafters);

  @override
  late final List<Crafter> primaryCrafters =
      UnmodifiableListView(_primaryCrafters);
  @override
  late final List<Crafter> secondaryCrafters =
      UnmodifiableListView(_secondaryCrafters);

  ProductionLineNode(
      {required super.factorioGraph,
      required Recipe recipe,
      required ImmutableModuledMachine craftingMachine,
      required NodeConstraint constraint,
      required dynamic constraintSpec})
      : _constraint = constraint,
        _constraintSpec = constraintSpec {
    // TODO
    throw UnimplementedError();
  }

  @override
  void _addOrModifyPrimaryCrafters(
      Map<Recipe, ImmutableModuledMachine> toModify) {
    // TODO
    throw UnimplementedError();
  }

  @override
  void _addOrModifySecondaryCrafters(
      Map<Recipe, ImmutableModuledMachine> toModify) {
    // TODO
    throw UnimplementedError();
  }

  @override
  void _setConstraint(NodeConstraint nodeConstraint, constraintSpec) {
    // TODO
    throw UnimplementedError();
  }

  @override
  Map<Item, double> get netIo => _netIo;
  @override
  NodeConstraint get constraint => _constraint;
  @override
  dynamic get constraintSpec => _constraintSpec;
  @override
  double get totalPowerConsumption => _totalPowerConsumption;
  @override
  double get totalPowerDrain => _totalPowerDrain;
  @override
  double get totalPollutionPerMin => _totalPollutionPerMin;
}

class RocketSiloNode extends GraphNode {
  @override
  NodeType get nodeType => NodeType.rocketSilo;

  NodeConstraint _constraint;
  dynamic _constraintSpec;

  late Crafter _rocketPartCrafter;
  Item? _cargo;

  // Initially set to 0 / empty to stop dart from yelling at me
  Map<Item, double> _netIo = {};
  double _rocketCompletionPerSecond = 0;

  RocketSiloNode(
      {required super.factorioGraph,
      required Recipe rocketPartRecipe,
      required ImmutableModuledMachine craftingMachine,
      Item? cargo,
      required NodeConstraint constraint,
      required dynamic constraintSpec})
      : _cargo = cargo,
        _constraint = constraint,
        _constraintSpec = constraintSpec {
    // TODO
    throw UnimplementedError();
  }

  @override
  void _setConstraint(NodeConstraint nodeConstraint, constraintSpec) {
    // TODO
    throw UnimplementedError();
  }

  set cargo(Item? newCargo) {
    // TODO
    throw UnimplementedError();
  }

  @override
  void _addOrModifyPrimaryCrafters(
      Map<Recipe, ImmutableModuledMachine> toModify) {
    // TODO
    throw UnimplementedError();
  }

  @override
  void _addOrModifySecondaryCrafters(
      Map<Recipe, ImmutableModuledMachine> toModify) {
    throw const GraphNodeException(
        "Rocket silo node may not have secondary crafters");
  }

  Item? get cargo => _cargo;
  double get rocketCompletionPerSecond => _rocketCompletionPerSecond;

  @override
  List<Crafter> get primaryCrafters => [_rocketPartCrafter];
  @override
  List<Crafter> get secondaryCrafters => const [];
  @override
  Map<Item, double> get netIo => _netIo;
  @override
  NodeConstraint get constraint => _constraint;
  @override
  dynamic get constraintSpec => _constraintSpec;
  @override
  double get totalPowerConsumption => _rocketPartCrafter.totalPowerConsumption;
  @override
  double get totalPowerDrain => _rocketPartCrafter.totalPowerDrain;
  @override
  double get totalPollutionPerMin => _rocketPartCrafter.totalPollutionPerMin;
}
