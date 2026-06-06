import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/stateful.dart';

class Graph implements BasePlannerElement<GraphState, GraphEvent> {
  final BasePlanner basePlanner;

  @override
  final int id;

  final EventNotifier<GraphEvent> _notifier = EventNotifier();
  GraphState _state;

  Graph(this.basePlanner)
    : id = BasePlannerElement.generateId(),
      _state = GraphState.uninitialised;

  @override
  GraphState get state => _state;
  @override
  set state(GraphState state) {
    // TODO: implement state setter
  }

  @override
  bool get hasCallback => _notifier.hasCallback;
  @override
  set eventCallback(Function(GraphEvent event) callback) =>
      _notifier.eventCallback = callback;
  @override
  void clearCallback() => _notifier.clearCallback();
  @override
  void notifyListener(event) => _notifier.notifyListener(event);

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
  static const uninitialised = GraphState();

  const GraphState();

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class GraphStateBuilder implements Builder<GraphState>, GraphState {
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
