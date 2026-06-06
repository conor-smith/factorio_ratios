import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/stateful.dart';

class Node implements BasePlannerElement<NodeState, NodeEvent> {
  final BasePlanner basePlanner;

  @override
  final int id;

  final EventNotifier<NodeEvent> _notifier = EventNotifier();
  NodeState _state;

  Node(this.basePlanner)
    : id = BasePlannerElement.generateId(),
      _state = NodeState.uninitialised;

  @override
  NodeState get state => _state;
  @override
  set state(NodeState state) {
    // TODO: implement state setter
  }

  @override
  bool get hasCallback => _notifier.hasCallback;
  @override
  set eventCallback(Function(NodeEvent event) callback) =>
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

class NodeState implements ElementState {
  static const uninitialised = NodeState();

  const NodeState();

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class NodeStateBuilder implements Builder<NodeState>, NodeState {
  @override
  NodeState build() {
    // TODO: implement build
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class NodeEvent {}
