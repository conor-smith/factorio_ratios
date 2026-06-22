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

  EdgeStateImpl._({
    this.amount,
    required this.percentage,
    this.edgeGeometry = EdgeGeometryImpl.uninitialised,
  });

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class EdgeStateBuilder implements Builder<EdgeStateImpl>, EdgeState {
  double? _amount;
  double _percentage;
  EdgeGeometryImpl _edgeGeometry;

  @override
  double? get amount => _amount;
  @override
  double get percentage => _percentage;
  @override
  EdgeGeometryImpl get edgeGeometry => _edgeGeometry;

  factory EdgeStateBuilder._new(Edge edge) {
    var builder = EdgeStateBuilder._from(edge);

    edge.parentGraph.getStateBuilder().addEdge(edge);

    edge.parent.getStateBuilder().addChild(edge);
    edge.child.getStateBuilder().addParent(edge);

    edge.parentProductionLine.getStateBuilder().addChild(edge);
    edge.childProductionLine.getStateBuilder().addParent(edge);

    return builder;
  }

  static void _remove(Edge edge) {
    edge.parentGraph.getStateBuilder().removeEdge(edge);

    edge.parent.getStateBuilder().removeChild(edge);
    edge.child.getStateBuilder().removeParent(edge);

    edge.parentProductionLine.getStateBuilder().removeChild(edge);
    edge.childProductionLine.getStateBuilder().removeParent(edge);
  }

  EdgeStateBuilder._from(Edge edge)
    : _amount = edge._state.amount,
      _percentage = edge._state.percentage,
      _edgeGeometry = edge._state.edgeGeometry {
    edge._basePlanner.getSnapshotBuilder().addToSnapsnot(edge, this);
  }

  void updateAmount(double amount) => _amount = amount;
  void clearAmount() => _amount = 0;
  void updatePercentage(double percentage) => _percentage = percentage;

  void updateGeometry(EdgeGeometryImpl edgeGeometry) =>
      _edgeGeometry = edgeGeometry;

  @override
  EdgeStateImpl build() => EdgeStateImpl._(
    amount: amount,
    percentage: _percentage,
    edgeGeometry: _edgeGeometry,
  );
}
