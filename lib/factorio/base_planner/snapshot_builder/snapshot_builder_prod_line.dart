part of 'snapshot_builder.dart';

class SnapshotBuilderProdLineNode
    extends
        SnapshotBuilderNode<
          ProdLineNode,
          ProdLineNodeState,
          NodeDependencies,
          ProdLineNodeStateBuilder
        > {
  SnapshotBuilderProdLineNode(super.element, super.previousState);

  SnapshotBuilderProdLineNode.newNode(
    super.element,
    super.previousState,
    super.stateBuilder,
  ) : super.newElement();

  @override
  // TODO: implement state
  ProdLineNodeState get state => throw UnimplementedError();

  @override
  ProdLineNodeStateBuilder _createStateBuilder() {
    // TODO: implement _createStateBuilder
    throw UnimplementedError();
  }

  @override
  Iterable<BasePlannerElement<dynamic, dynamic>> _determineDependants() {
    // TODO: implement _determineDependants
    throw UnimplementedError();
  }

  @override
  NodeDependencies _determineDependencies() {
    // TODO: implement _determineDependencies
    throw UnimplementedError();
  }

  @override
  bool calculateIo() {
    // TODO: implement calculateIo
    throw UnimplementedError();
  }

  @override
  void removeSelf() {
    // TODO: implement removeSelf
  }
}
