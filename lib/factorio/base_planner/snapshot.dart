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

  final Map<BasePlannerElement, Builder> _updatedElements = {};
  final Set<BasePlannerElement> _removedElements = {};

  SnapshotBuildStage _stage = SnapshotBuildStage.userOperations;

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

  void removeFromSnapshot(BasePlannerElement element) =>
      _removedElements.add(element);

  void queueIoUpdate(
    BasePlannerElement element, {
    bool requiredUpdate = false,
  }) {
    var newStatus = requiredUpdate
        ? UpdateStatus.required
        : UpdateStatus.checkDependencies;

    _elementUpdateStatus.update(element, (existingStatus) {
      existingStatus.deps = null;

      if (existingStatus.status != UpdateStatus.required) {
        existingStatus.status = newStatus;
      }

      return existingStatus;
    }, ifAbsent: () => _StatusAndDeps(newStatus));
  }

  void queueLayoutUpdate(Graph graph) => _graphsToUpdateLayout.add(graph);

  @override
  Snapshot build() {
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
  userOperations(1),
  buildIo(2),
  updateGraphLayouts(3),
  buildStates(4);

  final int order;

  const SnapshotBuildStage(this.order);
}

class _StatusAndDeps {
  UpdateStatus status;
  Dependencies? deps;

  _StatusAndDeps(this.status);
}
