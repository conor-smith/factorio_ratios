import 'package:factorio_ratios/factorio/base_planner/stateful.dart';
import 'package:factorio_ratios/factorio/old_base_planner/base_planner.dart';

class Edge implements BasePlannerElement<EdgeState, EdgeEvent> {
  final BasePlanner basePlanner;

  @override
  final int id;

  final EventNotifier<EdgeEvent> _notifier = EventNotifier();
  EdgeState _state;

  Edge(this.basePlanner)
    : id = BasePlannerElement.generateId(),
      _state = EdgeState.uninitialised;

  @override
  EdgeState get state => _state;
  @override
  set state(EdgeState state) {
    // TODO: implement state setter
  }

  @override
  bool get hasCallback => _notifier.hasCallback;
  @override
  set eventCallback(Function(EdgeEvent event) callback) =>
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

class EdgeState implements ElementState {
  static const uninitialised = EdgeState();

  const EdgeState();

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class EdgeStateBuilder implements Builder<EdgeState>, EdgeState {
  @override
  EdgeState build() {
    // TODO: implement build
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class EdgeEvent {}
