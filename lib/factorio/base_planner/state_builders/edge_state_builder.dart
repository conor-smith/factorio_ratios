part of 'state_builders.dart';

class EdgeStateBuilder implements StateBuilder<EdgeState>, EdgeState {
  final Edge edge;

  bool _removingSelf = false;

  double _amount;
  double _percentage;
  EdgeGeometryImpl _geometry;

  @override
  double get amount => _amount;
  @override
  double get percentage => _percentage;
  @override
  EdgeGeometryImpl get geometry => _geometry;

  EdgeStateBuilder.from(this.edge, EdgeStateImpl previousState)
    : _amount = previousState.amount,
      _percentage = previousState.percentage,
      _geometry = previousState.geometry {
    edge.basePlanner.getSnapshotBuilder().addToSnapsnot(edge, this);
  }

  @override
  void addSelf() {
    edge.parentGraph.getStateBuilder()._addEdge(edge);
    edge.parent.getStateBuilder()._addChild(edge);
    edge.child.getStateBuilder()._addParent(edge);
  }

  @override
  void removeSelf() {
    if (!_removingSelf) {
      _removingSelf = true;
      edge.basePlanner.getSnapshotBuilder().removeFromSnapshot(edge);

      edge.parentGraph.getStateBuilder()._removeEdge(edge);

      edge.parent.getStateBuilder()._removeChild(edge);
      edge.child.getStateBuilder()._removeParent(edge);
    }
  }

  void updateAmount(double amount) => _amount = amount;
  void updatePercentage(double percentage) => _percentage = percentage;

  void updateGeometry(EdgeGeometryImpl geometry) => _geometry = geometry;

  @override
  EdgeStateImpl build() => EdgeStateImpl(
    edge,
    amount: amount,
    percentage: _percentage,
    geometry: _geometry,
  );
}
