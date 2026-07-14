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

part 'elements/edge.dart';
part 'elements/element.dart';
part 'elements/graph.dart';
part 'elements/prod_line_node.dart';
part 'state_builders/edge.dart';
part 'state_builders/graph.dart';
part 'state_builders/prod_line_node.dart';
part 'state_builders/state_builders.dart';

class SnapshotBuilder implements Builder<Snapshot> {
  final Snapshot _previousSnapshot;

  final Map<Graph, SnapshotBuilderGraph> graphBuilders = {};
  final Map<ProdLineNode, SnapshotBuilderProdLineNode> nodeBuilders = {};
  final Map<Edge, SnapshotBuilderEdge> edgeBuilders = {};

  final List<SnapshotBuilderElement> _allElements = [];

  SnapshotBuilder.from(this._previousSnapshot);

  bool get hasChanges =>
      graphBuilders.isNotEmpty ||
      nodeBuilders.isNotEmpty ||
      edgeBuilders.isNotEmpty;

  @override
  Snapshot build() {
    Map<BasePlannerElement, SnapshotBuilderElement> toRemove = Map.fromEntries(
      <MapEntry<BasePlannerElement, SnapshotBuilderElement>>[
        ...graphBuilders.entries,
        ...nodeBuilders.entries,
        ...edgeBuilders.entries,
      ].where((entry) => entry.value.toRemove),
    );

    graphBuilders.removeWhere((_, builder) => builder.toRemove);
    nodeBuilders.removeWhere((_, builder) => builder.toRemove);
    edgeBuilders.removeWhere((_, builder) => builder.toRemove);

    _allElements
      ..addAll(graphBuilders.values)
      ..addAll(nodeBuilders.values)
      ..addAll(edgeBuilders.values);

    _checkForCircularDependencies();
    _performIoUdpates();

    throw UnimplementedError();
  }

  void _checkForCircularDependencies() {
    Set<BasePlannerElement> safeElements = {};

    var elementsToCheck = _allElements.where(
      (elementBuilder) => elementBuilder.circularDependencyCheck,
    );

    for (var elementBuilder in elementsToCheck) {
      elementBuilder.checkForCircularDependencies(safeElements, {});
    }
  }

  void _performIoUdpates() {
    Queue<SnapshotBuilderElement> updateQueue = Queue.from(
      _allElements.where(
        (elementBuilder) =>
            elementBuilder.ioUpdateStatus == IoUpdateStatus.required,
      ),
    );

    while (updateQueue.isNotEmpty) {
      var toUpdate = updateQueue.removeFirst();
      var updateStatus = toUpdate.ioUpdateStatus;

      // If element is already completed, restart loop
      if (updateStatus.isComplete) {
        continue;
      }

      var dependencies = toUpdate.cachedDependencies;

      // If unresolved dependencies exist,
      // Place said dependencies at front of queue and restart loop
      var unresolvedDeps = dependencies.allElements
          .where(
            (dependency) => !dependency
                .getSnapshotBuilderElement()
                .ioUpdateStatus
                .isComplete,
          )
          .toList();
      if (unresolvedDeps.isNotEmpty) {
        updateQueue.addFirst(toUpdate);
        for (var dep in unresolvedDeps) {
          updateQueue.addFirst(dep.getSnapshotBuilderElement());
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
                dependency.getSnapshotBuilderElement().ioUpdateStatus ==
                IoUpdateStatus.completeUpdate,
          );

      // If update is required and update returns true, add dependents to end of queue
      // Otherwise, mark element as completeNoUpdate
      // Remove element from queue in both scenarios
      if (updateRequired && toUpdate.calculateIo()) {
        toUpdate._ioUpdateStatus = IoUpdateStatus.completeUpdate;

        updateQueue.addAll(
          toUpdate.determineDependants().map(
            (element) => element.getSnapshotBuilderElement(),
          ),
        );
      } else {
        toUpdate._ioUpdateStatus = IoUpdateStatus.completeNoUpdate;
      }
    }
  }

  void _calculateUnusedIo() {
    var nodeElements = _allElements.whereType<SnapshotBuilderNode>().where(
      (element) => element.unusedIoCheck,
    );

    for (var node in nodeElements) {
      node.checkForUnusedIo();
    }
  }

  void _performGraphLayoutUpdates() {
    var graphsToUpdate = graphBuilders.values.where(
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
