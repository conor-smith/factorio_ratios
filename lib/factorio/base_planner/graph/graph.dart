import 'dart:collection';

import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/edge/edge.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/node_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/node/node.dart';
import 'package:factorio_ratios/factorio/models/models.dart';
import 'package:factorio_ratios/factorio/production_lines/production_line.dart';
import 'package:factorio_ratios/json/json.dart';

class Graph implements NodeElement<GraphState, GraphEvent> {
  final BasePlanner _basePlanner;

  @override
  final int id;
  final Surface? surface;
  @override
  final Graph? parentGraph;

  final EventNotifier<GraphEvent> _notifier = EventNotifierImpl();
  GraphState _state;
  GraphStateBuilder? _builder;

  // For convenience
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
  Set<Edge> get edges => state.edges;

  Graph(BasePlanner basePlanner, {this.parentGraph, this.surface})
    : _basePlanner = basePlanner,
      id = BasePlannerElement.generateId(),
      _state = GraphState._() {
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
  ProductionLine get productionLine => throw UnimplementedError();

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class GraphState implements ToJson {
  final Set<ProdLineNode> prodLineNodes;
  final Set<Graph> graphNodes;
  final Set<Edge> edges;
  final NodeGeometry nodeGeometry;

  Set<Edge>? _cachedParents;
  Set<Edge>? _cachedChildren;
  GraphIo? _cachedIo;

  // All following fields are derived from above fields
  // They are calculated and cached when required
  GraphIo get io {
    throw UnimplementedError();
  }

  Set<Edge> get parents {
    _cachedParents ??= _calculateExternalParents(prodLineNodes);

    return _cachedParents!;
  }

  // Affected whenever parentGraph gets a new edge connecting to an IO node
  Set<Edge> get children {
    _cachedChildren ??= _calculateExternalChildren(prodLineNodes);
    return _cachedChildren!;
  }

  GraphState._({
    Iterable<ProdLineNode> prodLineNodes = const {},
    Iterable<Graph> graphNodes = const {},
    Iterable<Edge> edges = const {},
    this.nodeGeometry = NodeGeometry.uninitialised,
    Set<Edge>? cachedParents,
    Set<Edge>? cachedChildren,
    GraphIo? cachedIo,
  }) : this.prodLineNodes = Set.unmodifiable(prodLineNodes),
       graphNodes = Set.unmodifiable(graphNodes),
       edges = Set.unmodifiable(edges),
       _cachedParents = cachedParents, // Assumed to be unmodifiable
       _cachedChildren = cachedChildren, // Assumed to be unmodifiable
       _cachedIo = cachedIo;

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class GraphStateBuilder implements NodeStateBuilder<GraphState>, GraphState {
  final Graph _graph;

  final Set<ProdLineNode> _prodLineNodes;
  final Set<Edge> _edges;
  final Set<Graph> _graphNodes;
  NodeGeometry _nodeGeometry;

  bool _hasClearedCachedIo = false;

  @override
  Set<Edge>? _cachedParents;
  @override
  Set<Edge>? _cachedChildren;
  @override
  GraphIo? _cachedIo;

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
  GraphIo get io {
    throw UnimplementedError();
  }

  @override
  Set<Edge> get parents {
    _cachedParents ??= _calculateExternalParents(_prodLineNodes);

    return _cachedParents!;
  }

  @override
  Set<Edge> get children {
    _cachedChildren ??= _calculateExternalChildren(_prodLineNodes);
    return _cachedChildren!;
  }

  GraphStateBuilder._from(this._graph)
    : _prodLineNodes = Set.from(_graph.prodLineNodes),
      _edges = Set.from(_graph.edges),
      _graphNodes = Set.from(_graph.graphNodes),
      _nodeGeometry = _graph.nodeGeometry,
      _cachedParents = _graph._state._cachedParents,
      _cachedChildren = _graph._state._cachedChildren,
      _cachedIo = _graph._state._cachedIo;

  void addNode(ProdLineNode node) => _prodLineNodes.add(node);
  void removeNode(ProdLineNode node) => _prodLineNodes.remove(node);

  void addEdge(Edge edge) => _edges.add(edge);

  void removeEdge(Edge edge) => _edges.remove(edge);

  void addChildGraph(Graph childGraph) => _graphNodes.add(childGraph);
  void removeChildGraph(Graph childGraph) => _graphNodes.remove(childGraph);

  @override
  void updateGeometry(NodeGeometry nodeGeometry) =>
      _nodeGeometry = nodeGeometry;

  void clearCachedParents() => _cachedParents = null;
  void clearCachedChildren() => _cachedChildren = null;
  void clearCachedIo() {
    if (!_hasClearedCachedIo) {
      _hasClearedCachedIo = true;
      _cachedIo = null;

      _graph.parentGraph?.getStateBuilder().clearCachedIo();
    }
  }

  @override
  GraphState build() => GraphState._(
    prodLineNodes: _prodLineNodes,
    edges: edges,
    graphNodes: _graphNodes,
    nodeGeometry: _nodeGeometry,
    cachedChildren: _cachedChildren,
    cachedParents: _cachedParents,
    cachedIo: _cachedIo,
  );

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class GraphIo extends FullIo {
  GraphIo({
    required super.inputConstraints,
    required super.outputConstraints,
    required super.netInput,
    required super.netOutput,
    required super.totalInput,
    required super.totalOutput,
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

Set<Edge> _calculateExternalParents(Iterable<ProdLineNode> nodes) =>
    Set.unmodifiable(
      nodes
          .where((node) => node.nodeType.isIo)
          .expand((node) => node.parents)
          .where((edge) => edge.parentProductionLine != edge.parentNode),
    );

Set<Edge> _calculateExternalChildren(Iterable<ProdLineNode> nodes) =>
    Set.unmodifiable(
      nodes
          .where((node) => node.nodeType.isIo)
          .expand((node) => node.children)
          .where((edge) => edge.childProductionLine != edge.childNode),
    );
