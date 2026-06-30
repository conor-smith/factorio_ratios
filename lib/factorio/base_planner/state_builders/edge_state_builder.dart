part of 'state_builders.dart';

class EdgeStateBuilder implements StateBuilder<EdgeState>, EdgeState {
  final Edge _edge;

  double _amount;
  double _requestedAmount;
  double _percentage;
  int _priority;
  EdgeGeometryImpl _geometry;

  @override
  double get amount => _amount;
  @override
  double get requestedAmount => _requestedAmount;
  @override
  double get percentage => _percentage;
  @override
  int get priority => _priority;
  @override
  EdgeGeometryImpl get geometry => _geometry;

  EdgeStateBuilder.initial(this._edge)
    : _amount = 0,
      _requestedAmount = 0,
      _percentage = _edge.edgeType.usesPriority ? 0 : 1,
      _priority = _edge.edgeType.usesPriority ? 1 : 0,
      _geometry = EdgeGeometryImpl.uninitialised {
    _edge.basePlanner.throwIfMutationNotPermitted();
    _edge.basePlanner.getSnapshotBuilder().addToSnapshot(_edge, this);

    _edge.parentGraph.getStateBuilder()._edges.add(_edge);

    _edge.parentProdLine.getStateBuilder()._children.update(
      _edge.item,
      (edges) => edges..add(_edge),
      ifAbsent: () => {_edge},
    );

    _edge.childProdLine.getStateBuilder()._parents.update(
      _edge.item,
      (edges) => edges..add(_edge),
      ifAbsent: () => {_edge},
    );

    // If parent is a graph, this just creates a new statebuilder
    // This ensures graph.parents and graph.children, which are determined dynamically, are updated
    _edge.parent.getStateBuilder();
    _edge.child.getStateBuilder();
  }

  EdgeStateBuilder.from(this._edge, EdgeStateImpl previousState)
    : _amount = previousState.amount,
      _percentage = previousState.percentage,
      _priority = previousState.priority,
      _geometry = previousState.geometry,
      _requestedAmount = previousState.requestedAmount {
    _edge.basePlanner.getSnapshotBuilder().addToSnapshot(_edge, this);
  }

  @override
  void removeSelf() {
    _edge.basePlanner.getSnapshotBuilder().removeFromSnapshot(_edge);

    _edge.parentProdLine.getStateBuilder()._children[_edge.item]?.remove(_edge);
    _edge.childProdLine.getStateBuilder()._parents[_edge.item]?.remove(_edge);
    _edge.parentGraph.getStateBuilder()._edges.remove(_edge);

    // If parent is a graph, this just creates a new statebuilder
    // This ensures graph.parents and graph.children, which are determined dynamically, are updated
    _edge.parent.getStateBuilder();
    _edge.child.getStateBuilder();
  }

  void updatePercentage(double percentage) => _percentage = percentage;
  void updateGeometry(EdgeGeometryImpl geometry) => _geometry = geometry;

  @override
  EdgeStateImpl build() => EdgeStateImpl(
    _edge,
    amount: _amount,
    requestedAmount: _requestedAmount,
    percentage: _percentage,
    priority: _priority,
    geometry: _geometry,
  );
}
