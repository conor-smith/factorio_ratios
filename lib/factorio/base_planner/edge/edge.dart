import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/edge_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/factorio/base_planner/node/node.dart';
import 'package:factorio_ratios/factorio/base_planner/state_builders/state_builders.dart';
import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/json/json.dart';

part 'edge_state.dart';

/// Represents an edge connecting two [NodeElement]s.
/// Items flow from child to parent
class Edge
    with EventNotifier<EdgeEvent>
    implements BasePlannerElement<EdgeState, EdgeEvent> {
  @override
  final BasePlanner basePlanner;

  @override
  final Graph parentGraph;
  final EdgeType edgeType;
  final NodeElement parent;
  final NodeElement child;

  /// This node is the node that items will actually come from / go to.
  /// It will typically be the same as [parent], unless [parent] is a [Graph],
  /// in which case, it will be the relevant IoNode.
  final NodeElement parentItemNode;

  /// This node is the node that items will actually come from / go to.
  /// It will typically be the same as [child], unless [child] is a [Graph],
  /// in which case, it will be the relevant IoNode.
  final NodeElement childItemNode;
  final InGameItem item;

  EdgeStateImpl _state;
  EdgeStateBuilder? _builder;

  // For convenience
  double? get amount => state.amount;
  double get percentage => state.percentage;
  EdgeGeometryImpl get edgeGeometry => state.edgeGeometry;

  Edge.addToBasePlanner({
    required this.basePlanner,
    required this.parentGraph,
    required this.edgeType,
    required this.parent,
    required this.child,
    required this.item,
    double percentage = 1.0,
    double? initialAmount,
    EdgeGeometryImpl edgeGeometry = EdgeGeometryImpl.uninitialised,
  }) : parentItemNode = switch (edgeType) {
         EdgeType.requestItems => parent.getInputItemNode(item),
         EdgeType.pushExcess => parent.getOutputItemNode(item),
       },
       childItemNode = switch (edgeType) {
         EdgeType.requestItems => child.getOutputItemNode(item),
         EdgeType.pushExcess => child.getInputItemNode(item),
       },
       _state = EdgeStateImpl._initial(
         amount: initialAmount,
         percentage: percentage,
         edgeGeometry: edgeGeometry,
       ) {
    if (parent.parentGraph != parentGraph) {
      throw EdgeException(
        'Edge with parentGraph $parentGraph cannot connect to parent node $parent with different parentGraph ${parent.parentGraph}',
      );
    } else if (child.parentGraph != parentGraph) {
      throw EdgeException(
        'Edge with parentGraph $parentGraph cannot connect to child node $parent with different parentGraph ${parent.parentGraph}',
      );
    }

    _builder = EdgeStateBuilder.from(this, _state);
    _builder!.addSelf();
  }

  @override
  EdgeState get state => _builder ?? _state;
  @override
  set state(EdgeStateImpl state) {
    basePlanner.throwIfMutationNotPermitted();
    _builder = null;
    _state = state;
  }

  @override
  EdgeStateBuilder getStateBuilder() {
    _builder ??= EdgeStateBuilder.from(this, _state);

    return _builder!;
  }

  @override
  void cancelStateBuilder() => _builder = null;

  @override
  bool get isSelected => basePlanner.selectedElements.contains(this);

  @override
  void select() => basePlanner.selectElement(this);

  @override
  void deselect() => basePlanner.deselectElement(this);

  @override
  void notifyListenersOfGeometryUpdate(EdgeGeometry edgeGeometry) =>
      notifyListeners(EdgeEvent.geometryOp(edgeGeometry));

  @override
  void notifyListenersOfStateUpdate(
    EdgeStateImpl oldState,
    EdgeStateImpl newState,
  ) {
    if (oldState.edgeGeometry != newState.edgeGeometry) {
      notifyListeners(EdgeEvent.geometryOp(edgeGeometry));
    }
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
  /// Parent is requesting items from child
  requestItems,

  /// Child is pushing excess items onto parent
  pushExcess,
}

class EdgeException extends BasePlannerException {
  const EdgeException(super.message, [super.cause]);
}
