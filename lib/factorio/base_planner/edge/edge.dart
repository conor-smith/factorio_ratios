import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/edge_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/factorio/base_planner/node/node.dart';
import 'package:factorio_ratios/factorio/base_planner/node/production_line_node/production_line_node.dart';
import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/json/json.dart';

part 'edge_state.dart';

class Edge
    with EventNotifier<EdgeEvent>
    implements BasePlannerElement<EdgeState, EdgeEvent> {
  final BasePlanner _basePlanner;

  @override
  final Graph parentGraph;
  final EdgeType edgeType;

  /// This node is the node that items will actually come from / go to.
  /// It will typically be the same as [parent], unless [parent] is a [Graph],
  /// in which case, it will be the relevant IoNode.
  final NodeElement parentItemNode;

  /// This node is the node that items will actually come from / go to.
  /// It will typically be the same as [child], unless [child] is a [Graph],
  /// in which case, it will be the relevant IoNode.
  final NodeElement childItemNode;
  final NodeElement parent;
  final NodeElement child;
  final InGameItem item;

  EdgeStateImpl _state;
  EdgeStateBuilder? _builder;

  // For convenience
  double? get amount => state.amount;
  double get percentage => state.percentage;
  EdgeGeometryImpl get edgeGeometry => state.edgeGeometry;

  Edge.addToBasePlanner({
    required BasePlanner basePlanner,
    required this.parentGraph,
    required this.edgeType,
    required this.parent,
    required this.child,
    required this.item,
    double percentage = 1.0,
  }) : _basePlanner = basePlanner,
       parentItemNode = switch (edgeType) {
         EdgeType.requestItems => parent.getInputItemNode(item),
         EdgeType.acceptExcess => parent.getOutputItemNode(item),
       },
       childItemNode = switch (edgeType) {
         EdgeType.requestItems => child.getOutputItemNode(item),
         EdgeType.acceptExcess => child.getInputItemNode(item),
       },
       _state = EdgeStateImpl._(percentage: percentage) {
    if (parent.parentGraph != parentGraph) {
      throw EdgeException(
        'Edge with parentGraph $parentGraph cannot connect to parent node $parent with different parentGraph ${parent.parentGraph}',
      );
    } else if (child.parentGraph != parentGraph) {
      throw EdgeException(
        'Edge with parentGraph $parentGraph cannot connect to child node $parent with different parentGraph ${parent.parentGraph}',
      );
    }

    _builder = EdgeStateBuilder._new(this);
  }

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
  void notifyListenersOfGeometryUpdate(EdgeGeometry edgeGeometry) =>
      notifyListeners(EdgeEvent.geometryOp(edgeGeometry));

  @override
  void notifyListenersOfStateUpdate(
    EdgeStateImpl oldState,
    EdgeStateImpl newState,
  ) {
    // TODO: implement notifyListenersOfStateUpdate
    throw UnimplementedError();
  }

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

enum EdgeType {
  /// Items flow from child to parent
  requestItems,

  /// Items flow from parent to child
  acceptExcess,
}

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
