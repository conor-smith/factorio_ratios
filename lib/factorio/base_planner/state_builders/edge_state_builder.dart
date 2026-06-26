part of 'state_builders.dart';

class EdgeStateBuilder implements StateBuilder<EdgeState>, EdgeState {
  final Edge _edge;

  double _amount;
  double _percentage;
  EdgeGeometryImpl _geometry;

  @override
  double get amount => _amount;
  @override
  double get percentage => _percentage;
  @override
  EdgeGeometryImpl get geometry => _geometry;

  EdgeStateBuilder.from(this._edge, EdgeStateImpl previousState)
    : _amount = previousState.amount,
      _percentage = previousState.percentage,
      _geometry = previousState.geometry {
    _edge.basePlanner.getSnapshotBuilder().addToSnapsnot(_edge, this);
  }

  @override
  void addSelf() {
    _edge.parentGraph.getStateBuilder()._addEdge(_edge);
    _edge.parent.getStateBuilder()._addChild(_edge);
    _edge.child.getStateBuilder()._addParent(_edge);

    // TODO - Technically, only the edges have to be updated rather than the whole thing.
    // Figure out how to optimise this later
    if (_amount != 0) {
      _edge.basePlanner.getSnapshotBuilder().queueNodeIoUpdate(
        switch (_edge.edgeType) {
          EdgeType.requestItems => _edge.parentProdLineNode,
          EdgeType.pushExcess => _edge.childProdLineNode,
        },
      );
    }
  }

  @override
  void removeSelf() {
    _edge.basePlanner.getSnapshotBuilder().removeFromSnapshot(_edge);

    _edge.parentGraph.getStateBuilder()._removeEdge(_edge);

    _edge.parent.getStateBuilder()._removeChild(_edge);
    _edge.child.getStateBuilder()._removeParent(_edge);

    _edge.basePlanner.getSnapshotBuilder().queueNodeIoUpdate(
      switch (_edge.edgeType) {
        EdgeType.requestItems => _edge.childProdLineNode,
        EdgeType.pushExcess => _edge.parentProdLineNode,
      },
    );
  }

  void updatePercentage(double percentage) => _percentage = percentage;
  void updateGeometry(EdgeGeometryImpl geometry) => _geometry = geometry;

  @override
  EdgeStateImpl build() => EdgeStateImpl(
    _edge,
    amount: amount,
    percentage: _percentage,
    geometry: _geometry,
  );

  @override
  void _parentGraphRemoval() {
    _edge.basePlanner.getSnapshotBuilder().removeFromSnapshot(_edge);
  }

  void _updateAmount(double amount) => _amount = amount;
}
