import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/change_tracker/change_trackers.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/edge_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/factorio/base_planner/node/node.dart';
import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/utility/json.dart';

part 'edge_state.dart';

/// Represents an edge connecting two [NodeElement]s.
/// Items flow from [childProdLine] to [parentProdLine].
class Edge extends BasePlannerElement<EdgeStateImpl, EdgeEvent> {
  @override
  final Graph parentGraph;
  final EdgeType edgeType;
  final NodeElement parentNode;
  final NodeElement childNode;

  /// This node is the node that items will actually go to.
  /// It will typically be the same as [parentNode], unless [parentNode] is a [Graph],
  /// in which case, it will be a relevant node of type [NodeType.input].
  final ProdLineNode parentProdLine;

  /// This node is the node that items will actually come from.
  /// It will typically be the same as [childNode], unless [childNode] is a [Graph],
  /// in which case, it will be a relevant node of type [NodeType.output].
  final ProdLineNode childProdLine;
  final InGameItem item;

  EdgeStateImpl _internalState;

  // For convenience
  double get percentage => _state.percentage;
  int get parentPriority => _state.parentPriority;
  int get childPriority => _state.childPriority;
  @override
  EdgeGeometryImpl get geometry => _state.geometry;

  double get amount => _state.amount;

  Edge.addToBasePlanner(
    super.basePlanner, {
    required this.parentGraph,
    required this.edgeType,
    required this.parentNode,
    required this.childNode,
    required this.item,
  }) : parentProdLine = parentNode.getInputItemNode(item),
       childProdLine = childNode.getOutputItemNode(item),
       _internalState = EdgeStateImpl.uninitialised {
    if (!parentNode.nodeType.permittedChildren.contains(edgeType)) {
      throw EdgeException(
        'Node of type ${parentNode.nodeType} cannot have child of type $edgeType',
      );
    } else if (!childNode.nodeType.permittedParents.contains(edgeType)) {
      throw EdgeException(
        'Node of type ${childNode.nodeType} cannot have a child of type $edgeType',
      );
    } else if (parentNode == childNode) {
      throw const EdgeException('A node may not consume it\'s own output');
    }

    EdgeChangeTracker.newEdge(
      this,
      _internalState,
      EdgeStateBuilder.initial(this),
    );
  }

  EdgeState get _state =>
      basePlanner.snapshotBuilder?.edgeTrackers[this]?.state ?? _internalState;

  @override
  void updateState(EdgeStateImpl newState) {
    basePlanner.throwIfMutationNotPermitted();
    _internalState = newState;
  }

  @override
  EdgeChangeTracker getChangeTracker() => basePlanner
      .getSnapshotBuilderOrThrow()
      .getEdgeChangeTracker(this, _internalState);

  @override
  EdgeStateBuilder getStateBuilder() => getChangeTracker().stateBuilder;

  @override
  void notifyListenersOfGeometryUpdate(EdgeGeometry geometry) =>
      notifyListeners(EdgeEvent.geometryOp(geometry));

  @override
  void notifyListenersOfUpdate() {
    notifyListeners(const EdgeEvent());
  }

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class EdgeEvent {
  final EdgeGeometry? geometry;

  EdgeEvent.geometryOp(EdgeGeometry this.geometry);

  const EdgeEvent() : geometry = null;
}

class EdgeDependencies implements Dependencies {
  final ProdLineNode? parentProdLineDep;
  final List<Edge>? orderedParentEdgeDeps;

  final ProdLineNode? childProdLineDep;
  final List<Edge>? orderedChildEdgeDeps;

  EdgeDependencies({
    this.parentProdLineDep,
    List<Edge>? parentEdgeDeps,
    this.childProdLineDep,
    List<Edge>? childEdgeDeps,
  }) : orderedParentEdgeDeps = parentEdgeDeps,
       orderedChildEdgeDeps = childEdgeDeps {
    orderedParentEdgeDeps?.sort(
      (preEdge1, preEdge2) =>
          preEdge1.parentPriority.compareTo(preEdge2.parentPriority),
    );
    orderedChildEdgeDeps?.sort(
      (creEdge1, creEdge2) =>
          creEdge1.childPriority.compareTo(creEdge2.childPriority),
    );
  }

  @override
  Iterable<BasePlannerElement> get allElements => <BasePlannerElement?>[
    parentProdLineDep,
    childProdLineDep,
    ...?orderedParentEdgeDeps,
    ...?orderedChildEdgeDeps,
  ].nonNulls;
}

enum EdgeType {
  // TODO: Document
  requestItems,

  // TODO: Document
  pushExcess,

  // TODO: Document
  requestExcess,
}

class EdgeException extends BasePlannerException {
  const EdgeException(super.message, [super.cause]);
}
