part of 'change_trackers.dart';

class SnapshotBuilder implements Builder<Snapshot> {
  final Snapshot _previousSnapshot;

  final Map<Graph, GraphChangeTracker> _graphTrackers = {};
  final Map<ProdLineNode, ProdLineNodeChangeTracker> _nodeTrackers = {};
  final Map<Edge, EdgeChangeTracker> _edgeTrackers = {};

  final Set<ElementChangeTracker> allTrackers = {};
  final List<BasePlannerElement> elementsToRemove = [];

  late final Map<Graph, GraphChangeTracker> graphTrackers = UnmodifiableMapView(
    _graphTrackers,
  );
  late final Map<ProdLineNode, ProdLineNodeChangeTracker> nodeTrackers =
      UnmodifiableMapView(_nodeTrackers);
  late final Map<Edge, EdgeChangeTracker> edgeTrackers = UnmodifiableMapView(
    _edgeTrackers,
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

  bool performAllQueuedOperationsAndReturnHasChanges() {
    allTrackers.removeWhere((tracker) {
      if (tracker.queuedForRemoval) {
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

    return elementsToRemove.isNotEmpty ||
        allTrackers.any((tracker) => tracker.hasUpdates);
  }

  @override
  Snapshot build() {
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
  }

  void _checkForCircularDependencies() {
    Set<BasePlannerElement> safeElements = {};

    var elementsToCheck = allTrackers.where(
      (elementBuilder) => elementBuilder.checkForCircularDependency,
    );

    for (var elementBuilder in elementsToCheck) {
      elementBuilder._checkForCircularDependencies(safeElements, {});
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
      if (updateRequired && trackerToUpdate._calculateIo()) {
        trackerToUpdate._ioUpdateStatus = IoUpdateStatus.completeUpdate;

        updateQueue.addAll(
          trackerToUpdate._determineDependants().map(
            (element) => element.getChangeTracker(),
          ),
        );
      } else {
        trackerToUpdate._ioUpdateStatus = IoUpdateStatus.completeNoUpdate;
      }
    }

    // New trackers may have been created as part of IO update step
    var trackersToAdd = <ElementChangeTracker>[
      ..._graphTrackers.values,
      ..._nodeTrackers.values,
      ..._edgeTrackers.values,
    ].where((tracker) => !tracker.queuedForRemoval);

    allTrackers.addAll(trackersToAdd);
  }

  void _calculateUnusedIo() {
    var nodeTrackers = allTrackers.whereType<NodeChangeTracker>().where(
      (element) => element.checkForUnusedIo,
    );

    for (var node in nodeTrackers) {
      node._performUnusedIoCheck();
    }
  }

  void _performGraphLayoutUpdates() {
    var graphsToUpdate = allTrackers.whereType<GraphChangeTracker>().where(
      (tracker) => tracker.layoutUpdateQueued,
    );

    for (var toUpdate in graphsToUpdate) {
      toUpdate._performLayoutUpdate();
    }
  }
}
