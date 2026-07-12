part of 'snapshot_builder.dart';

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
