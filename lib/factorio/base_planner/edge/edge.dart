import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/edge_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/factorio/base_planner/node/node.dart';
import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/json/json.dart';

class Edge implements BasePlannerElement<EdgeState, EdgeEvent> {
  final BasePlanner _basePlanner;

  @override
  final int id;

  final Graph parentGraph;
  final EdgeType edgeType;
  final ProdLineNode parentProductionLine;
  final ProdLineNode childProductionLine;
  final NodeElement parent;
  final NodeElement child;
  final InGameItem item;

  final EventNotifier<EdgeEvent> _notifier = EventNotifierImpl();
  EdgeState _state;
  EdgeStateBuilder? _builder;

  // For convenience
  double? get amount => state.amount;
  double get percentage => state.percentage;
  EdgeGeometry get edgeGeometry => state.edgeGeometry;

  factory Edge({
    required BasePlanner basePlanner,
    required Graph parentGraph,
    required EdgeType edgeType,
    required NodeElement parent,
    required NodeElement child,
    required InGameItem item,
    double percentage = 1.0,
  }) {
    ProdLineNode parentProdLine;
    ProdLineNode childProdLine;

    if (parent is ProdLineNode) {
      parentProdLine = parent;
    } else {
      var parentGraph = parent as Graph;

      parentProdLine = switch (edgeType) {
        EdgeType.requestItems => _findInputNodeForItem(parentGraph, item),
        EdgeType.acceptExcess => _findOutputNodeForItem(parentGraph, item),
      };
    }

    if (child is ProdLineNode) {
      childProdLine = child;
    } else {
      var childGraph = child as Graph;

      childProdLine = switch (edgeType) {
        EdgeType.requestItems => _findOutputNodeForItem(childGraph, item),
        EdgeType.acceptExcess => _findInputNodeForItem(childGraph, item),
      };
    }

    var edge = Edge._(
      basePlanner: basePlanner,
      parentGraph: parentGraph,
      edgeType: edgeType,
      parent: parent,
      child: child,
      parentProductionLine: parentProdLine,
      childProductionLine: childProdLine,
      item: item,
      percentage: percentage,
    );

    var builder = EdgeStateBuilder._from(edge);
    edge._builder = builder;
    basePlanner.getSnapshotBuilder().addToSnapsnot(edge, builder);

    parent.getStateBuilder().addChild(edge);
    parentProdLine.getStateBuilder().addChild(edge);

    child.getStateBuilder().addParent(edge);
    childProdLine.getStateBuilder().addParent(edge);

    return edge;
  }

  Edge._({
    required BasePlanner basePlanner,
    required this.parentGraph,
    required this.edgeType,
    required this.parent,
    required this.child,
    required this.parentProductionLine,
    required this.childProductionLine,
    required this.item,
    required double percentage,
  }) : _basePlanner = basePlanner,
       id = BasePlannerElement.generateId(),
       _state = EdgeState._(percentage: percentage);

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
    required this.percentage,
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
  EdgeState build() => EdgeState._(
    amount: amount,
    percentage: _percentage,
    edgeGeometry: _edgeGeometry,
  );

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

class EdgeException extends BasePlannerException {
  const EdgeException(super.message, [super.cause]);
}

ProdLineNode _findInputNodeForItem(Graph graph, InGameItem item) {
  if (!graph.inputItems.contains(item)) {
    throw EdgeException('Graph $graph contains no input node for item $item');
  } else {
    return graph.prodLineNodes.firstWhere(
      (node) =>
          node.nodeType == NodeType.input && node.inputItems.contains(item),
    );
  }
}

ProdLineNode _findOutputNodeForItem(Graph graph, InGameItem item) {
  if (!graph.outputItems.contains(item)) {
    throw EdgeException('Graph $graph contains no output node for item $item');
  } else {
    return graph.prodLineNodes.firstWhere(
      (node) =>
          node.nodeType == NodeType.output && node.outputItems.contains(item),
    );
  }
}
