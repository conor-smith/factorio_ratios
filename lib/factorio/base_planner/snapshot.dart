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

  final Map<BasePlannerElement, _StatusAndDeps> _elementUpdateStatus = {};
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

  void queueRequiredIoUpdate(BasePlannerElement element) =>
      _elementUpdateStatus[element] = _StatusAndDeps(UpdateStatus.required);

  Dependencies getCachedDependencies(BasePlannerElement element) {
    var statusAndDeps = _elementUpdateStatus[element]!;

    statusAndDeps.cachedDeps ??= element.determineDependencies();

    return statusAndDeps.cachedDeps!;
  }

  void queueLayoutUpdate(Graph graph) => _graphsToUpdateLayout.add(graph);

  @override
  Snapshot build() {
    if (_newElements.isNotEmpty) {
      _stage = SnapshotBuildStage.circularDependencyCheck;

      Set<BasePlannerElement> safeElements = {};

      for (var element in _newElements) {
        element.checkForCircularDependencies(safeElements, {});
      }
    }

    _stage = SnapshotBuildStage.buildIo;

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

class _StatusAndDeps {
  UpdateStatus status;
  Dependencies? cachedDeps;

  _StatusAndDeps(this.status);
}
