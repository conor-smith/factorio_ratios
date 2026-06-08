import 'dart:collection';

import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/edge.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/node_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/production_line_node.dart';
import 'package:factorio_ratios/factorio/base_planner/stateful.dart';
import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/factorio/models/models.dart';
import 'package:factorio_ratios/factorio/production_lines/production_line.dart';

class Graph implements BasePlannerElement<GraphState, GraphEvent>, Node {
  final BasePlanner basePlanner;
  late final Function(Function) newSnapshotFunction;

  @override
  final int id;

  final Surface? surface;

  @override
  final Graph? parentGraph;
  @override
  NodeGeometry get nodeGeometry => _state.nodeGeometry;
  @override
  Set<Edge> get parents => _state.parents;
  @override
  Set<Edge> get children => _state.children;
  @override
  GraphIo? get io => _state.io;

  final EventNotifier<GraphEvent> _notifier = EventNotifier();
  late GraphState _state;

  // For convenience
  Set<ProductionLineNode> get productionLineNodes => _state.productionLineNodes;
  Set<Graph> get graphNodes => _state.graphNodes;
  Set<Edge> get edges => _state.edges;

  Graph({required this.basePlanner, this.surface, this.parentGraph})
    : id = BasePlannerElement.generateId() {
    // TODO: verification
    _state = GraphState();
    basePlanner.initialiseGraph(this);

    if (parentGraph != null) {
      basePlanner.getGraphStateBuilder(parentGraph!).addChildGraph(this);
    }
  }

  @override
  GraphState get state => _state;
  @override
  set state(GraphState state) {
    basePlanner.throwIfMutationNotPermitted();

    // TODO: verification
    _state = state;
  }

  void addConsumerNodeAndTree(InGameItem item) {}

  @override
  bool get hasCallback => _notifier.hasCallback;
  @override
  set eventCallback(Function(GraphEvent event) callback) =>
      _notifier.eventCallback = callback;
  @override
  void clearCallback() => _notifier.clearCallback();
  @override
  void notifyListener(GraphEvent event) => _notifier.notifyListener(event);

  @override
  void notifyListenerOfStateChange(
    ElementState oldState,
    ElementState newState,
  ) {
    // TODO: implement notifyListenerOfStateChange
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

abstract class Node {
  Graph? get parentGraph;

  ProductionLineIo? get io;
  NodeGeometry get nodeGeometry;

  Set<Edge> get parents;
  Set<Edge> get children;
}

class GraphState implements ElementState {
  final Set<ProductionLineNode> productionLineNodes;
  final Set<Graph> graphNodes;
  final Set<Edge> edges;

  final NodeGeometry nodeGeometry;

  final Set<Edge>? _cachedParents;
  final Set<Edge>? _cachedChildren;
  final GraphIo? _cachedIo;

  // All following fields are derived from above fields
  // They are calculated and cached when required
  // However, some of the values are affected by the state of other objects
  // Eg. parents is modified if parentGraph gets a new edge connecting to an IO node
  // If parents was already calculated and cached before then, the value will be incorrect
  // The builder fields always recalculate these derived values
  // As such, when a state change affects these fields, we must call
  // basePlanner.getGraphStateBuilder on this graph too in order to ensure fields remain correct
  // All element interactions are documented

  // Affected whenever io data in any prodlineNode, here or within descendent graphs, is updated
  late final GraphIo io = _cachedIo ?? GraphIo.calculateIo(this);

  // Affected whenever parentGraph gets a new edge connecting to an IO node
  late final Set<Edge> parents =
      _cachedParents ??
      Set.unmodifiable(
        productionLineNodes
            .where((node) => node.nodeType.isIo)
            .expand((node) => node.parents)
            .where((edge) => edge.parentProductionLine != edge.parentNode),
      );
  // Affected whenever parentGraph gets a new edge connecting to an IO node
  late final Set<Edge> children =
      _cachedChildren ??
      Set.unmodifiable(
        productionLineNodes
            .where((node) => node.nodeType.isIo)
            .expand((node) => node.children)
            .where((edge) => edge.childProductionLine != edge.childNode),
      );

  GraphState({
    Iterable<ProductionLineNode> productionLineNodes = const {},
    Iterable<Graph> graphNodes = const {},
    Iterable<Edge> edges = const {},
    this.nodeGeometry = NodeGeometry.uninitialised,
    Set<Edge>? cachedParents,
    Set<Edge>? cachedChildren,
    GraphIo? cachedIo,
  }) : productionLineNodes = Set.unmodifiable(productionLineNodes),
       graphNodes = Set.unmodifiable(graphNodes),
       edges = Set.unmodifiable(edges),
       _cachedParents = cachedParents != null
           ? Set.unmodifiable(cachedParents)
           : null,
       _cachedChildren = cachedChildren != null
           ? Set.unmodifiable(cachedChildren)
           : null,
       _cachedIo = cachedIo;

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class GraphStateBuilder implements Builder<GraphState>, GraphState {
  final BasePlanner _basePlanner;

  final Set<ProductionLineNode> _prodLineNodes;
  final Set<Edge> _edges;
  final Set<Graph> _graphNodes;
  NodeGeometry _nodeGeometry;

  @override
  Set<Edge>? _cachedParents;
  @override
  Set<Edge>? _cachedChildren;
  @override
  GraphIo? _cachedIo;

  @override
  late final Set<ProductionLineNode> productionLineNodes = UnmodifiableSetView(
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
    _cachedIo ??= GraphIo.calculateIo(this);

    return _cachedIo!;
  }

  @override
  Set<Edge> get parents {
    _cachedParents ??= Set.unmodifiable(
      _prodLineNodes
          .where((node) => node.nodeType.isIo)
          .expand((node) => node.parents)
          .where((edge) => edge.parentProductionLine != edge.parentNode),
    );

    return _cachedParents!;
  }

  @override
  Set<Edge> get children {
    _cachedChildren = Set.unmodifiable(
      _prodLineNodes
          .where((node) => node.nodeType.isIo)
          .expand((node) => node.children)
          .where((edge) => edge.childProductionLine != edge.childNode),
    );
    return _cachedChildren!;
  }

  GraphStateBuilder.from(Graph graph)
    : _basePlanner = graph.basePlanner,
      _prodLineNodes = Set.from(graph.productionLineNodes),
      _edges = Set.from(graph.edges),
      _graphNodes = Set.from(graph.graphNodes),
      _nodeGeometry = graph.nodeGeometry,
      _cachedParents = graph._state._cachedParents,
      _cachedChildren = graph._state._cachedChildren,
      _cachedIo = graph._state._cachedIo;

  void addNode(ProductionLineNode node) => _prodLineNodes.add(node);
  void removeNode(ProductionLineNode node) => _prodLineNodes.remove(node);

  void addEdge(Edge edge) {
    _edges.add(edge);

    if (_graphNodes.contains(edge.parentNode)) {
      _basePlanner
          .getGraphStateBuilder(edge.parentNode as Graph)
          .clearCachedChildren();
    }
    if (_graphNodes.contains(edge.childNode)) {
      _basePlanner
          .getGraphStateBuilder(edge.childNode as Graph)
          .clearCachedParents();
    }
  }

  void removeEdge(Edge edge) {
    _edges.remove(edge);

    if (_graphNodes.contains(edge.parentNode)) {
      _basePlanner
          .getGraphStateBuilder(edge.parentNode as Graph)
          .clearCachedChildren();
    }
    if (_graphNodes.contains(edge.childNode)) {
      _basePlanner
          .getGraphStateBuilder(edge.childNode as Graph)
          .clearCachedParents();
    }
  }

  void addChildGraph(Graph childGraph) => _graphNodes.add(childGraph);
  void removeChildGraph(Graph childGraph) => _graphNodes.remove(childGraph);

  void updateGeometry(NodeGeometry nodeGeometry) =>
      _nodeGeometry = nodeGeometry;

  void clearCachedParents() => _cachedParents = null;
  void clearCachedChildren() => _cachedChildren = null;
  void clearCachedIo() => _cachedIo = null;

  @override
  GraphState build() => GraphState(
    productionLineNodes: _prodLineNodes,
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

class GraphIo extends ProductionLineIo {
  factory GraphIo.calculateIo(GraphState graphState) {
    // TODO
    throw UnimplementedError();
  }

  GraphIo({required super.netOutput, required super.netInput});
}

class GraphEvent {}

class GraphException extends BasePlannerException {
  const GraphException(super.message, [super.cause]);
}
