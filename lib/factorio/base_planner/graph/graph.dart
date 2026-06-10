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
  GraphIo get io => state.getIo(this);
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
    var builder = GraphStateBuilder._from(this);
    _builder = builder;

    basePlanner.getSnapshotBuilder().addToSnapsnot(this, builder);
  }

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
    if (_builder == null) {
      var builder = GraphStateBuilder._from(this);
      _basePlanner.getSnapshotBuilder().addToSnapsnot(this, builder);
      _builder = builder;
    }

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

  // All following fields are derived from above fields
  // They are calculated and cached when required
  _GraphStateCache _cache;

  late final Set<NodeElement> allNodes = Set.unmodifiable({
    ...prodLineNodes,
    ...graphNodes,
  });

  Set<Edge> get parents => _cache.getParents(prodLineNodes);
  Set<Edge> get children => _cache.getChildren(prodLineNodes);
  Set<InGameItem> get inputItems => _cache.getInputItems(prodLineNodes);
  Set<InGameItem> get outputItems => _cache.getOutputItems(prodLineNodes);
  GraphIo getIo(Graph graph) => _cache.getIo(graph);

  GraphState._({
    this.name = 'graph',
    this.icon,
    Iterable<ProdLineNode> prodLineNodes = const {},
    Iterable<Graph> graphNodes = const {},
    Iterable<Edge> edges = const {},
    _GraphStateCache? cache,
    this.nodeGeometry = NodeGeometry.uninitialised,
  }) : prodLineNodes = Set.unmodifiable(prodLineNodes),
       graphNodes = Set.unmodifiable(graphNodes),
       edges = Set.unmodifiable(edges),
       _cache = cache ?? _GraphStateCache();

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class GraphStateBuilder implements NodeStateBuilder<GraphState>, GraphState {
  final Graph _graph;

  String _name;
  EntityPrototype? _icon;
  final Set<ProdLineNode> _prodLineNodes;
  final Set<Edge> _edges;
  final Set<Graph> _graphNodes;
  NodeGeometry _nodeGeometry;

  @override
  _GraphStateCache _cache;

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
  Set<NodeElement> get allNodes => {..._prodLineNodes, ..._graphNodes};

  @override
  Set<Edge> get parents => _cache.getParents(prodLineNodes);
  @override
  Set<Edge> get children => _cache.getChildren(prodLineNodes);
  @override
  Set<InGameItem> get inputItems => _cache.getInputItems(prodLineNodes);
  @override
  Set<InGameItem> get outputItems => _cache.getOutputItems(prodLineNodes);
  @override
  GraphIo getIo(Graph graph) => _cache.getIo(graph);

  GraphStateBuilder._from(this._graph)
    : _name = _graph.name,
      _icon = _graph.icon,
      _prodLineNodes = Set.from(_graph.prodLineNodes),
      _edges = Set.from(_graph.edges),
      _graphNodes = Set.from(_graph.graphNodes),
      _nodeGeometry = _graph.nodeGeometry,
      _cache = _GraphStateCache.from(_graph._state._cache);

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
  void addChild(Edge chidEdge) => clearIoNodeItems();
  @override
  void addParent(Edge parentEdge) => clearIoNodeItems();
  @override
  void removeChild(Edge childEdge) => clearIoNodeItems();
  @override
  void removeParent(Edge parentEdge) => clearIoNodeItems();

  void clearIoNodeItems() => _cache.clearIoNodeItems();

  void clearIo() {
    if (_cache._io != null) {
      _cache.clearIo();
      Graph? graph = _graph;

      while (graph != null) {
        graph.getStateBuilder().clearIo();
        graph = graph.parentGraph;
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
    cache: _GraphStateCache.from(_cache),
  );

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class GraphIo extends ProductionLineIo {
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

class _GraphStateCache {
  Set<Edge>? _parents;
  Set<Edge>? _children;

  Set<InGameItem>? _inputItems;
  Set<InGameItem>? _outputItems;

  GraphIo? _io;

  _GraphStateCache();

  _GraphStateCache.from(_GraphStateCache oldCache) {
    _parents = oldCache._parents;
    _children = oldCache._children;
    _inputItems = oldCache._inputItems;
    _outputItems = oldCache._outputItems;
    _io = oldCache._io;
  }

  Set<Edge> getParents(Iterable<ProdLineNode> prodLineNodes) {
    if (_parents == null) {
      _populateIoNodeItems(prodLineNodes);
    }

    return _parents!;
  }

  Set<Edge> getChildren(Iterable<ProdLineNode> prodLineNodes) {
    if (_children == null) {
      _populateIoNodeItems(prodLineNodes);
    }

    return _children!;
  }

  Set<InGameItem> getInputItems(Iterable<ProdLineNode> prodLineNodes) {
    if (_inputItems == null) {
      _populateIoNodeItems(prodLineNodes);
    }

    return _inputItems!;
  }

  Set<InGameItem> getOutputItems(Iterable<ProdLineNode> prodLineNodes) {
    if (_outputItems == null) {
      _populateIoNodeItems(prodLineNodes);
    }

    return _outputItems!;
  }

  GraphIo getIo(Graph graph) {
    _io ??= graph.calculate(ItemIo());

    return _io!;
  }

  void clearIoNodeItems() {
    _parents = null;
    _children = null;
    _inputItems = null;
    _outputItems = null;
  }

  void clearIo() {
    _io = null;
  }

  void _populateIoNodeItems(Iterable<ProdLineNode> prodLineNodes) {
    Set<Edge> parents = {};
    Set<Edge> children = {};
    Set<InGameItem> inputItems = {};
    Set<InGameItem> outputItems = {};

    for (var ioNode in prodLineNodes.where((node) => node.nodeType.isIo)) {
      parents.addAll(
        ioNode.parents.where(
          (edge) => edge.parentGraph == ioNode.parentGraph.parentGraph,
        ),
      );

      children.addAll(
        ioNode.children.where(
          (edge) => edge.parentGraph == ioNode.parentGraph.parentGraph,
        ),
      );

      if (ioNode.nodeType == NodeType.input) {
        inputItems.addAll(ioNode.inputItems);
      } else if (ioNode.nodeType == NodeType.output) {
        outputItems.addAll(ioNode.outputItems);
      }
    }

    _parents = Set.unmodifiable(parents);
    _children = Set.unmodifiable(children);
    _inputItems = Set.unmodifiable(inputItems);
    _outputItems = Set.unmodifiable(outputItems);
  }
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

        sumMaps(netInput, io.netIo.inputs);
        sumMaps(netOutput, io.netIo.outputs);
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
