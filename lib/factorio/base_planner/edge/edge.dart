import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/edge_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/factorio/base_planner/node/node.dart';
import 'package:factorio_ratios/factorio/base_planner/state_builders/state_builders.dart';
import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/json/json.dart';
import 'package:factorio_ratios/utility/collections.dart';

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

  double get amount {
    basePlanner.throwIfIoNotToBeAccessed(this);
    return state.amount;
  }

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
  bool traverseDepsAndUpdateIo(Set<BasePlannerElement> visitedElements) {
    // Check for circular dependency
    // TODO - Centralise this code rather than copying it
    if (visitedElements.contains(this)) {
      throw BasePlannerException('Circular dependency detected at $this');
    }

    visitedElements.add(this);

    var updateStatus = switch (basePlanner.getSnapshotBuilder().getUpdateStatus(
      this,
    )) {
      UpdateStatus.completeUpdate => true,
      UpdateStatus.completeNoUpdate => false,
      UpdateStatus.checkDependencies => _determineAmount(
        false,
        visitedElements,
      ),
      UpdateStatus.required => _determineAmount(true, visitedElements),
    };

    visitedElements.remove(this);
    return updateStatus;
  }

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }

  bool _determineAmount(
    bool forceUpdate,
    Set<BasePlannerElement> visitedElements,
  ) {
    var updateStatus = switch (edgeType) {
      EdgeType.requestItems => _determineAmountForRequestItem(
        forceUpdate,
        visitedElements,
      ),
      EdgeType.pushExcess => _determineAmountForPushExcess(
        forceUpdate,
        visitedElements,
      ),
      EdgeType.requestExcess => _determineAmountForRequestExcess(
        forceUpdate,
        visitedElements,
      ),
    };

    if (updateStatus && parent is Graph) {
      basePlanner.getSnapshotBuilder().updateIoSatus(
        parent,
        UpdateStatus.required,
      );
    }
    if (updateStatus && child is Graph) {
      basePlanner.getSnapshotBuilder().updateIoSatus(
        child,
        UpdateStatus.required,
      );
    }

    return updateStatus;
  }

  bool _determineAmountForRequestItem(
    bool forceUpdate,
    Set<BasePlannerElement> visitedElements,
  ) {
    var parentItemEdges = parentProdLine.children[item]!;
    var snapshotBuilder = basePlanner.getSnapshotBuilder();

    // Will either retrieve requestExcess edge with highest parentPriority
    // or parentProdLine if no requestExcess edges exist
    BasePlannerElement dependency =
        maxOrNull<Edge>(
          parentItemEdges.where(
            (edge) => edge.edgeType == EdgeType.requestExcess,
          ),
          (edge1, edge2) =>
              edge1.parentPriority.compareTo(edge2.parentPriority),
        ) ??
        parentProdLine;

    var dependencyUpdate = dependency.traverseDepsAndUpdateIo(visitedElements);

    if (forceUpdate || dependencyUpdate) {
      // TODO - Update all requestItemEdges at once?
      var unfulfilledRequest =
          parentProdLine.itemIo.inputs[item]! -
          parentItemEdges
              .where((edge) => edge.edgeType != EdgeType.requestItems)
              .fold(0, (sum, edge) => sum + edge.amount);

      getStateBuilder().updateAmount(unfulfilledRequest * percentage);

      snapshotBuilder
        ..updateIoSatus(this, UpdateStatus.completeUpdate)
        ..updateIoSatus(childProdLine, UpdateStatus.checkDependencies, true);

      // Determine if there's enough unfulfilled requests for a new edge
      var requestItemEdges = parentItemEdges.where(
        (edge) => edge.edgeType == EdgeType.requestItems,
      );
      if (requestItemEdges.every(
        (edge) => snapshotBuilder.getUpdateStatus(edge).isComplete,
      )) {
        var leftOver =
            unfulfilledRequest -
            requestItemEdges.fold(0, (sum, edge) => sum + edge.amount);

        if (leftOver > basePlanner.ioThreshold) {
          snapshotBuilder.queueUnfulfilledIoCheck(parentProdLine);
        }
      }

      return true;
    } else {
      snapshotBuilder.updateIoSatus(this, UpdateStatus.completeNoUpdate);

      return false;
    }
  }

  bool _determineAmountForPushExcess(
    bool forceUpdate,
    Set<BasePlannerElement> visitedElements,
  ) {
    var childItemEdges = childProdLine.parents[item]!;
    var snapshotBuilder = basePlanner.getSnapshotBuilder();

    // Will either retrieve requestExcess edge with highest childPriority
    // or childProdLine if no requestExcess edges exist
    BasePlannerElement dependency =
        maxOrNull<Edge>(
          childItemEdges.where(
            (edge) => edge.edgeType == EdgeType.requestExcess,
          ),
          (edge1, edge2) => edge1.childPriority.compareTo(edge2.childPriority),
        ) ??
        childProdLine;

    bool dependencyUpdate = dependency.traverseDepsAndUpdateIo(visitedElements);

    if (forceUpdate || dependencyUpdate) {
      // TODO - Update all pushExcess edges at once?
      var unconsumedExcess =
          childProdLine.itemIo.outputs[item]! -
          childItemEdges
              .where((edge) => edge.edgeType != EdgeType.pushExcess)
              .fold(0, (sum, edge) => sum + edge.amount);

      getStateBuilder().updateAmount(unconsumedExcess * percentage);

      snapshotBuilder
        ..updateIoSatus(this, UpdateStatus.completeUpdate)
        ..updateIoSatus(parentProdLine, UpdateStatus.checkDependencies, true);

      // Determine if there's enough unfulfilled requests for a new edge
      var requestItemEdges = childItemEdges.where(
        (edge) => edge.edgeType == EdgeType.pushExcess,
      );
      if (requestItemEdges.every(
        (edge) =>
            basePlanner.getSnapshotBuilder().getUpdateStatus(edge).isComplete,
      )) {
        var leftOver =
            unconsumedExcess -
            requestItemEdges.fold(0, (sum, edge) => sum + edge.amount);

        if (leftOver > basePlanner.ioThreshold) {
          snapshotBuilder.queueUnfulfilledIoCheck(childProdLine);
        }
      }

      return true;
    } else {
      snapshotBuilder.updateIoSatus(this, UpdateStatus.completeNoUpdate);

      return false;
    }
  }

  bool _determineAmountForRequestExcess(
    bool forceUpdate,
    Set<BasePlannerElement> visitedElements,
  ) {
    var parentItemEdges = parentProdLine.children[item]!;
    var childItemEdges = childProdLine.parents[item]!;
    var snapshotBuilder = basePlanner.getSnapshotBuilder();

    // Will either retrieve parentProdLine
    // or preceding requestExcess edge from parent
    BasePlannerElement parentDependency = parentPriority == 1
        ? parentProdLine
        : parentItemEdges.firstWhere(
            (edge) =>
                edge.edgeType == EdgeType.requestExcess &&
                edge.parentPriority == parentPriority - 1,
          );

    // Will either retrieve childProdLine
    // or preceding requestExcess edge from child
    BasePlannerElement childDependency = childPriority == 1
        ? childProdLine
        : childItemEdges.firstWhere(
            (edge) =>
                edge.edgeType == EdgeType.requestExcess &&
                edge.childPriority == childPriority - 1,
          );

    var parentDepUpdate = parentDependency.traverseDepsAndUpdateIo(
      visitedElements,
    );
    var childDepUpdate = childDependency.traverseDepsAndUpdateIo(
      visitedElements,
    );

    if (forceUpdate || parentDepUpdate || childDepUpdate) {
      var parentUnfulfilledRequest =
          parentProdLine.itemIo.inputs[item]! -
          parentItemEdges
              .where(
                (edge) =>
                    edge.edgeType != EdgeType.requestItems &&
                    edge.parentPriority < parentPriority,
              )
              .fold(0, (sum, edge) => sum + edge.amount);

      var childUnconsumedExcess =
          childProdLine.itemIo.outputs[item]! -
          childItemEdges
              .where(
                (edge) =>
                    edge.edgeType != EdgeType.pushExcess &&
                    edge.childPriority < childPriority,
              )
              .fold(0, (sum, edge) => sum + edge.amount);

      var amount = parentUnfulfilledRequest > childUnconsumedExcess
          ? parentUnfulfilledRequest
          : childUnconsumedExcess;

      getStateBuilder().updateAmount(amount);

      snapshotBuilder.updateIoSatus(this, UpdateStatus.completeUpdate);

      // List should only contain the next requestExcess edge for parent and item
      var parentDependants = parentItemEdges
          .where(
            (edge) =>
                edge.edgeType == EdgeType.requestExcess &&
                edge.parentPriority == parentPriority + 1,
          )
          .toList();

      // List will contain all requestItem edges for parent and item
      if (parentDependants.isEmpty) {
        parentDependants = parentItemEdges
            .where((edge) => edge.edgeType == EdgeType.requestItems)
            .toList();
      }

      // If neither exist, check if unfulfilled IO
      if (parentDependants.isEmpty &&
          parentUnfulfilledRequest - amount > basePlanner.ioThreshold) {
        snapshotBuilder.queueUnfulfilledIoCheck(parentProdLine);
      }

      // List should only contain the next requestExcess edge for child and item
      var childDependants = childItemEdges
          .where(
            (edge) =>
                edge.edgeType == EdgeType.requestExcess &&
                edge.childPriority == childPriority + 1,
          )
          .toList();

      // List will contain all requestItem edges for parent and item
      if (childDependants.isEmpty) {
        childDependants = childItemEdges
            .where((edge) => edge.edgeType == EdgeType.pushExcess)
            .toList();
      }

      if (childDependants.isEmpty &&
          childUnconsumedExcess - amount > basePlanner.ioThreshold) {
        snapshotBuilder.queueUnfulfilledIoCheck(childProdLine);
      }

      for (var dependentEdge in [...parentDependants, ...childDependants]) {
        snapshotBuilder.updateIoSatus(
          dependentEdge,
          UpdateStatus.checkDependencies,
          true,
        );
      }

      return true;
    } else {
      basePlanner.getSnapshotBuilder().updateIoSatus(
        this,
        UpdateStatus.completeNoUpdate,
      );
      return false;
    }
  }
}

class EdgeEvent {
  final EdgeGeometry? geometry;

  EdgeEvent.geometryOp(EdgeGeometry this.geometry);
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
