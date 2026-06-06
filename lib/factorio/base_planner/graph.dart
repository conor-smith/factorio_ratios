import 'dart:collection';

import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/edge.dart';
import 'package:factorio_ratios/factorio/base_planner/node.dart';
import 'package:factorio_ratios/factorio/base_planner/stateful.dart';
import 'package:factorio_ratios/factorio/models/models.dart';

class Graph implements BasePlannerElement<GraphState, GraphEvent> {
  final BasePlanner basePlanner;

  final Surface? surface;
  final Graph? parentGraph;

  @override
  final int id;

  final EventNotifier<GraphEvent> _notifier = EventNotifier();
  late GraphState _state;

  Graph({required this.basePlanner, this.surface, this.parentGraph})
    : id = BasePlannerElement.generateId() {
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
  }

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class GraphState implements ElementState {
  final Graph _graph;

  final Set<Node> nodes;
  final Set<Edge> edges;
  final Set<Graph> childGraphs;

  GraphState(
    Graph graph, {
    Iterable<Node> nodes = const {},
    Iterable<Edge> edges = const {},
    Iterable<Graph> childGraphs = const {},
  }) : _graph = graph,
       nodes = Set.unmodifiable(nodes),
       edges = Set.unmodifiable(edges),
       childGraphs = Set.unmodifiable(childGraphs) {
    // TODO: Validation
  }

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class GraphStateBuilder implements Builder<GraphState>, GraphState {
  @override
  final Graph _graph;

  final Set<Node> _nodes;
  final Set<Edge> _edges;
  final Set<Graph> _childGraphs;

  @override
  late final Set<Node> nodes = UnmodifiableSetView(_nodes);
  @override
  late final Set<Edge> edges = UnmodifiableSetView(_edges);
  @override
  late final Set<Graph> childGraphs = UnmodifiableSetView(_childGraphs);

  factory GraphStateBuilder.from(GraphState state) {
    if (state is GraphStateBuilder) {
      return state;
    } else {
      return GraphStateBuilder._from(state);
    }
  }

  GraphStateBuilder._from(GraphState state)
    : _graph = state._graph,
      _nodes = Set.from(state.nodes),
      _edges = Set.from(state.edges),
      _childGraphs = Set.from(state.childGraphs);

  void addNode(Node node) => _nodes.add(node);
  void removeNode(Node node) => _nodes.remove(node);

  void addEdge(Edge edge) => _edges.add(edge);
  void removeEdge(Edge edge) => _edges.remove(edge);

  void addChildGraph(Graph childGraph) => _childGraphs.add(childGraph);
  void removeChildGraph(Graph childGraph) => _childGraphs.remove(childGraph);

  @override
  GraphState build() =>
      GraphState(_graph, nodes: nodes, edges: edges, childGraphs: childGraphs);

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class GraphEvent {}

class GraphException extends BasePlannerException {
  const GraphException(super.message, [super.cause]);
}
