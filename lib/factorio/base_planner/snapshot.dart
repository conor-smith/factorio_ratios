part of 'base_planner.dart';

/// Represents a snapshot of all states of elements in [BasePlanner].
class Snapshot {
  final Map<BasePlannerElement, dynamic> states;

  Snapshot._(Map<BasePlannerElement, dynamic> states)
    : states = Map.unmodifiable(states);
}

// TODO - Document
class SnapshotBuilder implements Builder<Snapshot> {
  final Snapshot _previousSnapshot;

  SnapshotBuildStage _stage = SnapshotBuildStage.userOperations;

  final Map<BasePlannerElement, Builder> _updatedElements = {};
  final Set<BasePlannerElement> _newElements = {};
  final Set<BasePlannerElement> _removedElements = {};

  final Map<BasePlannerElement, Dependencies> _cachedDependencies = {};
  final Map<BasePlannerElement, UpdateStatus> _elementUpdateStatus = {};
  final Set<Graph> _graphsToUpdateLayout = {};

  bool get hasChanges =>
      _updatedElements.isNotEmpty || _removedElements.isNotEmpty;
  SnapshotBuildStage get stage => _stage;

  SnapshotBuilder._from(this._previousSnapshot);

  void throwIfNotStage(SnapshotBuildStage stage) {
    if (_stage != stage) {
      throw BasePlannerException(
        'Can only perform this operation at stage $stage. Current stage is $_stage',
      );
    }
  }

  void addToSnapshot(BasePlannerElement element, Builder builder) =>
      _updatedElements[element] = builder;

  void queueCircularDependencyCheck(BasePlannerElement element) =>
      _newElements.add(element);

  void removeFromSnapshot(BasePlannerElement element) =>
      _removedElements.add(element);

  void queueRequiredIoUpdate(BasePlannerElement element) {
    if (_stage != SnapshotBuildStage.userOperations) {
      throw BasePlannerException(
        'Attempted to queue IO operation on $element after user operation stage',
      );
    }

    _elementUpdateStatus[element] = UpdateStatus.required;
  }

  Dependencies getCachedDependencies(BasePlannerElement element) =>
      _cachedDependencies.putIfAbsent(
        element,
        () => element.determineDependencies(),
      );

  void queueLayoutUpdate(Graph graph) => _graphsToUpdateLayout.add(graph);

  @override
  Snapshot build() {
    for (var removedElement in _removedElements) {
      _newElements.remove(removedElement);
      _elementUpdateStatus.remove(removedElement);
    }

    _checkForCircularDependencies();
    _performIoUdpates();
    _performGraphLayoutUpdates();
    var newStateMap = _performStateUpdateAndReturnMap();

    return Snapshot._(newStateMap);
  }

  UpdateStatus _getOrCreateUpdateStatus(BasePlannerElement element) =>
      _elementUpdateStatus.putIfAbsent(
        element,
        () => UpdateStatus.checkDependencies,
      );

  void _checkForCircularDependencies() {
    _stage = SnapshotBuildStage.circularDependencyCheck;

    Set<BasePlannerElement> safeElements = {};

    for (var element in _newElements) {
      element.checkForCircularDependencies(safeElements, {});
    }
  }

  void _performIoUdpates() {
    _stage = SnapshotBuildStage.buildIo;

    Queue<BasePlannerElement> updateQueue = Queue.from(
      _elementUpdateStatus.keys,
    );

    while (updateQueue.isNotEmpty) {
      var toUpdate = updateQueue.removeFirst();
      var updateStatus = _getOrCreateUpdateStatus(toUpdate);

      // If element is already completed, restart loop
      if (updateStatus.isComplete) {
        continue;
      }

      var dependencies = getCachedDependencies(toUpdate);

      // If unresolved dependencies exist,
      // Place said dependencies at front of queue and restart loop
      var unresolvedDeps = dependencies.allDependencies
          .where(
            (dependency) => !_getOrCreateUpdateStatus(dependency).isComplete,
          )
          .toList();
      if (unresolvedDeps.isNotEmpty) {
        updateQueue.addFirst(toUpdate);
        for (var dep in unresolvedDeps) {
          updateQueue.addFirst(dep);
        }

        continue;
      }

      // An IO update is required in two scenarios
      // 1. Explicitly marked as required via UpdateStatus.required
      // 2. One or more dependencies have were updated
      var updateRequired =
          updateStatus == UpdateStatus.required ||
          dependencies.allDependencies.any(
            (dependency) =>
                _getOrCreateUpdateStatus(dependency) ==
                UpdateStatus.completeUpdate,
          );

      // If update is required and update returns true, add dependents to end of queue
      // Otherwise, mark element as completeNoUpdate
      // Remove element from queue in both scenarios
      if (updateRequired && toUpdate.calculateIo(dependencies)) {
        _elementUpdateStatus[toUpdate] = UpdateStatus.completeUpdate;

        updateQueue.addAll(toUpdate.determineDependants());
      } else {
        _elementUpdateStatus[toUpdate] = UpdateStatus.completeNoUpdate;
      }
    }
  }

  void _performGraphLayoutUpdates() {
    _stage = SnapshotBuildStage.updateGraphLayouts;

    for (var graph in _graphsToUpdateLayout) {
      graph.defaultLayout();
    }
  }

  Map<BasePlannerElement, dynamic> _performStateUpdateAndReturnMap() {
    _stage = SnapshotBuildStage.buildStates;

    Map<BasePlannerElement, dynamic> newStateMap = Map.from(
      _previousSnapshot.states,
    );

    for (var removedElement in _removedElements) {
      removedElement.cancelStateBuilder();
      newStateMap.remove(removedElement);
    }

    var updatedStates = _updatedElements.map(
      (element, builder) => MapEntry(element, builder.build()),
    );
    newStateMap.addAll(updatedStates);

    return newStateMap;
  }
}

enum UpdateStatus {
  checkDependencies(false),
  required(false),
  completeNoUpdate(true),
  completeUpdate(true);

  final bool isComplete;

  const UpdateStatus(this.isComplete);
}

enum SnapshotBuildStage {
  userOperations,
  circularDependencyCheck,
  buildIo,
  updateGraphLayouts,
  buildStates,
}
