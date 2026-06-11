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

part 'graph_state.dart';

class Graph
    implements NodeElement<GraphState, GraphEvent>, ProductionLine<GraphIo> {
  final BasePlanner _basePlanner;

  @override
  final int id;
  final Surface? surface;
  @override
  final Graph? parentGraph;
  final SurfaceProperties? _surfaceProperties;

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
  ItemIo? get ioRatios => null;

  Graph(
    BasePlanner basePlanner, {
    this.parentGraph,
    this.surface,
    EntityPrototype? icon,
  }) : _basePlanner = basePlanner,
       id = BasePlannerElement.generateId(),
       _state = GraphStateImpl._(icon: icon ?? surface),
       _surfaceProperties = basePlanner.surfaceProperties[surface] {
    _builder = GraphStateBuilder._new(this);
  }

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

  @override
  ProductionLine get productionLine => this;

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
