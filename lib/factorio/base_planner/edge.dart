import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/edge_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/graph.dart';
import 'package:factorio_ratios/factorio/base_planner/production_line_node.dart';
import 'package:factorio_ratios/factorio/base_planner/stateful.dart';
import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';

class Edge implements BasePlannerElement<EdgeState, EdgeEvent> {
  final BasePlanner basePlanner;
  late final Function(Function) newSnapshotFunction;

  @override
  final int id;

  final Graph parentGraph;
  final EdgeType edgeType;
  final ProductionLineNode parentProductionLine;
  final ProductionLineNode childProductionLine;
  final Node parentNode;
  final Node childNode;
  final InGameItem item;

  final EventNotifier<EdgeEvent> _notifier = EventNotifier();
  late EdgeState _state;

  // For convenience
  double? get amount => _state.amount;
  double get percentage => _state.percentage;
  EdgeGeometry get edgeGeometry => _state.edgeGeometry;

  Edge({
    required this.basePlanner,
    required this.parentGraph,
    required this.edgeType,
    required this.parentProductionLine,
    required this.childProductionLine,
    required this.item,
  }) : id = BasePlannerElement.generateId(),
       parentNode = parentProductionLine.parentGraph == parentGraph
           ? parentProductionLine
           : parentProductionLine.parentGraph,
       childNode = childProductionLine.parentGraph == parentGraph
           ? childProductionLine
           : childProductionLine.parentGraph {
    // TODO: verification
    _state = EdgeState();

    basePlanner.initialiseEdge(this);

    basePlanner.getGraphStateBuilder(parentGraph).addEdge(this);
    basePlanner
        .getProdLineNodeStateBuilder(parentProductionLine)
        .addChild(this);
    basePlanner
        .getProdLineNodeStateBuilder(childProductionLine)
        .addParent(this);
  }

  @override
  EdgeState get state => _state;
  @override
  set state(EdgeState state) {
    basePlanner.throwIfMutationNotPermitted();

    // TODO: verification
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
  final double? amount;
  final double percentage;

  final EdgeGeometry edgeGeometry;

  EdgeState({
    this.amount,
    this.percentage = 1.0,
    this.edgeGeometry = EdgeGeometry.uninitialised,
  });

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class EdgeStateBuilder implements Builder<EdgeState>, EdgeState {
  double? _amount;
  double _percentage;
  EdgeGeometry _edgeGeometry;

  @override
  double? get amount => _amount;
  @override
  double get percentage => _percentage;
  @override
  EdgeGeometry get edgeGeometry => _edgeGeometry;

  EdgeStateBuilder.from(Edge edge)
    : _amount = edge.amount,
      _percentage = edge.percentage,
      _edgeGeometry = edge.edgeGeometry;

  void updateAmount(double amount) => _amount = amount;
  void clearAmount() => _amount = 0;
  void updatePercentage(double percentage) => _percentage = percentage;

  void updateGeometry(EdgeGeometry edgeGeometry) =>
      _edgeGeometry = edgeGeometry;

  @override
  EdgeState build() => EdgeState(amount: amount, edgeGeometry: _edgeGeometry);

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class EdgeEvent {}

enum EdgeType { requestItems, acceptExcess }
