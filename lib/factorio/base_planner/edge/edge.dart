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
class Edge extends BasePlannerElement<EdgeState, EdgeEvent> {
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

  EdgeStateImpl _internalState;
  EdgeStateBuilder? _stateBuilder;

  // For convenience
  double get percentage => state.percentage;
  int get parentPriority => state.parentPriority;
  int get childPriority => state.childPriority;
  @override
  EdgeGeometryImpl get geometry => state.geometry;

  double get amount => state.amount;

  Edge.addToBasePlanner(
    super.basePlanner, {
    required this.parentGraph,
    required this.edgeType,
    required this.parent,
    required this.child,
    required this.item,
  }) : parentProdLine = parent.getInputItemNode(item),
       childProdLine = child.getOutputItemNode(item),
       _internalState = EdgeStateImpl.uninitialised {
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

    _stateBuilder = EdgeStateBuilder.initial(this);
  }

  EdgeState get state => _stateBuilder ?? _internalState;
  @override
  void updateState(EdgeStateImpl state) {
    basePlanner.throwIfMutationNotPermitted();
    _stateBuilder = null;
    _internalState = state;
  }

  @override
  EdgeStateBuilder getStateBuilder() {
    _stateBuilder ??= EdgeStateBuilder.from(this, _internalState);

    return _stateBuilder!;
  }

  @override
  void cancelStateBuilder() => _stateBuilder = null;

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
  EdgeDependencies determineDependencies() => switch (edgeType) {
    EdgeType.requestItems => EdgeDependencies(
      parentProdLineDep: parentProdLine,
      parentEdgeDeps: parent.children[item]!
          .where((edge) => edge.edgeType != EdgeType.requestItems)
          .toList(),
    ),

    EdgeType.pushExcess => EdgeDependencies(
      childProdLineDep: childProdLine,
      childEdgeDeps: child.parents[item]!
          .where((edge) => edge.edgeType == EdgeType.pushExcess)
          .toList(),
    ),

    EdgeType.requestExcess => EdgeDependencies(
      parentProdLineDep: parentProdLine,
      parentEdgeDeps: parent.children[item]!
          .where(
            (edge) =>
                edge.edgeType == EdgeType.pushExcess ||
                (edge.edgeType == EdgeType.requestExcess &&
                    edge.parentPriority < parentPriority),
          )
          .toList(),
      childProdLineDep: childProdLine,
      childEdgeDeps: child.parents[item]!
          .where(
            (edge) =>
                edge.edgeType != EdgeType.requestItems ||
                (edge.edgeType == EdgeType.requestExcess &&
                    edge.childPriority < childPriority),
          )
          .toList(),
    ),
  };

  // Adding both childProdLine and child ensures child is updated if child is a graph
  // Same goes for parent. Even if this does result in some duplication
  @override
  List<BasePlannerElement> determineDependants() => [
    ...determineParentDependants(),
    ...determineChildDependants(),
  ];

  @override
  bool calculateIo(EdgeDependencies dependencies) {
    double newAmount;
    List<NodeElement> unusedIoCheckNodes;

    switch (edgeType) {
      case EdgeType.requestItems:
        newAmount = _getAmountToRequest(dependencies) * percentage;
        unusedIoCheckNodes = [parentProdLine, parent];

      case EdgeType.pushExcess:
        newAmount = _getAmountToPush(dependencies) * percentage;
        unusedIoCheckNodes = [childProdLine, child];

      case EdgeType.requestExcess:
        var request = _getAmountToRequest(dependencies);
        var push = _getAmountToPush(dependencies);
        newAmount = request > push ? request : push;

        unusedIoCheckNodes = [parentProdLine, parent, childProdLine, child];
    }

    if (newAmount != amount) {
      getStateBuilder().updateAmount(newAmount);

      for (var node in unusedIoCheckNodes) {
        basePlanner.getSnapshotBuilder().queueUnusedIoCheck(node);
      }

      return true;
    } else {
      return false;
    }
  }

  List<BasePlannerElement> determineParentDependants() => switch (edgeType) {
    EdgeType.requestItems => const [],

    EdgeType.pushExcess => [
      parentProdLine,
      parent,
      ...parentProdLine.children[item]!.where(
        (edge) => edge.edgeType != EdgeType.pushExcess,
      ),
    ],

    EdgeType.requestExcess => [
      parentProdLine,
      parent,
      ...parentProdLine.children[item]!.where(
        (edge) =>
            edge.edgeType == EdgeType.pushExcess ||
            (edge.edgeType == EdgeType.requestExcess &&
                edge.childPriority > childPriority),
      ),
    ],
  };

  List<BasePlannerElement> determineChildDependants() => switch (edgeType) {
    EdgeType.requestItems => [
      childProdLine,
      child,
      ...childProdLine.parents[item]!.where(
        (edge) => edge.edgeType != EdgeType.requestItems,
      ),
    ],

    EdgeType.pushExcess => const [],

    EdgeType.requestExcess => [
      childProdLine,
      child,
      ...childProdLine.parents[item]!.where(
        (edge) =>
            edge.edgeType == EdgeType.requestItems ||
            (edge.edgeType == EdgeType.requestExcess &&
                edge.parentPriority > parentPriority),
      ),
    ],
  };

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }

  double _getAmountToRequest(EdgeDependencies dependencies) =>
      dependencies.parentProdLineDep!.ioData.itemIo.inputs[item]! -
      dependencies.orderedParentEdgeDeps!.fold(
        0.0,
        (amount, edge) => amount + edge.amount,
      );

  double _getAmountToPush(EdgeDependencies dependencies) =>
      dependencies.childProdLineDep!.ioData.itemIo.outputs[item]! -
      dependencies.orderedChildEdgeDeps!.fold(
        0.0,
        (amount, edge) => amount + edge.amount,
      );
}

class EdgeEvent {
  final EdgeGeometry? geometry;

  EdgeEvent.geometryOp(EdgeGeometry this.geometry);
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
  Iterable<BasePlannerElement> get allDependencies => <BasePlannerElement?>[
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
