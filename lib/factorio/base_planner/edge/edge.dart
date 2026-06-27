import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/edge_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/factorio/base_planner/node/node.dart';
import 'package:factorio_ratios/factorio/base_planner/state_builders/state_builders.dart';
import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/json/json.dart';

part 'edge_state.dart';

/// Represents an edge connecting two [NodeElement]s.
/// Items flow from [childProdLineNode] to [parentProdLineNode].
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

  /// This node is the node that items will actually go to.
  /// It will typically be the same as [parent], unless [parent] is a [Graph],
  /// in which case, it will be a relevant node of type [NodeType.input].
  final ProdLineNode parentProdLineNode;

  /// This node is the node that items will actually come from.
  /// It will typically be the same as [child], unless [child] is a [Graph],
  /// in which case, it will be a relevant node of type [NodeType.output].
  final ProdLineNode childProdLineNode;
  final InGameItem item;

  EdgeStateImpl _state;
  EdgeStateBuilder? _builder;

  // For convenience
  double get amount => state.amount;
  double get percentage => state.percentage;
  int get priority => state.priority;
  @override
  EdgeGeometryImpl get geometry => state.geometry;

  Edge.addToBasePlanner({
    required this.basePlanner,
    required this.parentGraph,
    required this.edgeType,
    required this.parent,
    required this.child,
    required this.item,
  }) : parentProdLineNode = parent.getInputItemNode(item),
       childProdLineNode = child.getOutputItemNode(item),
       _state = EdgeStateImpl.uninitialised {
    _builder = EdgeStateBuilder.initial(this);
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
  void notifyListenersOfGeometryUpdate(EdgeGeometry geometry) =>
      notifyListeners(EdgeEvent.geometryOp(geometry));

  @override
  void notifyListenersOfStateUpdate(
    EdgeStateImpl oldState,
    EdgeStateImpl newState,
  ) {
    if (oldState.geometry != newState.geometry) {
      notifyListeners(EdgeEvent.geometryOp(geometry));
    }
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
}

enum EdgeType {
  /// Represents a parent requesting [Edge.amount] from a child.
  ///
  /// The total [Edge.percentage] sum of all child edges with the same [Edge.item]
  /// must add up to 1.
  /// If they do not, new edges will be created and connected a node in same
  /// graph that can output this item.
  /// If no node exists, a new node will also be created
  requestItems(false, false),

  /// Represents a parent requesting [Edge.amount] from a child, but the child
  /// can "refuse" and set a max amount if need be.
  ///
  /// TODO - Document more
  deferRequestItems(true, false),

  /// Child is pushing excess items onto parent.
  ///
  /// The total [Edge.percentage] sum of all child edges with the same [Edge.item]
  /// must add up to 1.
  /// If they do not, new edges will be created and connected a node in same
  /// graph that can output this item.
  /// If no node exists, a new node will also be created
  pushExcess(false, true),

  /// Represents a child pushing [Edge.amount] onto a parent, but the parent
  /// can "refuse" and set a max amount if need be.
  ///
  /// TODO - Document more
  deferPushExcess(true, true);

  /// Uses [Edge.priority] if true, [Edge.percentage] otherwise
  final bool usesPriority;

  /// Sets constraints on [Edge.parent] if true, on [Edge.child] otherwise
  final bool constrainsParents;

  const EdgeType(this.usesPriority, this.constrainsParents);
}

// TODO - Document
enum RequestStatus {
  /// Request is still pending on some other operation
  pending,

  /// Request is known but has not yet been applied to relevant node
  known,

  /// Request is known and applied
  done,
}

class EdgeException extends BasePlannerException {
  const EdgeException(super.message, [super.cause]);
}
