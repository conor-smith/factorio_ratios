// TODO - Document
import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/edge/edge.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/factorio/base_planner/node/node.dart';
import 'package:factorio_ratios/factorio/base_planner/state_builders/state_builders.dart';
import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/utility/builder.dart';

part 'snapshot_builder_edge.dart';
part 'snapshot_builder_graph.dart';
part 'snapshot_builder_element.dart';
part 'snapshot_builder_prod_line.dart';

class SnapshotBuilder implements Builder<Snapshot> {
  final Snapshot _previousSnapshot;

  final Map<Graph, SnapshotBuilderGraph> graphBuilders = {};
  final Map<ProdLineNode, SnapshotBuilderProdLineNode> nodeBuilders = {};
  final Map<Edge, SnapshotBuilderEdge> edgeBuilders = {};

  SnapshotBuildStage _stage = SnapshotBuildStage.userOperations;

  SnapshotBuilder.from(this._previousSnapshot);

  bool get hasChanges =>
      graphBuilders.isNotEmpty ||
      nodeBuilders.isNotEmpty ||
      edgeBuilders.isNotEmpty;

  void throwIfNotStage(SnapshotBuildStage stage) {
    if (_stage != stage) {
      throw BasePlannerException(
        'Can only perform this operation at stage $stage. Current stage is $_stage',
      );
    }
  }

  @override
  Snapshot build() {
    throw UnimplementedError();
    // for (var removedElement in _removedElements) {
    //   _newElements.remove(removedElement);
    //   _elementUpdateStatus.remove(removedElement);
    // }

    // _checkForCircularDependencies();
    // _performIoUdpates();
    // _performGraphLayoutUpdates();
    // var newStateMap = _performStateUpdateAndReturnMap();

    // return Snapshot(newStateMap);
  }

  // IoUpdateStatus _getOrCreateUpdateStatus(BasePlannerElement element) =>
  //     _elementUpdateStatus.putIfAbsent(
  //       element,
  //       () => IoUpdateStatus.checkDependencies,
  //     );

  // void _checkForCircularDependencies() {
  //   _stage = SnapshotBuildStage.circularDependencyCheck;

  //   Set<BasePlannerElement> safeElements = {};

  //   for (var element in _newElements) {
  //     element.checkForCircularDependencies(safeElements, {});
  //   }
  // }

  // void _performIoUdpates() {
  //   _stage = SnapshotBuildStage.buildIo;

  //   Queue<BasePlannerElement> updateQueue = Queue.from(
  //     _elementUpdateStatus.keys,
  //   );

  //   while (updateQueue.isNotEmpty) {
  //     var toUpdate = updateQueue.removeFirst();
  //     var updateStatus = _getOrCreateUpdateStatus(toUpdate);

  //     // If element is already completed, restart loop
  //     if (updateStatus.isComplete) {
  //       continue;
  //     }

  //     var dependencies = getCachedDependencies(toUpdate);

  //     // If unresolved dependencies exist,
  //     // Place said dependencies at front of queue and restart loop
  //     var unresolvedDeps = dependencies.allDependencies
  //         .where(
  //           (dependency) => !_getOrCreateUpdateStatus(dependency).isComplete,
  //         )
  //         .toList();
  //     if (unresolvedDeps.isNotEmpty) {
  //       updateQueue.addFirst(toUpdate);
  //       for (var dep in unresolvedDeps) {
  //         updateQueue.addFirst(dep);
  //       }

  //       continue;
  //     }

  //     // An IO update is required in two scenarios
  //     // 1. Explicitly marked as required via UpdateStatus.required
  //     // 2. One or more dependencies have were updated
  //     var updateRequired =
  //         updateStatus == IoUpdateStatus.required ||
  //         dependencies.allDependencies.any(
  //           (dependency) =>
  //               _getOrCreateUpdateStatus(dependency) ==
  //               IoUpdateStatus.completeUpdate,
  //         );

  //     // If update is required and update returns true, add dependents to end of queue
  //     // Otherwise, mark element as completeNoUpdate
  //     // Remove element from queue in both scenarios
  //     if (updateRequired && toUpdate.calculateIo(dependencies)) {
  //       _elementUpdateStatus[toUpdate] = IoUpdateStatus.completeUpdate;

  //       updateQueue.addAll(toUpdate.determineDependants());
  //     } else {
  //       _elementUpdateStatus[toUpdate] = IoUpdateStatus.completeNoUpdate;
  //     }
  //   }

  //   // Once all IO updates are done, we can check for unused IO
  //   for (var node in _nodesToCheckUnusedIo) {
  //     node.calculateUnusedIo();
  //   }
  // }

  // void _performGraphLayoutUpdates() {
  //   _stage = SnapshotBuildStage.updateGraphLayouts;

  //   for (var graph in _graphsToUpdateLayout) {
  //     graph.defaultLayout();
  //   }
  // }

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
  notQueued(false),
  checkDependencies(false),
  required(false),
  completeNoUpdate(true),
  completeUpdate(true);

  final bool isComplete;

  const IoUpdateStatus(this.isComplete);
}

enum SnapshotBuildStage {
  userOperations,
  circularDependencyCheck,
  buildIo,
  updateGraphLayouts,
  buildStates,
}
