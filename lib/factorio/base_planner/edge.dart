import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/graph.dart';
import 'package:factorio_ratios/factorio/base_planner/node.dart';
import 'package:factorio_ratios/factorio/base_planner/stateful.dart';
import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';

class Edge implements BasePlannerElement<EdgeState, EdgeEvent> {
  final BasePlanner basePlanner;

  @override
  final int id;

  final Graph parentGraph;
  final EdgeType edgeType;
  final Node parent;
  final Node child;
  final InGameItem item;

  final EventNotifier<EdgeEvent> _notifier = EventNotifier();
  late EdgeState _state;

  Edge({
    required this.basePlanner,
    required this.parentGraph,
    required this.edgeType,
    required this.parent,
    required this.child,
    required this.item,
  }) : id = BasePlannerElement.generateId() {
    basePlanner.initialiseEdge(this);

    basePlanner.getGraphStateBuilder(parentGraph).edges.add(this);
    basePlanner.getNodeStateBuilder(parent).children.add(this);
    basePlanner.getNodeStateBuilder(child).parents.add(this);
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
  final Edge _edge;

  final double? amount;

  EdgeState(Edge edge, {this.amount}) : _edge = edge {
    // TODO: verification
  }

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class EdgeStateBuilder implements Builder<EdgeState>, EdgeState {
  @override
  final Edge _edge;

  @override
  double? amount;

  factory EdgeStateBuilder.from(EdgeState state) {
    if (state is EdgeStateBuilder) {
      return state;
    } else {
      return EdgeStateBuilder._from(state);
    }
  }

  EdgeStateBuilder._from(EdgeState state)
    : _edge = state._edge,
      amount = state.amount;

  @override
  EdgeState build() => EdgeState(_edge, amount: amount);

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class EdgeEvent {}

enum EdgeType { requestItems, acceptExcess }
