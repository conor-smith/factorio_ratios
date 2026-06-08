import 'dart:collection';

import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/edge.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/node_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/production_line_node.dart';
import 'package:factorio_ratios/factorio/base_planner/stateful.dart';
import 'package:factorio_ratios/factorio/models/models.dart';
import 'package:factorio_ratios/factorio/production_lines/production_line.dart';

class Graph implements BasePlannerElement<GraphState, GraphEvent>, Node {
  final BasePlanner basePlanner;

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
    _state = GraphState(this);
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

  late final GraphIo io = GraphIo.calculateIo(this);

  final Set<Edge> parents;
  final Set<Edge> children;

  factory GraphState(
    Graph graph, {
    Iterable<ProductionLineNode> productionLineNodes = const {},
    Iterable<Edge> edges = const {},
    Iterable<Graph> graphNodes = const {},
    NodeGeometry nodeGeometry = NodeGeometry.uninitialised,
  }) {
    Set<Edge> parents = {};
    Set<Edge> children = {};

    for (var ioNode in productionLineNodes.where(
      (node) => node.nodeType.isIo,
    )) {
      parents.addAll(ioNode.parents.where((edge) => edge.parentGraph != graph));
      children.addAll(
        ioNode.children.where((edge) => edge.parentGraph != graph),
      );
    }

    return GraphState._(
      productionLineNodes: Set.unmodifiable(productionLineNodes),
      graphNodes: Set.unmodifiable(graphNodes),
      edges: Set.unmodifiable(edges),
      nodeGeometry: nodeGeometry,
      parents: Set.unmodifiable(parents),
      children: Set.unmodifiable(children),
    );
  }

  GraphState._({
    required this.productionLineNodes,
    required this.graphNodes,
    required this.edges,
    required this.nodeGeometry,
    required this.parents,
    required this.children,
  });

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class GraphStateBuilder implements Builder<GraphState>, GraphState {
  final Graph _graph;

  final Set<ProductionLineNode> _prodLineNodes;
  final Set<Edge> _edges;
  final Set<Graph> _graphNodes;
  NodeGeometry _nodeGeometry;

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
  GraphIo get io => GraphIo.calculateIo(this);

  @override
  Set<Edge> get parents => _prodLineNodes
      .where((node) => node.nodeType.isIo)
      .expand((node) => node.parents)
      .where((edge) => edge.parentNodeGraph != _graph)
      .toSet();
  @override
  Set<Edge> get children => _prodLineNodes
      .where((node) => node.nodeType.isIo)
      .expand((node) => node.children)
      .where((edge) => edge.childNodeGraph != _graph)
      .toSet();

  GraphStateBuilder.from(Graph graph)
    : _graph = graph,
      _prodLineNodes = Set.from(graph.productionLineNodes),
      _edges = Set.from(graph.edges),
      _graphNodes = Set.from(graph.graphNodes),
      _nodeGeometry = graph.nodeGeometry;

  void addNode(ProductionLineNode node) => _prodLineNodes.add(node);
  void removeNode(ProductionLineNode node) => _prodLineNodes.remove(node);

  void addEdge(Edge edge) => _edges.add(edge);
  void removeEdge(Edge edge) => _edges.remove(edge);

  void addChildGraph(Graph childGraph) => _graphNodes.add(childGraph);
  void removeChildGraph(Graph childGraph) => _graphNodes.remove(childGraph);

  void updateGeometry(NodeGeometry nodeGeometry) =>
      _nodeGeometry = nodeGeometry;

  @override
  GraphState build() => GraphState(
    _graph,
    productionLineNodes: _prodLineNodes,
    edges: edges,
    graphNodes: _graphNodes,
    nodeGeometry: _nodeGeometry,
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

  GraphIo._({
    required super.netOutput,
    required super.netInput,
    super.inputConstraints,
    super.outputConstraints,
    super.electricPowerConsumption,
    super.pollution,
    super.displayData,
  });
}

class GraphEvent {}

class GraphException extends BasePlannerException {
  const GraphException(super.message, [super.cause]);
}
