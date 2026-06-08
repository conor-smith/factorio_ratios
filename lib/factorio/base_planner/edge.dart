import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/edge_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/graph.dart';
import 'package:factorio_ratios/factorio/base_planner/production_line_node.dart';
import 'package:factorio_ratios/factorio/base_planner/stateful.dart';
import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';

class Edge implements BasePlannerElement<EdgeState, EdgeEvent> {
  final BasePlanner basePlanner;

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
  Graph get parentNodeGraph => parentProductionLine.parentGraph;
  Graph get childNodeGraph => childProductionLine.parentGraph;
  double? get amount => _state.amount;
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

    // If either attached nodes are ioNodes of a graphNode, we must update their state
    // This is because adding this edge will affect the parents and children fields
    if (parentProductionLine.parentGraph != parentGraph) {
      basePlanner.getGraphStateBuilder(parentProductionLine.parentGraph);
    }
    if (childProductionLine.parentGraph != parentGraph) {
      basePlanner.getGraphStateBuilder(childProductionLine.parentGraph);
    }
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

  final EdgeGeometry edgeGeometry;

  EdgeState({this.amount, this.edgeGeometry = EdgeGeometry.uninitialised});

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class EdgeStateBuilder implements Builder<EdgeState>, EdgeState {
  final Edge _edge;

  double? _amount;
  EdgeGeometry _edgeGeometry;

  @override
  double? get amount => _amount;
  @override
  EdgeGeometry get edgeGeometry => _edgeGeometry;

  EdgeStateBuilder.from(Edge edge)
    : _edge = edge,
      _amount = edge.amount,
      _edgeGeometry = edge.edgeGeometry;

  void updateAmount(double amount) => _amount = amount;
  void clearAmount() => _amount = 0;

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
