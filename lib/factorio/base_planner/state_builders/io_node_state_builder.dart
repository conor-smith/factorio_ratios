part of 'state_builders.dart';

class IoNodeStateBuilder extends AbstractNodeStateBuilder<IoNodeStateImpl>
    implements IoNodeState {
  @override
  final IoNode node;

  IoNodeIo? _io;

  @override
  IoNodeIo? get io => _io;

  IoNodeStateBuilder.from(this.node, IoNodeStateImpl previousState)
    : _io = node.io,
      super.from(node, previousState) {
    node.basePlanner.getSnapshotBuilder().addToSnapsnot(node, this);
  }

  @override
  void addSelf() {
    node.parentGraph.getStateBuilder()._addIoNode(node);
  }

  @override
  void removeSelf() {
    super.removeSelf();

    node.parentGraph.getStateBuilder()._removeIoNode(node);
  }

  @override
  ProductionLine<ProductionLineIo> get productionLine => node;

  @override
  void calculateIo(ItemIo constraints) {
    _io = node.calculate(constraints);
    clearParentIo();
  }

  @override
  void clearIo() {
    _io = null;
    clearParentIo();
  }

  @override
  IoNodeStateImpl build() => IoNodeStateImpl(
    node,
    io: io,
    geometry: geometry,
    parents: parents,
    children: children,
  );
}
