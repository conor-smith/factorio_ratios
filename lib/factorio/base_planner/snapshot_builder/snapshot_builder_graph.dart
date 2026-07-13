part of 'snapshot_builder.dart';

class SnapshotBuilderGraph
    extends
        SnapshotBuilderNode<
          Graph,
          GraphState,
          GraphDependencies,
          GraphStateBuilder
        > {
  SnapshotBuilderGraph(super.element, super.previousState);

  SnapshotBuilderGraph.newGraph(
    super.element,
    super.previousState,
    super.stateBuilder,
  ) : super.newElement();

  @override
  // TODO: implement state
  GraphState get state => _cachedStateBuilder ?? previousState;

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
  Iterable<BasePlannerElement<dynamic, dynamic>> _determineDependants() {
    // TODO: implement _determineDependants
    throw UnimplementedError();
  }

  @override
  GraphDependencies _determineDependencies() {
    // TODO: implement _determineDependencies
    throw UnimplementedError();
  }

  @override
  GraphStateBuilder _createStateBuilder() {
    // TODO: implement _createStateBuilder
    throw UnimplementedError();
  }
}
