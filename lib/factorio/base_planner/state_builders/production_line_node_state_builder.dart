part of 'state_builders.dart';

class ProdLineNodeStateBuilder
    extends AbstractNodeStateBuilder<ProdLineNodeStateImpl>
    implements ProdLineNodeState {
  @override
  final ProdLineNode node;

  ItemIo? _requirements;
  ProductionLine _productionLine;
  ProductionLineIo? _io;

  @override
  ItemIo? get requirements => _requirements;
  @override
  ProductionLine get productionLine => _productionLine;
  @override
  ProductionLineIo? get io => _io;

  ProdLineNodeStateBuilder.from(this.node, ProdLineNodeStateImpl previousState)
    : _requirements = previousState.requirements,
      _productionLine = previousState.productionLine,
      super.from(node, previousState) {
    node.basePlanner.getSnapshotBuilder().addToSnapsnot(node, this);
  }

  @override
  void addSelf() {
    node.parentGraph.getStateBuilder()._addProdLineNode(node);
  }

  @override
  void removeSelf() {
    super.removeSelf();

    node.parentGraph.getStateBuilder()._removeProdLineNode(node);
  }

  void updateRequirements(ItemIo requirements) => _requirements = requirements;
  void clearRequirements() => _requirements = null;

  void updateProductionLine(ProductionLine newProdLine) {
    // Remove any edges that can no longer connect
    var parentsToRemove = _productionLine.outputItems
        .difference(newProdLine.outputItems)
        .expand(
          (removedOutput) =>
              parents.where((parent) => parent.item == removedOutput),
        );
    var childrenToRemove = _productionLine.inputItems
        .difference(newProdLine.inputItems)
        .expand(
          (removedOutput) =>
              children.where((child) => child.item == removedOutput),
        );

    for (var toRemove in parentsToRemove.followedBy(childrenToRemove)) {
      toRemove.getStateBuilder().removeSelf();
    }

    _productionLine = newProdLine;
  }

  @override
  void clearIo() {
    _io = null;
    clearParentIo();
  }

  @override
  void calculateIo(ItemIo constraints) {
    _io = productionLine.calculate(constraints);
    clearParentIo();
  }

  @override
  ProdLineNodeStateImpl build() => ProdLineNodeStateImpl(
    node,
    requirements: _requirements,
    productionLine: _productionLine,
    io: io,
    geometry: geometry,
    parents: parents,
    children: children,
  );
}
