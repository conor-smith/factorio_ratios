part of 'base_planner.dart';

class SnapshotBuilder implements Builder<Snapshot?> {
  final Snapshot _previousSnapshot;

  final Map<Graph, GraphChangeTracker> graphTrackers = {};
  final Map<ProdLineNode, ProdLineNodeChangeTracker> nodeTrackers = {};
  final Map<Edge, EdgeChangeTracker> edgeTrackers = {};

  final Set<ElementChangeTracker> allTrackers = {};

  SnapshotBuilder.from(this._previousSnapshot);

  @override
  Snapshot? build() {
    List<BasePlannerElement> elementsToRemove = [];

    allTrackers.removeWhere((tracker) {
      if (tracker.toRemove) {
        elementsToRemove.add(tracker.element);
        return true;
      } else {
        return false;
      }
    });

    _checkForCircularDependencies();
    _performIoUdpates();
    _calculateUnusedIo();
    _performGraphLayoutUpdates();

    if (elementsToRemove.isNotEmpty ||
        allTrackers.any((tracker) => tracker.hasUpdates)) {
      Map<BasePlannerElement, ElementAndState> newStateMap = Map.from(
        _previousSnapshot.stateMap,
      );

      for (var toRemove in elementsToRemove) {
        newStateMap.remove(toRemove);
      }

      for (var update in allTrackers.where((tracker) => tracker.hasUpdates)) {
        newStateMap[update.element] = update.build();
      }

      return Snapshot(newStateMap);
    } else {
      return null;
    }
  }

  void _checkForCircularDependencies() {
    Set<BasePlannerElement> safeElements = {};

    var elementsToCheck = allTrackers.where(
      (elementBuilder) => elementBuilder.circularDependencyCheck,
    );

    for (var elementBuilder in elementsToCheck) {
      elementBuilder.checkForCircularDependencies(safeElements, {});
    }
  }

  void _performIoUdpates() {
    Queue<ElementChangeTracker> updateQueue = Queue.from(
      allTrackers.where(
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
        trackerToUpdate.setIoCompleteWithUpdate();

        updateQueue.addAll(
          trackerToUpdate.determineDependants().map(
            (element) => element.getChangeTracker(),
          ),
        );
      } else {
        trackerToUpdate.setIoCompleteWithNoUpdate();
      }
    }

    // New trackers may have been created as part of IO update step
    var trackersToAdd = <ElementChangeTracker>[
      ...graphTrackers.values,
      ...nodeTrackers.values,
      ...edgeTrackers.values,
    ].where((tracker) => !tracker.toRemove);

    allTrackers.addAll(trackersToAdd);
  }

  void _calculateUnusedIo() {
    var nodeTrackers = allTrackers.whereType<NodeChangeTracker>().where(
      (element) => element.unusedIoCheck,
    );

    for (var node in nodeTrackers) {
      node.checkForUnusedIo();
    }
  }

  void _performGraphLayoutUpdates() {
    var graphsToUpdate = allTrackers.whereType<GraphChangeTracker>().where(
      (tracker) => tracker.layoutUpdate,
    );

    for (var toUpdate in graphsToUpdate) {
      toUpdate.performLayoutUptdate();
    }
  }
}
