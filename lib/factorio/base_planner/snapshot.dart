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
  final List<BasePlannerElement> _queuedIoUpdateElements = [];
  final Set<Graph> _graphsToUpdateLayout = {};

  bool get hasChanges =>
      _updatedElements.isNotEmpty || _removedElements.isNotEmpty;
  SnapshotBuildStage get stage => _stage;

  SnapshotBuilder._from(this._previousSnapshot);

  void throwIfNotBuildingIo() {
    if (_stage != SnapshotBuildStage.buildIo) {
      throw const BasePlannerException(
        'Cannot perform this operation outside of buildIo step',
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
    var status = _elementUpdateStatus.update(
      element,
      (existingStatus) => existingStatus == UpdateStatus.checkDependencies
          ? UpdateStatus.required
          : existingStatus,
      ifAbsent: () => UpdateStatus.required,
    );

    if (_stage == SnapshotBuildStage.buildIo && !status.isComplete) {
      _queuedIoUpdateElements.add(element);
    }
  }

  UpdateStatus getUpdateStatus(BasePlannerElement element) =>
      _elementUpdateStatus.update(
        element,
        (existingStatus) => UpdateStatus.checkDependencies,
      );

  Dependencies getCachedDependencies(BasePlannerElement element) =>
      _cachedDependencies.putIfAbsent(
        element,
        () => element.determineDependencies(),
      );

  void queueLayoutUpdate(Graph graph) => _graphsToUpdateLayout.add(graph);

  @override
  Snapshot build() {
    _newElements.removeAll(_removedElements);

    for (var removedElement in _removedElements) {
      _elementUpdateStatus.remove(removedElement);
    }

    if (_newElements.isNotEmpty) {
      _checkForCircularDependencies();
    }
    if (_elementUpdateStatus.isNotEmpty) {
      _performIoUdpates();
    }

    Map<BasePlannerElement, dynamic> newStateMap = Map.from(
      _previousSnapshot.states,
    );

    for (var removedElement in _removedElements) {
      removedElement.cancelStateBuilder();
      _updatedElements.remove(removedElement);
      newStateMap.remove(removedElement);
    }

    var updatedStates = _updatedElements.map(
      (element, builder) => MapEntry(element, builder.build()),
    );
    newStateMap.addAll(updatedStates);

    return Snapshot._(newStateMap);
  }

  void _checkForCircularDependencies() {
    _stage = SnapshotBuildStage.circularDependencyCheck;

    Set<BasePlannerElement> safeElements = {};

    for (var element in _newElements) {
      element.checkForCircularDependencies(safeElements, {});
    }
  }

  void _performIoUdpates() {
    _stage = SnapshotBuildStage.buildIo;

    _queuedIoUpdateElements.addAll(_elementUpdateStatus.keys);

    while (_queuedIoUpdateElements.isNotEmpty) {
      var toUpdate = _queuedIoUpdateElements.first;
      var updateStatus = getUpdateStatus(toUpdate);

      // If element is already completed or removed, remove from queue and restart loop
      if (updateStatus.isComplete) {
        _queuedIoUpdateElements.removeAt(0);

        continue;
      }

      var dependencies = getCachedDependencies(toUpdate);

      // If unresolved dependencies exist,
      // Place said dependencies at front of queue and restart loop
      var unresolvedDeps = dependencies.allDependencies
          .where((dependency) => !getUpdateStatus(dependency).isComplete)
          .toList();
      if (unresolvedDeps.isNotEmpty) {
        _queuedIoUpdateElements.insertAll(0, unresolvedDeps);
        continue;
      }

      // If io update is required, or if one or more dependencies was updated
      // Perform IO update operation.
      // Otherwise, mark element as completed with no update
      // Remove element from front of queue in both scenarios
      var updateRequired =
          updateStatus == UpdateStatus.required ||
          dependencies.allDependencies.any(
            (dependency) =>
                getUpdateStatus(dependency) == UpdateStatus.completeUpdate,
          );

      if (updateRequired && toUpdate.updateIo(dependencies)) {
        _elementUpdateStatus[toUpdate] = UpdateStatus.completeUpdate;

        _queuedIoUpdateElements.addAll(toUpdate.determineDependants());
      } else {
        _elementUpdateStatus[toUpdate] = UpdateStatus.completeNoUpdate;
      }

      _queuedIoUpdateElements.removeAt(0);
    }
  }
}

enum UpdateStatus {
  checkDependencies(false, 1),
  required(false, 2),
  completeNoUpdate(true, 3),
  completeUpdate(true, 4);

  final bool isComplete;
  final int priority;

  const UpdateStatus(this.isComplete, this.priority);
}

enum SnapshotBuildStage {
  userOperations,
  circularDependencyCheck,
  buildIo,
  updateGraphLayouts,
  buildStates,
}
