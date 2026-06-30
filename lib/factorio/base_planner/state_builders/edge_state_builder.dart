part of 'state_builders.dart';

class EdgeStateBuilder implements StateBuilder<EdgeState>, EdgeState {
  final Edge _edge;

  double _amount;
  double _requestedAmount;
  double _percentage;
  int _parentPriority;
  int _childPriority;
  EdgeGeometryImpl _geometry;

  @override
  double get amount => _amount;
  @override
  double get requestedAmount => _requestedAmount;
  @override
  double get percentage => _percentage;
  @override
  int get parentPriority => _parentPriority;
  @override
  int get childPriority => _childPriority;
  @override
  EdgeGeometryImpl get geometry => _geometry;

  EdgeStateBuilder.initial(this._edge)
    : _amount = 0,
      _requestedAmount = 0,
      _percentage = 0,
      _parentPriority = 0,
      _childPriority = 0,
      _geometry = EdgeGeometryImpl.uninitialised {
    if (_edge.edgeType == EdgeType.requestExcess) {
      _parentPriority = 1;
      _childPriority = 1;
    } else {
      _percentage = 1.0;
    }

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
      _parentPriority = previousState.parentPriority,
      _childPriority = previousState.childPriority,
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
    parentPriority: _parentPriority,
    childPriority: _childPriority,
    geometry: _geometry,
  );
}
