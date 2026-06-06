import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/edge.dart';
import 'package:factorio_ratios/factorio/base_planner/graph.dart';
import 'package:factorio_ratios/factorio/base_planner/stateful.dart';
import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/factorio/production_lines/production_line.dart';

class Node implements BasePlannerElement<NodeState, NodeEvent> {
  final BasePlanner basePlanner;

  @override
  final int id;

  final Graph parentGraph;
  final NodeType nodeType;

  final EventNotifier<NodeEvent> _notifier = EventNotifier();
  late NodeState _state;

  Node({
    required this.basePlanner,
    required this.parentGraph,
    required this.nodeType,
    required ProductionLine productionLine,
  }) : id = BasePlannerElement.generateId() {
    _state = NodeState(node: this, productionLine: productionLine);
    basePlanner.initialiseNode(this);

    basePlanner.getGraphStateBuilder(parentGraph).nodes.add(this);
  }

  @override
  NodeState get state => _state;
  @override
  set state(NodeState state) {
    basePlanner.throwIfMutationNotPermitted();
    _state = state;
  }

  @override
  bool get hasCallback => _notifier.hasCallback;
  @override
  set eventCallback(Function(NodeEvent event) callback) =>
      _notifier.eventCallback = callback;
  @override
  void clearCallback() => _notifier.clearCallback();
  @override
  void notifyListener(NodeEvent event) => _notifier.notifyListener(event);

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
  final Node _node;

  final ItemAmounts? requiredInput;
  final ItemAmounts? requiredOutput;

  final ProductionLine productionLine;
  final ProductionLineIo? io;

  final Set<Edge> parents;
  final Set<Edge> children;

  NodeState({
    required Node node,
    ItemAmounts? requiredInput,
    ItemAmounts? requiredOutput,
    required this.productionLine,
    this.io,
    Iterable<Edge> parents = const {},
    Iterable<Edge> children = const {},
  }) : _node = node,
       requiredInput = requiredInput != null
           ? Map.unmodifiable(requiredInput)
           : null,
       requiredOutput = requiredOutput != null
           ? Map.unmodifiable(requiredOutput)
           : null,
       parents = Set.unmodifiable(parents),
       children = Set.unmodifiable(children) {
    // TODO: Validation
  }

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class NodeStateBuilder implements Builder<NodeState>, NodeState {
  @override
  final Node _node;

  @override
  ItemAmounts? requiredInput;
  @override
  ItemAmounts? requiredOutput;

  @override
  ProductionLine productionLine;
  @override
  ProductionLineIo? io;

  @override
  final Set<Edge> parents;
  @override
  final Set<Edge> children;

  factory NodeStateBuilder.from(NodeState state) {
    if (state is NodeStateBuilder) {
      return state;
    } else {
      return NodeStateBuilder._from(state);
    }
  }

  NodeStateBuilder._from(NodeState state)
    : _node = state._node,
      requiredInput = state.requiredInput != null
          ? Map.from(state.requiredInput!)
          : null,
      requiredOutput = state.requiredOutput != null
          ? Map.from(state.requiredOutput!)
          : null,
      productionLine = state.productionLine,
      io = state.io,
      parents = Set.from(state.parents),
      children = Set.from(state.children);

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

class NodeEvent {
  // TODO
}

enum NodeType {
  consumer,
  producer,
  input,
  output,
  resource,
  disposal,
  productionLine,
}
