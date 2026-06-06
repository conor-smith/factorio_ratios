import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/stateful.dart';

class Graph implements BasePlannerElement<GraphState, GraphEvent> {
  final BasePlanner basePlanner;

  @override
  final int id;

  final EventNotifier<GraphEvent> _notifier = EventNotifier();
  late GraphState _state;

  Graph(this.basePlanner) : id = BasePlannerElement.generateId() {
    basePlanner.initialiseGraph(this);
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
  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class GraphStateBuilder implements Builder<GraphState>, GraphState {
  GraphStateBuilder();
  GraphStateBuilder.from(GraphState state);

  @override
  GraphState build() {
    // TODO: implement build
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class GraphEvent {}
