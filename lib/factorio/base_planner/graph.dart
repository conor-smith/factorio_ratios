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
      basePlanner.getGraphStateBuilder(parentGraph!).childGraphs.add(this);
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

  @override
  final Set<Node> nodes;
  @override
  final Set<Edge> edges;
  @override
  final Set<Graph> childGraphs;

  factory GraphStateBuilder.from(GraphState state) {
    if (state is GraphStateBuilder) {
      return state;
    } else {
      return GraphStateBuilder._from(state);
    }
  }

  GraphStateBuilder._from(GraphState state)
    : _graph = state._graph,
      nodes = Set.from(state.nodes),
      edges = Set.from(state.edges),
      childGraphs = Set.from(state.childGraphs);

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
