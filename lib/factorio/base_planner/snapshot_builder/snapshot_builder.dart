// TODO - Document
import 'dart:collection';

import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/factorio/base_planner/node/node.dart';
import 'package:factorio_ratios/factorio/base_planner/state_builders/state_builders.dart';
import 'package:factorio_ratios/utility/builder.dart';

class SnapshotBuilder implements Builder<Snapshot> {
  final Snapshot _previousSnapshot;

  SnapshotBuildStage _stage = SnapshotBuildStage.userOperations;

  final Map<BasePlannerElement, Builder> _updatedElements = {};
  final Set<BasePlannerElement> _newElements = {};
  final Set<BasePlannerElement> _removedElements = {};

  final Map<BasePlannerElement, Dependencies> _cachedDependencies = {};

  final Map<BasePlannerElement, IoUpdateStatus> _elementUpdateStatus = {};
  final Set<NodeElement> _nodesToCheckUnusedIo = {};

  final Set<Graph> _graphsToUpdateLayout = {};

  bool get hasChanges =>
      _updatedElements.isNotEmpty || _removedElements.isNotEmpty;
  SnapshotBuildStage get stage => _stage;

  SnapshotBuilder.from(this._previousSnapshot);

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

    _elementUpdateStatus[element] = IoUpdateStatus.required;
  }

  void queueUnusedIoCheck(NodeElement node) => _nodesToCheckUnusedIo.add(node);

  void queueLayoutUpdate(Graph graph) => _graphsToUpdateLayout.add(graph);

  Dependencies getCachedDependencies(BasePlannerElement element) =>
      _cachedDependencies.putIfAbsent(
        element,
        () => element.determineDependencies(),
      );

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

    return Snapshot(newStateMap);
  }

  IoUpdateStatus _getOrCreateUpdateStatus(BasePlannerElement element) =>
      _elementUpdateStatus.putIfAbsent(
        element,
        () => IoUpdateStatus.checkDependencies,
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
          updateStatus == IoUpdateStatus.required ||
          dependencies.allDependencies.any(
            (dependency) =>
                _getOrCreateUpdateStatus(dependency) ==
                IoUpdateStatus.completeUpdate,
          );

      // If update is required and update returns true, add dependents to end of queue
      // Otherwise, mark element as completeNoUpdate
      // Remove element from queue in both scenarios
      if (updateRequired && toUpdate.calculateIo(dependencies)) {
        _elementUpdateStatus[toUpdate] = IoUpdateStatus.completeUpdate;

        updateQueue.addAll(toUpdate.determineDependants());
      } else {
        _elementUpdateStatus[toUpdate] = IoUpdateStatus.completeNoUpdate;
      }
    }

    // Once all IO updates are done, we can check for unused IO
    for (var node in _nodesToCheckUnusedIo) {
      node.calculateUnusedIo();
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

abstract class SnapshotBuilderElement<St, D extends Dependencies>
    implements Builder<ElementAndState<St>> {
  final SnapshotBuilder snapshotBuilder;
  final BasePlannerElement<St, dynamic> element;
  final ElementAndState<St>? oldEAndS;

  StateBuilder<St>? _cachedStateBuilder;
  D? _cachedDependencies;

  bool toRemove;
  final bool circularDependencyCheck;
  IoUpdateStatus ioUpdateStatus;

  SnapshotBuilderElement(
    this.snapshotBuilder,
    ElementAndState<St> this.oldEAndS,
  ) : element = oldEAndS.element,
      toRemove = false,
      circularDependencyCheck = false,
      ioUpdateStatus = IoUpdateStatus.notQueued;

  SnapshotBuilderElement.newElement(
    this.snapshotBuilder,
    this.element,
    StateBuilder<St> stateBuilder,
  ) : oldEAndS = null,
      _cachedStateBuilder = stateBuilder,
      toRemove = false,
      circularDependencyCheck = true,
      ioUpdateStatus = IoUpdateStatus.required;

  St get state;

  bool calculateIo();
  void checkForCircularDependencies(
    Set<BasePlannerElement> safeElements,
    Set<BasePlannerElement> visitedElements,
  );
  StateBuilder<St> createStateBuilder();
  D determineDependencies();
  Iterable<BasePlannerElement> determineDependants();
  void removeSelf();

  StateBuilder<St> get stateBuilder {
    _cachedStateBuilder ??= createStateBuilder();

    return _cachedStateBuilder!;
  }

  D get cachedDependencies {
    _cachedDependencies ??= determineDependencies();

    return _cachedDependencies!;
  }

  @override
  ElementAndState<St> build() {
    if (_cachedStateBuilder == null && oldEAndS != null) {
      return oldEAndS!;
    } else {
      return ElementAndState(element, _cachedStateBuilder!.build());
    }
  }
}

enum IoUpdateStatus {
  notQueued(false),
  checkDependencies(false),
  required(false),
  completeNoUpdate(true),
  completeUpdate(true);

  final bool isComplete;

  const IoUpdateStatus(this.isComplete);
}

enum SnapshotBuildStage {
  userOperations,
  circularDependencyCheck,
  buildIo,
  updateGraphLayouts,
  buildStates,
}
