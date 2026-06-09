import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/edge_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/factorio/base_planner/node/node.dart';
import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/json/json.dart';

class Edge
    implements BasePlannerElement<EdgeState, EdgeStateBuilder, EdgeEvent> {
  final BasePlanner _basePlanner;

  @override
  final int id;

  final Graph parentGraph;
  final EdgeType edgeType;
  final ProdLineNode parentProductionLine;
  final ProdLineNode childProductionLine;
  final NodeElement parentNode;
  final NodeElement childNode;
  final InGameItem item;

  final EventNotifier<EdgeEvent> _notifier = EventNotifierImpl();
  EdgeState _state;
  EdgeStateBuilder? _builder;

  // For convenience
  double? get amount => state.amount;
  double get percentage => state.percentage;
  EdgeGeometry get edgeGeometry => state.edgeGeometry;

  Edge({
    required BasePlanner basePlanner,
    required this.parentGraph,
    required this.edgeType,
    required this.parentProductionLine,
    required this.childProductionLine,
    required this.item,
  }) : _basePlanner = basePlanner,
       id = BasePlannerElement.generateId(),
       _state = EdgeState._(),
       parentNode = parentProductionLine.parentGraph == parentGraph
           ? parentProductionLine
           : parentProductionLine.parentGraph,
       childNode = childProductionLine.parentGraph == parentGraph
           ? childProductionLine
           : childProductionLine.parentGraph {
    var builder = EdgeStateBuilder._from(this);

    _basePlanner.getSnapshotBuilder().addToSnapsnot(this, builder);
    _builder = builder;

    parentGraph.getStateBuilder().addEdge(this);

    parentProductionLine.getStateBuilder().addChild(this);
    childProductionLine.getStateBuilder().addParent(this);

    if (parentNode is Graph) {
      (parentNode as Graph).getStateBuilder().clearCachedChildren();
    }
    if (childNode is Graph) {
      (childNode as Graph).getStateBuilder().clearCachedChildren();
    }
  }

  @override
  EdgeState get state => _builder ?? _state;
  @override
  set state(EdgeState state) {
    _basePlanner.throwIfMutationNotPermitted();

    // TODO: validate state
    _state = state;
  }

  @override
  EdgeStateBuilder getStateBuilder() {
    if (_builder == null) {
      var builder = EdgeStateBuilder._from(this);
      _basePlanner.getSnapshotBuilder().addToSnapsnot(this, builder);
      _builder = builder;
    }

    return _builder!;
  }

  @override
  void addListener(Object listener, Function(EdgeEvent event) callback) =>
      _notifier.addListener(listener, callback);
  @override
  void removeListener(Object listener) => _notifier.removeListener(listener);
  @override
  void clearListeners() => _notifier.clearListeners();
  @override
  void notifyListeners(EdgeEvent event) => _notifier.notifyListeners(event);

  @override
  void notifyListenersOfStateChange(EdgeState oldState, EdgeState newState) {
    // TODO: implement notifyListenerOfStateChange
    throw UnimplementedError();
  }

  @override
  void notifyListenersOfGeometryUpdate(EdgeGeometry edgeGeometry) {
    // TODO: implement notifyListenersOfGeometryUpdate
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class EdgeState implements ToJson {
  final double? amount;
  final double percentage;

  final EdgeGeometry edgeGeometry;

  EdgeState._({
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

  EdgeStateBuilder._from(Edge edge)
    : _amount = edge.amount,
      _percentage = edge.percentage,
      _edgeGeometry = edge.edgeGeometry;

  void updateAmount(double amount) => _amount = amount;
  void clearAmount() => _amount = 0;
  void updatePercentage(double percentage) => _percentage = percentage;

  void updateGeometry(EdgeGeometry edgeGeometry) =>
      _edgeGeometry = edgeGeometry;

  @override
  EdgeState build() => EdgeState._(amount: amount, edgeGeometry: _edgeGeometry);

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class EdgeEvent {
  EdgeEvent.geometryOp(EdgeGeometry edgeGeometry) {
    // TODO
    throw UnimplementedError();
  }
}

enum EdgeType { requestItems, acceptExcess }
