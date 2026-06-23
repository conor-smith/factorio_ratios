part of 'edge.dart';

abstract class EdgeState {
  double? get amount;
  double get percentage;

  EdgeGeometryImpl get edgeGeometry;
}

class EdgeStateImpl implements EdgeState, ToJson {
  @override
  final double? amount;
  @override
  final double percentage;

  @override
  final EdgeGeometryImpl edgeGeometry;

  EdgeStateImpl._initial({
    required this.amount,
    required this.percentage,
    required this.edgeGeometry,
  });

  EdgeStateImpl._(
    Edge edge, {
    required this.amount,
    required this.percentage,
    required this.edgeGeometry,
  }) {
    if (percentage > 1.0 || percentage < 0.0) {
      throw EdgeException('Edge $edge had invalid percentage: $percentage');
    }

    if (amount != null && amount! < 0) {
      throw EdgeException('Edge $edge had invalid amount: $amount');
    }
  }

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class EdgeStateBuilder implements StateBuilder<EdgeStateImpl>, EdgeState {
  final Edge _edge;

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

  EdgeStateBuilder._from(this._edge)
    : _amount = _edge._state.amount,
      _percentage = _edge._state.percentage,
      _edgeGeometry = _edge._state.edgeGeometry {
    _edge._basePlanner.getSnapshotBuilder().addToSnapsnot(_edge, this);
  }

  @override
  void addSelf() {
    _edge.parentGraph.getStateBuilder().addEdge(_edge);
    _edge.parent.getStateBuilder().addChild(_edge);
    _edge.child.getStateBuilder().addParent(_edge);
  }

  @override
  void removeSelf() {
    if (!_removingSelf) {
      _removingSelf = true;
      _edge._basePlanner.getSnapshotBuilder().removeFromSnapshot(_edge);

      _edge.parentGraph.getStateBuilder().removeEdge(_edge);

      _edge.parent.getStateBuilder().removeChild(_edge);
      _edge.parentItemNode.getStateBuilder().removeChild(_edge);
      _edge.child.getStateBuilder().removeParent(_edge);
      _edge.childItemNode.getStateBuilder().removeParent(_edge);
    }
  }

  void updateAmount(double amount) => _amount = amount;
  void clearAmount() => _amount = 0;
  void updatePercentage(double percentage) => _percentage = percentage;

  void updateGeometry(EdgeGeometryImpl edgeGeometry) =>
      _edgeGeometry = edgeGeometry;

  @override
  EdgeStateImpl build() => EdgeStateImpl._(
    _edge,
    amount: amount,
    percentage: _percentage,
    edgeGeometry: _edgeGeometry,
  );
}
