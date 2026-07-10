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
    if (_graphsToUpdateLayout.isNotEmpty) {
      _stage = SnapshotBuildStage.updateGraphLayouts;

      for (var graph in _graphsToUpdateLayout) {
        graph.defaultLayout();
      }
    }

    _stage = SnapshotBuildStage.buildStates;

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

    List<BasePlannerElement> updateQueue = List.from(_elementUpdateStatus.keys);

    while (updateQueue.isNotEmpty) {
      var toUpdate = updateQueue.first;
      var updateStatus = _getOrCreateUpdateStatus(toUpdate);

      // If element is already completed or removed, remove from queue and restart loop
      if (updateStatus.isComplete) {
        updateQueue.removeAt(0);

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
        updateQueue.insertAll(0, unresolvedDeps);
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
      if (updateRequired && toUpdate.updateIo(dependencies)) {
        _elementUpdateStatus[toUpdate] = UpdateStatus.completeUpdate;

        updateQueue.addAll(toUpdate.determineDependants());
      } else {
        _elementUpdateStatus[toUpdate] = UpdateStatus.completeNoUpdate;
      }

      updateQueue.removeAt(0);
    }
  }

  UpdateStatus _getOrCreateUpdateStatus(BasePlannerElement element) =>
      _elementUpdateStatus.putIfAbsent(
        element,
        () => UpdateStatus.checkDependencies,
      );
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
