import 'dart:collection';

import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/edge/edge.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/edge_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/node_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/factorio/base_planner/node/node.dart';
import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/factorio/models/models.dart';
import 'package:factorio_ratios/factorio/production_lines/production_line.dart';
import 'package:factorio_ratios/utility/builder.dart';

part 'edge_change_tracker.dart';
part 'edge_state_builder.dart';
part 'graph_change_tracker.dart';
part 'graph_state_builder.dart';
part 'prod_line_node_change_tracker.dart';
part 'prod_line_node_state_builder.dart';
part 'snapshot_builder.dart';

abstract interface class Dependencies {
  Iterable<BasePlannerElement> get allElements;
}

abstract class ElementChangeTracker<
  E extends BasePlannerElement<St, dynamic>,
  St,
  D extends Dependencies,
  B extends Builder<St>
>
    implements Builder<ElementAndState<E, St>> {
  final SnapshotBuilder snapshotBuilder;
  final E element;
  final St previousState;

  B? _cachedStateBuilder;
  D? _cachedDependencies;

  bool _circularDependencyCheck;
  bool _queuedForRemoval;
  IoUpdateStatus _ioUpdateStatus;

  ElementChangeTracker(this.element, this.previousState)
    : snapshotBuilder = element.basePlanner.getSnapshotBuilderOrThrow(),
      _queuedForRemoval = false,
      _circularDependencyCheck = false,
      _ioUpdateStatus = IoUpdateStatus.checkDependencies {
    _addSelfToSnapshotBuilder();
  }

  ElementChangeTracker.newElement(
    this.element,
    this.previousState,
    B stateBuilder,
  ) : snapshotBuilder = element.basePlanner.getSnapshotBuilderOrThrow(),
      _cachedStateBuilder = stateBuilder,
      _queuedForRemoval = false,
      _circularDependencyCheck = true,
      _ioUpdateStatus = IoUpdateStatus.required {
    _addSelfToSnapshotBuilder();
    element.parentGraph.getChangeTracker().queueLayoutUpdate();
  }

  Object get state;

  void removeSelf();

  // Returns true if update occurred, false otherwise
  bool _calculateIo();
  B _createStateBuilder();
  D _determineDependencies();
  Iterable<BasePlannerElement> _determineDependants();
  void _addSelfToSnapshotBuilder();
  void _removeSelfOnly();

  bool get hasUpdates => _cachedStateBuilder != null;

  B get stateBuilder {
    _cachedStateBuilder ??= _createStateBuilder();

    return _cachedStateBuilder!;
  }

  D _getCachedDependencies() {
    _cachedDependencies ??= _determineDependencies();

    return _cachedDependencies!;
  }

  void queueIoUpdate() => _ioUpdateStatus = IoUpdateStatus.required;

  @override
  ElementAndState<E, St> build() =>
      ElementAndState(element, _cachedStateBuilder?.build() ?? previousState);

  void _checkForCircularDependencies(
    Set<BasePlannerElement> safeElements,
    Set<BasePlannerElement> visitedElements,
  ) {
    if (visitedElements.contains(element)) {
      throw BasePlannerException('Circular dependency detected at $element');
    }

    if (!safeElements.contains(element)) {
      visitedElements.add(element);

      for (var dependency in _getCachedDependencies().allElements) {
        dependency.getChangeTracker()._checkForCircularDependencies(
          safeElements,
          visitedElements,
        );
      }

      visitedElements.remove(element);
      safeElements.add(element);
    }
  }
}

abstract class NodeChangeTracker<
  E extends NodeElement<St, NodeEvent>,
  St extends NodeState,
  D extends Dependencies,
  B extends NodeStateBuilder<St>
>
    extends ElementChangeTracker<E, St, D, B> {
  bool _checkForUnusedIo;

  NodeChangeTracker(super.element, super.previousState)
    : _checkForUnusedIo = false;

  NodeChangeTracker.newNode(
    super.element,
    super.previousState,
    super.stateBuilder,
  ) : _checkForUnusedIo = true,
      super.newElement() {
    element.parentGraph.getChangeTracker()._addNodeToNodeCaches(element);
  }

  @override
  NodeState get state;

  bool get checkForUnusedIo => _checkForUnusedIo;

  void queueUnusedIoCheck() => _checkForUnusedIo = true;

  void _performUnusedIoCheck() {
    var itemIo = state.ioData.itemIo;

    ItemIoBuilder unusedIoBuilder = ItemIoBuilder();

    state.parents.forEach((item, edges) {
      var unconsumedOutput =
          itemIo.outputs[item]! -
          edges.fold(0.0, (sum, edge) => sum + edge.amount);

      // Account for floating point errors
      if (unconsumedOutput > 0.000001) {
        unusedIoBuilder.addToOutputs(item, unconsumedOutput);
      }
    });

    state.children.forEach((item, edges) {
      var unfulfilledInput =
          itemIo.inputs[item]! -
          edges.fold(0.0, (sum, edge) => sum + edge.amount);

      // Account for floating point errors
      if (unfulfilledInput > 0.000001) {
        unusedIoBuilder.addToOutputs(item, unfulfilledInput);
      }
    });

    var newUnusedIo = unusedIoBuilder.build();

    if (newUnusedIo != state.unusedIo) {
      stateBuilder._updateUnusedIo(newUnusedIo);
    }
  }

  void _removeSelfAndUpdateParentGraphSnapshotBuilder() {
    element.parentGraph.getChangeTracker()
      ..queueLayoutUpdate()
      ..queueIoUpdate()
      .._removeNodeFromNodeCaches(element);
  }
}

abstract class NodeStateBuilder<T extends NodeState>
    implements NodeState, Builder<T> {
  void _updateUnusedIo(ItemIoImpl newUnusedIo);
  void updateGeometry(NodeGeometryImpl geometry);
}

enum IoUpdateStatus {
  checkDependencies(false),
  required(false),
  completeNoUpdate(true),
  completeUpdate(true);

  final bool isComplete;

  const IoUpdateStatus(this.isComplete);
}
