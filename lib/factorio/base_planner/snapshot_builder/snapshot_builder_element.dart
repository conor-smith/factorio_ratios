part of 'snapshot_builder.dart';

abstract class SnapshotBuilderElement<
  E extends BasePlannerElement<St, dynamic>,
  St,
  D extends Dependencies,
  B extends StateBuilder<St>
>
    implements Builder<ElementAndState<E, St>> {
  final SnapshotBuilder snapshotBuilder;
  final E element;
  final ElementAndState<E, St>? oldEAndS;

  B? _cachedStateBuilder;
  D? _cachedDependencies;

  bool toRemove;
  final bool circularDependencyCheck;
  IoUpdateStatus ioUpdateStatus;

  SnapshotBuilderElement(
    this.snapshotBuilder,
    ElementAndState<E, St> this.oldEAndS,
  ) : element = oldEAndS.element,
      toRemove = false,
      circularDependencyCheck = false,
      ioUpdateStatus = IoUpdateStatus.notQueued;

  SnapshotBuilderElement.newElement(
    this.snapshotBuilder,
    this.element,
    B stateBuilder,
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
  void removeSelf();

  B _createStateBuilder();
  D _determineDependencies();
  Iterable<BasePlannerElement> _determineDependants();

  B get stateBuilder {
    _cachedStateBuilder ??= _createStateBuilder();

    return _cachedStateBuilder!;
  }

  D get cachedDependencies {
    _cachedDependencies ??= _determineDependencies();

    return _cachedDependencies!;
  }

  @override
  ElementAndState<E, St> build() {
    if (_cachedStateBuilder == null && oldEAndS != null) {
      return oldEAndS!;
    } else {
      return ElementAndState(element, _cachedStateBuilder!.build());
    }
  }
}

abstract class SnapshotBuilderNode<
  E extends NodeElement<St, dynamic>,
  St,
  D extends Dependencies,
  B extends NodeStateBuilder<St>
>
    extends SnapshotBuilderElement<E, St, D, B> {
  bool unusedIoCheck;

  SnapshotBuilderNode(super.snapshotBuilder, super.oldEAndS)
    : unusedIoCheck = false;

  SnapshotBuilderNode.newElement(
    super.snapshotBuilder,
    super.element,
    super.stateBuilder,
  ) : unusedIoCheck = true,
      super.newElement();
}
