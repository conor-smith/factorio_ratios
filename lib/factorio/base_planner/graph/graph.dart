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
  GraphState _state;
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
  String get type => 'graph';
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
       _state = GraphState._(icon: icon ?? surface),
       _surfaceProperties = basePlanner.surfaceProperties[surface] {
    _builder = GraphStateBuilder._new(this);
  }

  @override
  void remove() => GraphStateBuilder._remove(this);

  @override
  GraphState get state => _builder ?? _state;
  @override
  set state(GraphState state) {
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

class GraphState implements ToJson {
  final String name;
  final EntityPrototype? icon;
  final Set<ProdLineNode> prodLineNodes;
  final Set<Graph> graphNodes;
  final Set<Edge> edges;
  final NodeGeometry nodeGeometry;
  final Set<Edge> parents;
  final Set<Edge> children;
  final Set<InGameItem> inputItems;
  final Set<InGameItem> outputItems;
  final GraphIo? io;

  late final Set<NodeElement> allNodes = Set.unmodifiable({
    ...prodLineNodes,
    ...graphNodes,
  });

  GraphState._({
    this.name = 'graph',
    this.icon,
    Iterable<ProdLineNode> prodLineNodes = const {},
    Iterable<Graph> graphNodes = const {},
    Iterable<Edge> edges = const {},
    this.nodeGeometry = NodeGeometry.uninitialised,
    Iterable<Edge> parents = const {},
    Iterable<Edge> children = const {},
    Iterable<InGameItem> inputItems = const {},
    Iterable<InGameItem> outputItems = const {},
    this.io,
  }) : prodLineNodes = Set.unmodifiable(prodLineNodes),
       graphNodes = Set.unmodifiable(graphNodes),
       edges = Set.unmodifiable(edges),
       parents = Set.unmodifiable(parents),
       children = Set.unmodifiable(children),
       inputItems = Set.unmodifiable(inputItems),
       outputItems = Set.unmodifiable(outputItems);

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class GraphStateBuilder implements NodeStateBuilder<GraphState>, GraphState {
  @override
  final Graph _graph;

  String _name;
  EntityPrototype? _icon;
  final Set<ProdLineNode> _prodLineNodes;
  final Set<Edge> _edges;
  final Set<Graph> _graphNodes;
  NodeGeometry _nodeGeometry;
  final Set<Edge> _parents;
  final Set<Edge> _children;
  final Set<InGameItem> _inputItems;
  final Set<InGameItem> _outputItems;
  GraphIo? _io;

  @override
  String get name => _name;
  @override
  EntityPrototype? get icon => _icon;
  @override
  late final Set<ProdLineNode> prodLineNodes = UnmodifiableSetView(
    _prodLineNodes,
  );
  @override
  late final Set<Edge> edges = UnmodifiableSetView(_edges);
  @override
  late final Set<Graph> graphNodes = UnmodifiableSetView(_graphNodes);
  @override
  NodeGeometry get nodeGeometry => _nodeGeometry;
  @override
  Set<Edge> get parents => UnmodifiableSetView(_parents);
  @override
  Set<Edge> get children => UnmodifiableSetView(_children);
  @override
  Set<InGameItem> get inputItems => UnmodifiableSetView(_inputItems);
  @override
  Set<InGameItem> get outputItems => UnmodifiableSetView(_outputItems);
  @override
  GraphIo? get io => _io;

  @override
  Set<NodeElement> get allNodes => {..._prodLineNodes, ..._graphNodes};

  factory GraphStateBuilder._new(Graph graph) {
    var builder = GraphStateBuilder._from(graph);

    var parentGraph = graph.parentGraph;
    if (parentGraph != null) {
      parentGraph.getStateBuilder()
        ..addChildGraph(graph)
        ..clearIo();
    }

    return builder;
  }

  static void _remove(Graph graph) {
    for (var edge in graph.edges) {
      edge.remove();
    }
    for (var node in graph.allNodes) {
      node.remove();
    }

    var parentGraph = graph.parentGraph;
    if (parentGraph != null) {
      parentGraph.getStateBuilder()
        ..removeChildGraph(graph)
        ..clearIo();
    }
  }

  GraphStateBuilder._from(this._graph)
    : _name = _graph.name,
      _icon = _graph.icon,
      _prodLineNodes = Set.from(_graph.prodLineNodes),
      _edges = Set.from(_graph.edges),
      _graphNodes = Set.from(_graph.graphNodes),
      _nodeGeometry = _graph.nodeGeometry,
      _parents = Set.from(_graph.parents),
      _children = Set.from(_graph.children),
      _inputItems = Set.from(_graph.inputItems),
      _outputItems = Set.from(_graph.outputItems) {
    _graph._basePlanner.getSnapshotBuilder().addToSnapsnot(_graph, this);
  }

  void updateName(String newName) => _name = newName;

  void updateIcon(EntityPrototype newIcon) => _icon = newIcon;
  void clearIcon() => _icon = null;

  void addNode(ProdLineNode node) => _prodLineNodes.add(node);
  void removeNode(ProdLineNode node) => _prodLineNodes.remove(node);

  void addEdge(Edge edge) => _edges.add(edge);
  void removeEdge(Edge edge) => _edges.remove(edge);

  void addChildGraph(Graph childGraph) => _graphNodes.add(childGraph);
  void removeChildGraph(Graph childGraph) => _graphNodes.remove(childGraph);

  @override
  void updateGeometry(NodeGeometry nodeGeometry) =>
      _nodeGeometry = nodeGeometry;

  @override
  void addParent(Edge parent) => _parents.add(parent);
  @override
  void addChild(Edge child) => _children.add(child);
  @override
  void removeParent(Edge parent) => _parents.remove(parent);
  @override
  void removeChild(Edge child) => _children.remove(child);

  void addOutputItems(Iterable<InGameItem> outputs) =>
      _outputItems.addAll(outputs);
  void addInputItems(Iterable<InGameItem> inputs) => _inputItems.addAll(inputs);
  void removeOutputItems(Iterable<InGameItem> outputs) =>
      _outputItems.removeAll(outputs);
  void removeInputItems(Iterable<InGameItem> inputs) =>
      _inputItems.removeAll(inputs);

  void clearIo() {
    if (_io != null) {
      _io = null;

      Graph? parentGraph = _graph.parentGraph;
      while (parentGraph != null) {
        parentGraph.getStateBuilder().clearIo();
        parentGraph = parentGraph.parentGraph;
      }
    }
  }

  @override
  GraphState build() => GraphState._(
    name: _name,
    prodLineNodes: _prodLineNodes,
    edges: edges,
    graphNodes: _graphNodes,
    nodeGeometry: _nodeGeometry,
    parents: _parents,
    children: _children,
    inputItems: inputItems,
    outputItems: outputItems,
    io: io,
  );

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
    required super.netIo,
    required super.totalIo,
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
  final ItemAmounts netInput = {};
  final ItemAmounts netOutput = {};
  final ItemAmounts totalInput = {};
  final ItemAmounts totalOutput = {};
  double electricPowerConsumption = 0.0;
  final Map<String, double> emissions = {};

  void add(NodeElement node) {
    var io = node.io;

    if (io != null) {
      if (node.nodeType.isIo) {
        sumMaps(inputConstraints, io.constraints.inputs);
        sumMaps(outputConstraints, io.constraints.outputs);
      }

      if (node.nodeType == NodeType.output) {
        sumMaps(netOutput, io.netIo.outputs);
      } else if (node.nodeType == NodeType.input) {
        sumMaps(netInput, io.netIo.inputs);
      }

      sumMaps(totalInput, io.totalIo.inputs);
      sumMaps(totalOutput, io.totalIo.outputs);

      electricPowerConsumption += io.electricPowerConsumption;

      sumMaps(emissions, io.emissions);
    }
  }

  @override
  GraphIo build() => GraphIo(
    constraints: ItemIo(inputs: inputConstraints, outputs: outputConstraints),
    netIo: ItemIo(inputs: netInput, outputs: netOutput),
    totalIo: ItemIo(inputs: totalInput, outputs: totalOutput),
    electricPowerConsumption: electricPowerConsumption,
    emissions: emissions,
  );
}
