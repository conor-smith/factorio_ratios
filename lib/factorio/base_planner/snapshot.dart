part of 'base_planner.dart';

/// Represents a snapshot of all states of elements in [BasePlanner].
class Snapshot {
  final Map<BasePlannerElement, dynamic> states;

  Snapshot._(Map<BasePlannerElement, dynamic> states)
    : states = Map.unmodifiable(states);
}

/// Builds a snapshot in 3 stages.
///
/// ### Spec update
/// Users can add and remove elements, update geometry, etc.
/// They can also set and update internal constraints on relevant nodes.
/// However, no updates to item flow (ioData, edge amounts, etc) may
/// take place during this time
///
/// ### Snapshot building
/// This occurs once [build] is called. At this point, the user is locked out
/// from making any more changes. It is because of this that we can now safely
/// calculate node itemIo and edge amounts. New edges and nodes will be created
/// to satisfy any unfulfilled IO of any node. It is only during this step that
/// cyclical dependencies will be checked for. Despite this, ioData will not yet
/// be calculated, as some itemIo data will need to be redone multiple times,
/// and it's best to avoid unnecessary work.
///
/// ### Element building
/// It is here that all the [BasePlannerElement.state] items will be built.
/// Final validation will occur as well. Once complete, a new snapshot will
/// be added to the [BasePlanner].
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
