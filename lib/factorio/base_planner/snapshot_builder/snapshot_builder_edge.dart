part of 'snapshot_builder.dart';

class SnapshotBuilderEdge
    extends
        SnapshotBuilderElement<
          Edge,
          EdgeState,
          EdgeDependencies,
          EdgeStateBuilder
        > {
  SnapshotBuilderEdge(super.element, super.previousState);

  SnapshotBuilderEdge.newEdge(
    super.element,
    super.previousState,
    super.stateBuilder,
  ) : super.newElement();

  @override
  // TODO: implement state
  EdgeState get state => throw UnimplementedError();

  @override
  void removeSelf() {
    // TODO: implement removeSelf
  }

  @override
  bool calculateIo() {
    // TODO: implement calculateIo
    throw UnimplementedError();
  }

  @override
  EdgeStateBuilder _createStateBuilder() {
    // TODO: implement _createStateBuilder
    throw UnimplementedError();
  }

  @override
  Iterable<BasePlannerElement<dynamic, dynamic>> _determineDependants() {
    // TODO: implement _determineDependants
    throw UnimplementedError();
  }

  @override
  EdgeDependencies _determineDependencies() {
    // TODO: implement _determineDependencies
    throw UnimplementedError();
  }
}
