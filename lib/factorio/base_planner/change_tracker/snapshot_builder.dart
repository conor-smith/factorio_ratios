part of 'change_trackers.dart';

class SnapshotBuilder implements Builder<Snapshot> {
  final Snapshot _previousSnapshot;

  final Map<Graph, GraphChangeTracker> _graphTrackers = {};
  final Map<ProdLineNode, ProdLineNodeChangeTracker> _nodeTrackers = {};
  final Map<Edge, EdgeChangeTracker> _edgeTrackers = {};

  final List<ElementChangeTracker> _allTrackers = [];
  final List<BasePlannerElement> _elementsToRemove = [];

  late final Map<Graph, GraphChangeTracker> graphTrackers = UnmodifiableMapView(
    _graphTrackers,
  );
  late final Map<ProdLineNode, ProdLineNodeChangeTracker> nodeTrackers =
      UnmodifiableMapView(_nodeTrackers);
  late final Map<Edge, EdgeChangeTracker> edgeTrackers = UnmodifiableMapView(
    _edgeTrackers,
  );

  bool get hasChanges =>
      _elementsToRemove.isNotEmpty ||
      _allTrackers.any((tracker) => tracker.hasUpdates);
  bool get hasQueuedIoOperations => _allTrackers.any(
    (tracker) =>
        tracker._queuedForRemoval ||
        tracker._circularDependencyCheck ||
        !tracker._ioUpdateStatus.isComplete ||
        (tracker is NodeChangeTracker && tracker._checkForUnusedIo) ||
        (tracker is GraphChangeTracker && tracker._layoutUpdateQueued),
  );

  SnapshotBuilder.from(this._previousSnapshot);

  GraphChangeTracker getGraphChangeTracker(
    Graph graph,
    GraphStateImpl currentState,
  ) => _graphTrackers[graph] ?? GraphChangeTracker(graph, currentState);

  ProdLineNodeChangeTracker getProdLineChangeTracker(
    ProdLineNode node,
    ProdLineNodeStateImpl currentState,
  ) => _nodeTrackers[node] ?? ProdLineNodeChangeTracker(node, currentState);

  EdgeChangeTracker getEdgeChangeTracker(
    Edge edge,
    EdgeStateImpl currentState,
  ) => _edgeTrackers[edge] ?? EdgeChangeTracker(edge, currentState);

  void performQueuedIoOperations() {
    // Any trackers queued for removal do not need to be processed
    // As such, they can be removed from this list
    _allTrackers.removeWhere((tracker) {
      if (tracker._queuedForRemoval) {
        _elementsToRemove.add(tracker.element);
        return true;
      } else {
        return false;
      }
    });

    // Just in case this has been called more than once
    // New elements may have been added, so caches must be cleared
    for (var tracker in _allTrackers) {
      tracker._cachedDependencies = null;
    }

    _checkForCircularDependencies();
    _performIoUdpates();
    _calculateUnusedIo();
  }

  void performQueuedLayoutUpdates() {
    var graphsToUpdate = _allTrackers.whereType<GraphChangeTracker>().where(
      (tracker) => tracker.layoutUpdateQueued,
    );

    for (var toUpdate in graphsToUpdate) {
      toUpdate._performLayoutUpdate();
      toUpdate._layoutUpdateQueued = false;
    }
  }

  @override
  Snapshot build() {
    Map<BasePlannerElement, Object> newStateMap = Map.from(
      _previousSnapshot.stateMap,
    );

    for (var toRemove in _elementsToRemove) {
      newStateMap.remove(toRemove);
    }

    for (var update in _allTrackers.where((tracker) => tracker.hasUpdates)) {
      newStateMap[update.element] = update.build();
    }

    return Snapshot(newStateMap);
  }

  void _checkForCircularDependencies() {
    Set<BasePlannerElement> safeElements = {};

    var elementsToCheck = _allTrackers
        .where((elementBuilder) => elementBuilder._circularDependencyCheck)
        .toList();

    for (var elementBuilder in elementsToCheck) {
      elementBuilder._checkForCircularDependencies(safeElements, {});
      elementBuilder._circularDependencyCheck = false;
    }
  }

  void _performIoUdpates() {
    Queue<ElementChangeTracker> updateQueue = DoubleLinkedQueue.from(
      _allTrackers.where(
        (elementBuilder) =>
            elementBuilder._ioUpdateStatus == IoUpdateStatus.required,
      ),
    );

    while (updateQueue.isNotEmpty) {
      var trackerToUpdate = updateQueue.removeFirst();

      // If element is already completed, restart loop
      if (trackerToUpdate._ioUpdateStatus.isComplete) {
        continue;
      }

      // If unresolved dependencies exist,
      // Place said dependencies at front of queue and restart loop
      var unresolvedDeps = trackerToUpdate
          ._getCachedDependencies()
          .allElements
          .where(
            (dependency) =>
                !dependency.getChangeTracker()._ioUpdateStatus.isComplete,
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
      // 2. Status is checkDependencies and one or more dependencies have were updated
      // Thanks to previous steps, we know status can only be required or checkDependencies
      var updateRequired =
          trackerToUpdate._ioUpdateStatus == IoUpdateStatus.required ||
          trackerToUpdate._getCachedDependencies().allElements.any(
            (dependency) =>
                dependency.getChangeTracker()._ioUpdateStatus ==
                IoUpdateStatus.completeUpdate,
          );

      // If update is required and update returns true, add dependents to end of queue
      // Otherwise, mark element as completeNoUpdate
      // Remove element from queue in both scenarios
      if (updateRequired && trackerToUpdate._calculateIo()) {
        trackerToUpdate._ioUpdateStatus = IoUpdateStatus.completeUpdate;

        var dependantTrackers = trackerToUpdate._determineDependants().map(
          (element) => element.getChangeTracker(),
        );
        for (var tracker in dependantTrackers) {
          tracker._ioUpdateStatus = IoUpdateStatus.checkDependencies;
          updateQueue.addLast(tracker);
        }
      } else {
        trackerToUpdate._ioUpdateStatus = IoUpdateStatus.completeNoUpdate;
      }
    }
  }

  void _calculateUnusedIo() {
    var nodeTrackers = _allTrackers.whereType<NodeChangeTracker>().where(
      (element) => element.checkForUnusedIo,
    );

    for (var node in nodeTrackers) {
      node._performUnusedIoCheck();
      node._checkForUnusedIo = false;
    }
  }
}
