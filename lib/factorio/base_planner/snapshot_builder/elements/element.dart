part of '../snapshot_builder.dart';

abstract class SnapshotBuilderElement<
  E extends BasePlannerElement<St, dynamic>,
  St,
  D extends Dependencies,
  B extends StateBuilder<St>
>
    implements Builder<ElementAndState<E, St>> {
  final SnapshotBuilder snapshotBuilder;
  final E element;
  final St previousState;

  B? _cachedStateBuilder;
  D? _cachedDependencies;

  final bool circularDependencyCheck;
  bool _toRemove;
  IoUpdateStatus? _ioUpdateStatus;

  SnapshotBuilderElement(this.element, this.previousState)
    : snapshotBuilder = element.basePlanner.getSnapshotBuilderOrThrow(),
      _toRemove = false,
      circularDependencyCheck = false;

  SnapshotBuilderElement.newElement(
    this.element,
    this.previousState,
    B stateBuilder,
  ) : snapshotBuilder = element.basePlanner.getSnapshotBuilderOrThrow(),
      _cachedStateBuilder = stateBuilder,
      _toRemove = false,
      circularDependencyCheck = true,
      _ioUpdateStatus = IoUpdateStatus.required {
    element.parentGraph.getSnapshotBuilderElement().queueLayoutUpdate();
  }

  Object get state;

  bool calculateIo();
  Iterable<BasePlannerElement> determineDependants();
  void removeSelf();

  B _createStateBuilder();
  D _determineDependencies();
  void _removeSelfOnly();

  bool get toRemove => _toRemove;

  B get stateBuilder {
    _cachedStateBuilder ??= _createStateBuilder();

    return _cachedStateBuilder!;
  }

  D get cachedDependencies {
    _cachedDependencies ??= _determineDependencies();

    return _cachedDependencies!;
  }

  IoUpdateStatus get ioUpdateStatus {
    _ioUpdateStatus ??= IoUpdateStatus.checkDependencies;

    return _ioUpdateStatus!;
  }

  void queueIoUpdate() => _ioUpdateStatus = IoUpdateStatus.required;

  void checkForCircularDependencies(
    Set<BasePlannerElement> safeElements,
    Set<BasePlannerElement> visitedElements,
  ) {
    if (visitedElements.contains(element)) {
      throw BasePlannerException('Circular dependency detected at $element');
    }

    if (!safeElements.contains(element)) {
      visitedElements.add(element);

      for (var dependency in cachedDependencies.allDependencies) {
        dependency.getSnapshotBuilderElement().checkForCircularDependencies(
          safeElements,
          visitedElements,
        );
      }

      visitedElements.remove(element);
      safeElements.add(element);
    }
  }

  @override
  ElementAndState<E, St> build() {
    if (_cachedStateBuilder == null) {
      return ElementAndState(element, previousState);
    } else {
      return ElementAndState(element, _cachedStateBuilder!.build());
    }
  }
}

abstract class SnapshotBuilderNode<
  E extends NodeElement<St, NodeEvent>,
  St extends NodeState,
  D extends Dependencies,
  B extends NodeStateBuilder<St>
>
    extends SnapshotBuilderElement<E, St, D, B> {
  bool _unusedIoCheck;

  bool get unusedIoCheck => _unusedIoCheck;

  SnapshotBuilderNode(super.element, super.previousState)
    : _unusedIoCheck = false;

  SnapshotBuilderNode.newNode(
    super.element,
    super.previousState,
    super.stateBuilder,
  ) : _unusedIoCheck = true,
      super.newElement() {
    element.parentGraph.getSnapshotBuilderElement()._addNodeToNodeCaches(
      element,
    );
  }

  @override
  NodeState get state;

  void queueUnusedIoCheck() => _unusedIoCheck = true;

  void checkForUnusedIo() {
    var itemIo = state.ioData.itemIo;

    ItemIoBuilder unusedIoBuilder = ItemIoBuilder();

    state.parents.forEach((item, edges) {
      var unconsumedOutput =
          itemIo.outputs[item]! -
          edges.fold(0.0, (sum, edge) => sum + edge.amount);

      // Account for floating point errors
      if (unconsumedOutput > 0.000001) {
        unusedIoBuilder.addToOutputs(item, unconsumedOutput);
      }
    });

    state.children.forEach((item, edges) {
      var unfulfilledInput =
          itemIo.inputs[item]! -
          edges.fold(0.0, (sum, edge) => sum + edge.amount);

      // Account for floating point errors
      if (unfulfilledInput > 0.000001) {
        unusedIoBuilder.addToOutputs(item, unfulfilledInput);
      }
    });

    var newUnusedIo = unusedIoBuilder.build();

    if (newUnusedIo != state.unusedIo) {
      stateBuilder.updateUnusedIo(newUnusedIo);
    }
  }

  void _removeSelfAndUpdateParentGraphSnapshotBuilder() {
    element.parentGraph.getSnapshotBuilderElement()
      ..queueLayoutUpdate()
      ..queueIoUpdate()
      .._removeNodeFromNodeCaches(element);
  }
}
