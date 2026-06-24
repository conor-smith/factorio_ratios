part of 'state_builders.dart';

class EdgeStateBuilder implements StateBuilder<EdgeState>, EdgeState {
  final Edge edge;

  bool _removingSelf = false;

  double? _amount;
  double _percentage;
  EdgeGeometryImpl _edgeGeometry;

  @override
  double? get amount => _amount;
  @override
  double get percentage => _percentage;
  @override
  EdgeGeometryImpl get edgeGeometry => _edgeGeometry;

  EdgeStateBuilder.from(this.edge, EdgeStateImpl previousState)
    : _amount = previousState.amount,
      _percentage = previousState.percentage,
      _edgeGeometry = previousState.edgeGeometry {
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
  void clearAmount() => _amount = 0;
  void updatePercentage(double percentage) => _percentage = percentage;

  void updateGeometry(EdgeGeometryImpl edgeGeometry) =>
      _edgeGeometry = edgeGeometry;

  @override
  EdgeStateImpl build() => EdgeStateImpl(
    edge,
    amount: amount,
    percentage: _percentage,
    edgeGeometry: _edgeGeometry,
  );
}
