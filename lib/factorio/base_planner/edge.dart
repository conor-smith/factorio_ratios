import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/stateful.dart';

class Edge implements BasePlannerElement<EdgeState, EdgeEvent> {
  final BasePlanner basePlanner;

  @override
  final int id;

  final EventNotifier<EdgeEvent> _notifier = EventNotifier();
  late EdgeState _state;

  Edge(this.basePlanner) : id = BasePlannerElement.generateId() {
    basePlanner.initialiseEdge(this);
  }

  @override
  EdgeState get state => _state;
  @override
  set state(EdgeState state) {
    basePlanner.throwIfMutationNotPermitted();
    _state = state;
  }

  @override
  bool get hasCallback => _notifier.hasCallback;
  @override
  set eventCallback(Function(EdgeEvent event) callback) =>
      _notifier.eventCallback = callback;
  @override
  void clearCallback() => _notifier.clearCallback();
  @override
  void notifyListener(EdgeEvent event) => _notifier.notifyListener(event);

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
  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class EdgeStateBuilder implements Builder<EdgeState>, EdgeState {
  EdgeStateBuilder.from(EdgeState state);

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
