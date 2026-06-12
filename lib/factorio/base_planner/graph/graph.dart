import 'dart:collection';

import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/edge/edge.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/node_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/node/node.dart';
import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/factorio/models/models.dart';
import 'package:factorio_ratios/factorio/production_lines/production_line.dart';
import 'package:factorio_ratios/json/json.dart';
import 'package:factorio_ratios/utility/utility.dart';
import 'package:sorted_list/sorted_list.dart';

part 'graph_state.dart';

class Graph
    implements NodeElement<GraphState, GraphEvent>, ProductionLine<GraphIo> {
  final BasePlanner _basePlanner;

  @override
  final int id;
  final Surface? surface;
  @override
  final Graph? parentGraph;
  final SurfaceProperties _surfaceProperties;

  final EventNotifier<GraphEvent> _notifier = EventNotifierImpl();
  GraphStateImpl _state;
  GraphStateBuilder? _builder;

  // For convenience
  @override
  String get name => state.name;
  @override
  EntityPrototype? get icon => state.icon;
  @override
  NodeGeometry get nodeGeometry => state.nodeGeometry;
  @override
  Set<Edge> get parents => state.parents;
  @override
  Set<Edge> get children => state.children;
  @override
  Map<InGameItem, List<Edge>> get inputEdges => state.inputEdges;
  @override
  Map<InGameItem, List<Edge>> get outputEdges => state.outputEdges;
  @override
  GraphIo? get io => state.io;
  Set<Graph> get graphNodes => state.graphNodes;
  Set<ProdLineNode> get prodLineNodes => state.prodLineNodes;
  Set<NodeElement> get allNodes => state.allNodes;
  Set<Edge> get edges => state.edges;
  @override
  Set<InGameItem> get inputItems => state.inputItems;
  @override
  Set<InGameItem> get outputItems => state.outputItems;

  @override
  ProductionLineType get productionLineType => ProductionLineType.graph;
  @override
  NodeType get nodeType => NodeType.productionLine;
  @override
  ProductionLine get productionLine => this;

  @override
  ItemIo? get ioRatios => null;

  final Map<InGameItem, SortedList<NodeElement>> _cachedNodeOutputIndex = {};

  Graph.addToBasePlanner(
    BasePlanner basePlanner, {
    this.parentGraph,
    this.surface,
    EntityPrototype? icon,
  }) : _basePlanner = basePlanner,
       id = BasePlannerElement.generateId(),
       _state = GraphStateImpl._(icon: icon ?? surface),
       _surfaceProperties =
           basePlanner.surfaceProperties[surface] ?? SurfaceProperties.empty {
    _builder = GraphStateBuilder._new(this);
  }

  Graph.rootGraph(BasePlanner basePlanner, [this.surface])
    : _basePlanner = basePlanner,
      id = BasePlannerElement.generateId(),
      parentGraph = null,
      _state = GraphStateImpl._(icon: surface),
      _surfaceProperties =
          basePlanner.surfaceProperties[surface] ?? SurfaceProperties.empty;

  @override
  void remove() => GraphStateBuilder._remove(this);

  @override
  GraphState get state => _builder ?? _state;
  @override
  set state(GraphStateImpl state) {
    _basePlanner.throwIfMutationNotPermitted();
    _builder = null;

    // Validate state
    _state = state;
  }

  @override
  GraphStateBuilder getStateBuilder() {
    _builder ??= GraphStateBuilder._from(this);

    return _builder!;
  }

  @override
  void addListener(Object listener, Function(GraphEvent event) callback) =>
      _notifier.addListener(listener, callback);
  @override
  void removeListener(Object listener) => _notifier.removeListener(listener);
  @override
  void clearListeners() => _notifier.clearListeners();
  @override
  void notifyListeners(GraphEvent event) => _notifier.notifyListeners(event);

  @override
  void notifyListenersOfStateChange(GraphState oldState, GraphState newState) {
    // TODO: implement notifyListenerOfStateChange
    throw UnimplementedError();
  }

  @override
  void notifyListenersOfGeometryUpdate(NodeGeometry nodeGeometry) {
    // TODO: implement notifyListenersOfGeometryUpdate
    throw UnimplementedError();
  }

  void addConsumerNodeAndTree(InGameItem item) {
    if (surface == null) {
      throw const GraphException(
        'Cannot build node tree of graph with no surface',
      );
    }

    var existingConsumerNode = prodLineNodes
        .where(
          (node) =>
              node.nodeType == NodeType.consumer &&
              node.inputItems.contains(item),
        )
        .firstOrNull;
    if (existingConsumerNode == null) {
      _basePlanner.buildNextSnapshot(() {
        var consumerNode = ProdLineNode.addToBasePlanner(
          basePlanner: _basePlanner,
          parentGraph: this,
          nodeType: NodeType.consumer,
          productionLine: MagicLine.singleItemConsumer(item),
        );

        _resetNodeOutputIndex();

        _createNodeTree(consumerNode, {});
      });
    }
  }

  @override
  GraphIo calculate(ItemIo constraints) {
    var ioBuilder = GraphIoBuilder();

    for (var node in allNodes) {
      ioBuilder.add(node);
    }

    return ioBuilder.build();
  }

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }

  void _resetNodeOutputIndex() {
    _cachedNodeOutputIndex.clear();

    for (var node in allNodes.where(
      (node) => node.nodeType != NodeType.output,
    )) {
      _addToNodeOutputIndex(node);
    }
  }

  void _addToNodeOutputIndex(NodeElement node) {
    for (var output in node.outputItems) {
      // TODO: optimise this
      _cachedNodeOutputIndex.update(
        output,
        (nodeList) => nodeList..add(node),
        ifAbsent: () => SortedList(
          (node1, node2) => node1.nodeType.compareTo(node2.nodeType),
        )..add(node),
      );
    }
  }

  void _createNodeTree(NodeElement startNode, Set<NodeElement> visitedNodes) {
    visitedNodes.add(startNode);

    var inputEdges = startNode.inputEdges;

    for (var inputItem in startNode.inputItems.where(
      (input) => inputEdges.containsKey(input),
    )) {
      var nextNode =
          _findExistingNodeWithOutput(inputItem) ?? _createNewNode(inputItem);

      Edge.addToBasePlanner(
        basePlanner: _basePlanner,
        parentGraph: this,
        edgeType: EdgeType.requestItems,
        parent: startNode,
        child: nextNode,
        item: inputItem,
      );

      if (!visitedNodes.contains(nextNode)) {
        _createNodeTree(nextNode, visitedNodes);
      }
    }
  }

  NodeElement? _findExistingNodeWithOutput(InGameItem output) =>
      _cachedNodeOutputIndex[output]?.firstOrNull;

  ProdLineNode _createNewNode(InGameItem requiredOutput) {
    var newNode =
        _createResourceNode(requiredOutput) ??
        _createRecipeNode(requiredOutput) ??
        _createProducerNode(requiredOutput);

    _addToNodeOutputIndex(newNode);
    return newNode;
  }

  ProdLineNode? _createResourceNode(InGameItem requiredOutput) {
    if (_surfaceProperties.resources.contains(requiredOutput)) {
      return ProdLineNode.addToBasePlanner(
        basePlanner: _basePlanner,
        parentGraph: this,
        nodeType: NodeType.resource,
        productionLine: MagicLine.singleItemProducer(requiredOutput),
      );
    } else {
      return null;
    }
  }

  ProdLineNode? _createRecipeNode(InGameItem requiredOutput) {
    // TODO - check for valid fluid temperatures
    var baseRecipe = _surfaceProperties.defaultRecipes
        .where(
          (recipe) => recipe.results.any(
            (product) => product.item == requiredOutput.internalItem,
          ),
        )
        .firstOrNull;

    if (baseRecipe != null) {
      var quality = requiredOutput is InGameSolidItem
          ? requiredOutput.quality
          : 1;
      var inGameRecipe = InGameRecipe(baseRecipe, quality);

      var inGameMachine = InGameMachine(
        _basePlanner.sortedMachines.firstWhere(
          (machine) => machine.recipes.contains(baseRecipe),
        ),
      );

      InGameSolidItem? fuel;
      if (inGameMachine.needsSolidFuel) {
        var burner = inGameMachine.energySource as BurnerEnergySource;

        // Search existing nodes for valid fuel
        var existingNodeFuel = burner.fuelItems
            .where(
              (fuelItem) =>
                  _findExistingNodeWithOutput(InGameItem(fuelItem)) != null,
            )
            .map((item) => InGameSolidItem(item));

        // Search surface for valid fuel
        var surfaceFuels = _surfaceProperties.availableSolidFuels.where(
          (surfaceFuel) => burner.fuelItems.contains(surfaceFuel.internalItem),
        );

        // Use first valid fuel
        var machineFuels = burner.fuelItems.map(
          (fuelItem) => InGameSolidItem(fuelItem),
        );

        fuel = existingNodeFuel
            .followedBy(surfaceFuels)
            .followedBy(machineFuels)
            .first;
      }

      return ProdLineNode.addToBasePlanner(
        basePlanner: _basePlanner,
        parentGraph: this,
        nodeType: NodeType.productionLine,
        productionLine: SingleRecipeLine.fromBaseMachine(
          inGameMachine,
          inGameRecipe,
          surface: surface,
          fuel: fuel,
        ),
      );
    } else {
      return null;
    }
  }

  ProdLineNode _createProducerNode(InGameItem requiredOutput) =>
      ProdLineNode.addToBasePlanner(
        basePlanner: _basePlanner,
        parentGraph: this,
        nodeType: NodeType.producer,
        productionLine: MagicLine.singleItemProducer(requiredOutput),
      );
}

class GraphIo extends ProductionLineIo {
  factory GraphIo.fromState(GraphState state) {
    var builder = GraphIoBuilder();

    for (var node in state.allNodes) {
      builder.add(node);
    }

    return builder.build();
  }

  GraphIo({
    required super.constraints,
    required super.io,
    required super.totalProductionAndConsumption,
    required super.electricPowerConsumption,
    super.displayData = const [],
    required super.emissions,
  });
}

class GraphEvent {
  GraphEvent.geometryOp(NodeGeometry nodeGeometry) {
    // TODO
    throw UnimplementedError();
  }
}

class GraphException extends BasePlannerException {
  const GraphException(super.message, [super.cause]);
}

class GraphIoBuilder implements Builder<GraphIo> {
  final ItemAmounts inputConstraints = {};
  final ItemAmounts outputConstraints = {};
  final ItemAmounts input = {};
  final ItemAmounts output = {};
  final ItemAmounts consumption = {};
  final ItemAmounts production = {};
  double electricPowerConsumption = 0.0;
  final Map<String, double> emissions = {};

  void add(NodeElement node) {
    var io = node.io;

    if (io != null) {
      if (node.nodeType == NodeType.input) {
        sumMaps(inputConstraints, io.constraints.inputs);
        sumMaps(input, io.io.inputs);
      } else if (node.nodeType == NodeType.output) {
        sumMaps(outputConstraints, io.constraints.outputs);
        sumMaps(output, io.io.outputs);
      }

      sumMaps(consumption, io.totalProductionAndConsumption.inputs);
      sumMaps(production, io.totalProductionAndConsumption.outputs);

      electricPowerConsumption += io.electricPowerConsumption;

      sumMaps(emissions, io.emissions);
    }
  }

  @override
  GraphIo build() => GraphIo(
    constraints: ItemIo(inputs: inputConstraints, outputs: outputConstraints),
    io: ItemIo(inputs: input, outputs: output),
    totalProductionAndConsumption: ItemIo(
      inputs: consumption,
      outputs: production,
    ),
    electricPowerConsumption: electricPowerConsumption,
    emissions: emissions,
  );
}
