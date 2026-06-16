import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/edge_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/factorio/base_planner/node/node.dart';
import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/json/json.dart';

part 'edge_state.dart';

class Edge implements BasePlannerElement<EdgeState, EdgeEvent> {
  final BasePlanner _basePlanner;

  @override
  final int id;

  @override
  final Graph parentGraph;
  final EdgeType edgeType;
  final ProdLineNode parentProductionLine;
  final ProdLineNode childProductionLine;
  final NodeElement parent;
  final NodeElement child;
  final InGameItem item;

  final EventNotifier<EdgeEvent> _notifier = EventNotifierImpl();
  EdgeStateImpl _state;
  EdgeStateBuilder? _builder;

  // For convenience
  double? get amount => state.amount;
  double get percentage => state.percentage;
  EdgeGeometryImpl get edgeGeometry => state.edgeGeometry;

  factory Edge.addToBasePlanner({
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

    edge._builder = EdgeStateBuilder._new(edge);

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
       _state = EdgeStateImpl._(percentage: percentage, firstState: true);

  @override
  EdgeState get state => _builder ?? _state;
  @override
  set state(EdgeStateImpl state) {
    _basePlanner.throwIfMutationNotPermitted();

    // TODO: validate state, update listeners
    _state = state;
  }

  @override
  void remove() => EdgeStateBuilder._remove(this);

  @override
  EdgeStateBuilder getStateBuilder() {
    _builder ??= EdgeStateBuilder._from(this);

    return _builder!;
  }

  @override
  void cancelStateBuilder() => _builder = null;

  @override
  bool get isSelected => _basePlanner.selectedElements.contains(this);

  @override
  void select() => _basePlanner.selectElement(this);

  @override
  void deselect() => _basePlanner.deselectElement(this);

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
  void notifyListenersOfGeometryUpdate(EdgeGeometry edgeGeometry) =>
      notifyListeners(EdgeEvent.geometryOp(edgeGeometry));

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class EdgeEvent {
  final EdgeGeometry? edgeGeometry;

  EdgeEvent.geometryOp(EdgeGeometry this.edgeGeometry);
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
