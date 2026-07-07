import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/edge_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/factorio/base_planner/node/node.dart';
import 'package:factorio_ratios/factorio/base_planner/state_builders/state_builders.dart';
import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/json/json.dart';

part 'edge_state.dart';

/// Represents an edge connecting two [NodeElement]s.
/// Items flow from [childProdLine] to [parentProdLine].
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
  final ProdLineNode parentProdLine;

  /// This node is the node that items will actually come from.
  /// It will typically be the same as [child], unless [child] is a [Graph],
  /// in which case, it will be a relevant node of type [NodeType.output].
  final ProdLineNode childProdLine;
  final InGameItem item;

  EdgeStateImpl _state;
  EdgeStateBuilder? _builder;

  // For convenience
  double get percentage => state.percentage;
  int get parentPriority => state.parentPriority;
  int get childPriority => state.childPriority;
  @override
  EdgeGeometryImpl get geometry => state.geometry;

  double get amount => state.amount;

  Edge.addToBasePlanner({
    required this.basePlanner,
    required this.parentGraph,
    required this.edgeType,
    required this.parent,
    required this.child,
    required this.item,
  }) : parentProdLine = parent.getInputItemNode(item),
       childProdLine = child.getOutputItemNode(item),
       _state = EdgeStateImpl.uninitialised {
    if (!parent.nodeType.permittedChildren.contains(edgeType)) {
      throw EdgeException(
        'Node of type ${parent.nodeType} cannot have child of type $edgeType',
      );
    } else if (!child.nodeType.permittedParents.contains(edgeType)) {
      throw EdgeException(
        'Node of type ${child.nodeType} cannot have a child of type $edgeType',
      );
    } else if (parent == child) {
      throw const EdgeException('A node may not consume it\'s own output');
    }

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
  List<BasePlannerElement> traverseDependencyTreeAndReturnQueue(
    List<BasePlannerElement> orderedDependencies,
    Set<BasePlannerElement> visitedDependants,
  ) {
    // TODO: implement getOrderedDependencies
    throw UnimplementedError();
  }

  @override
  Dependencies determineDependencies() {
    // TODO: implement determineDependencies
    throw UnimplementedError();
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

class EdgeDependencies implements Dependencies {}

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
