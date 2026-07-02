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

  Set<BasePlannerElement> _updateQueue = {};
  final Map<BasePlannerElement, UpdateStatus> _elementUpdateStatus = {};
  final Set<ProdLineNode> _nodesToCheckUnfulfilledIo = {};
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

  void updateIoSatusAndQueue(
    BasePlannerElement element,
    UpdateStatus updateStatus, [
    bool overrideComplete = false,
  ]) {
    var finalSatus = _elementUpdateStatus.update(element, (previousStatus) {
      if (overrideComplete && previousStatus.isComplete) {
        return updateStatus;
      } else {
        return updateStatus.priority > previousStatus.priority
            ? updateStatus
            : previousStatus;
      }
    }, ifAbsent: () => updateStatus);

    if (!finalSatus.isComplete) {
      _updateQueue.add(element);
    }
  }

  UpdateStatus getUpdateStatus(BasePlannerElement element) =>
      _elementUpdateStatus.putIfAbsent(
        element,
        () => UpdateStatus.checkDependencies,
      );

  void queueLayoutUpdate(Graph graph) => _graphsToUpdateLayout.add(graph);

  void queueUnfulfilledIoCheck(ProdLineNode node) =>
      _nodesToCheckUnfulfilledIo.add(node);

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
  userOperations,
  buildIo,
  updateGraphLayouts,
  buildStates,
}
