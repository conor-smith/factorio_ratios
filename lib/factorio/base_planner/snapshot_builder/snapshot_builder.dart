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

part 'change_tracker/edge.dart';
part 'change_tracker/element.dart';
part 'change_tracker/graph.dart';
part 'change_tracker/prod_line_node.dart';
part 'state_builders/edge.dart';
part 'state_builders/graph.dart';
part 'state_builders/prod_line_node.dart';
part 'state_builders/state_builders.dart';

class SnapshotBuilder implements Builder<Snapshot> {
  final Snapshot _previousSnapshot;

  final Map<Graph, GraphChangeTracker> graphTrackers = {};
  final Map<ProdLineNode, ProdLineNodeChangeTracker> nodeTrackers = {};
  final Map<Edge, EdgeChangeTracker> edgeTrackers = {};

  final List<ElementChangeTracker> _allTrackers = [];

  SnapshotBuilder.from(this._previousSnapshot);

  bool get hasChanges =>
      graphTrackers.isNotEmpty ||
      nodeTrackers.isNotEmpty ||
      edgeTrackers.isNotEmpty;

  @override
  Snapshot build() {
    Map<BasePlannerElement, ElementChangeTracker> toRemove = Map.fromEntries(
      <MapEntry<BasePlannerElement, ElementChangeTracker>>[
        ...graphTrackers.entries,
        ...nodeTrackers.entries,
        ...edgeTrackers.entries,
      ].where((entry) => entry.value.toRemove),
    );

    graphTrackers.removeWhere((_, builder) => builder.toRemove);
    nodeTrackers.removeWhere((_, builder) => builder.toRemove);
    edgeTrackers.removeWhere((_, builder) => builder.toRemove);

    _allTrackers
      ..addAll(graphTrackers.values)
      ..addAll(nodeTrackers.values)
      ..addAll(edgeTrackers.values);

    _checkForCircularDependencies();
    _performIoUdpates();

    throw UnimplementedError();
  }

  void _checkForCircularDependencies() {
    Set<BasePlannerElement> safeElements = {};

    var elementsToCheck = _allTrackers.where(
      (elementBuilder) => elementBuilder.circularDependencyCheck,
    );

    for (var elementBuilder in elementsToCheck) {
      elementBuilder.checkForCircularDependencies(safeElements, {});
    }
  }

  void _performIoUdpates() {
    Queue<ElementChangeTracker> updateQueue = Queue.from(
      _allTrackers.where(
        (elementBuilder) =>
            elementBuilder.ioUpdateStatus == IoUpdateStatus.required,
      ),
    );

    while (updateQueue.isNotEmpty) {
      var trackerToUpdate = updateQueue.removeFirst();
      var updateStatus = trackerToUpdate.ioUpdateStatus;

      // If element is already completed, restart loop
      if (updateStatus.isComplete) {
        continue;
      }

      var dependencies = trackerToUpdate.cachedDependencies;

      // If unresolved dependencies exist,
      // Place said dependencies at front of queue and restart loop
      var unresolvedDeps = dependencies.allElements
          .where(
            (dependency) =>
                !dependency.getChangeTracker().ioUpdateStatus.isComplete,
          )
          .toList();
      if (unresolvedDeps.isNotEmpty) {
        updateQueue.addFirst(trackerToUpdate);
        for (var dep in unresolvedDeps) {
          updateQueue.addFirst(dep.getChangeTracker());
        }

        continue;
      }

      // An IO update is required in two scenarios
      // 1. Explicitly marked as required via UpdateStatus.required
      // 2. One or more dependencies have were updated
      var updateRequired =
          updateStatus == IoUpdateStatus.required ||
          dependencies.allElements.any(
            (dependency) =>
                dependency.getChangeTracker().ioUpdateStatus ==
                IoUpdateStatus.completeUpdate,
          );

      // If update is required and update returns true, add dependents to end of queue
      // Otherwise, mark element as completeNoUpdate
      // Remove element from queue in both scenarios
      if (updateRequired && trackerToUpdate.calculateIo()) {
        trackerToUpdate._ioUpdateStatus = IoUpdateStatus.completeUpdate;

        updateQueue.addAll(
          trackerToUpdate.determineDependants().map(
            (element) => element.getChangeTracker(),
          ),
        );
      } else {
        trackerToUpdate._ioUpdateStatus = IoUpdateStatus.completeNoUpdate;
      }
    }
  }

  void _calculateUnusedIo() {
    var nodeTrackers = _allTrackers.whereType<NodeChangeTracker>().where(
      (element) => element.unusedIoCheck,
    );

    for (var node in nodeTrackers) {
      node.checkForUnusedIo();
    }
  }

  void _performGraphLayoutUpdates() {
    var graphsToUpdate = graphTrackers.values.where(
      (tracker) => tracker.layoutUpdate,
    );

    // TODO
  }

  // Map<BasePlannerElement, dynamic> _performStateUpdateAndReturnMap() {
  //   _stage = SnapshotBuildStage.buildStates;

  //   Map<BasePlannerElement, dynamic> newStateMap = Map.from(
  //     _previousSnapshot.states,
  //   );

  //   for (var removedElement in _removedElements) {
  //     removedElement.cancelStateBuilder();
  //     newStateMap.remove(removedElement);
  //   }

  //   var updatedStates = _updatedElements.map(
  //     (element, builder) => MapEntry(element, builder.build()),
  //   );
  //   newStateMap.addAll(updatedStates);

  //   return newStateMap;
  // }
}

enum IoUpdateStatus {
  checkDependencies(false),
  required(false),
  completeNoUpdate(true),
  completeUpdate(true);

  final bool isComplete;

  const IoUpdateStatus(this.isComplete);
}
