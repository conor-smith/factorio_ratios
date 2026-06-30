part of 'state_builders.dart';

class EdgeStateBuilder implements StateBuilder<EdgeState>, EdgeState {
  final Edge _edge;

  double _amount;
  double _requestedAmount;
  double _percentage;
  int _parentPriority;
  int _childPriority;
  EdgeGeometryImpl _geometry;

  IoUpdateStatus _ioUpdateStatus;

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

  @override
  IoUpdateStatus get ioUpdateStatus => _ioUpdateStatus;

  EdgeStateBuilder.initial(this._edge)
    : _amount = 0,
      _requestedAmount = 0,
      _percentage = 0,
      _parentPriority = 0,
      _childPriority = 0,
      _geometry = EdgeGeometryImpl.uninitialised,
      _ioUpdateStatus = IoUpdateStatus.pending {
    if (_edge.edgeType == EdgeType.requestExcess) {
      _parentPriority = 1;
      _childPriority = 1;
    } else {
      _percentage = 1.0;
    }

    _edge.basePlanner.getSnapshotBuilder().addToSnapshot(_edge, this);
    _edge.basePlanner.getSnapshotBuilder()
      ..addToSnapshot(_edge, this)
      ..queueIoUpdate(_edge);

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
      _requestedAmount = previousState.requestedAmount,
      _ioUpdateStatus = IoUpdateStatus.notRequired {
    _edge.basePlanner.getSnapshotBuilder().addToSnapshot(_edge, this);
  }

  @override
  void _queueIoUpdate() {
    if (_ioUpdateStatus == IoUpdateStatus.notRequired) {
      _ioUpdateStatus = IoUpdateStatus.pending;
      _edge.basePlanner.getSnapshotBuilder().queueIoUpdate(_edge);
    }
  }

  @override
  void performIoUpdate() {
    // TODO: implement performIoUpdate
  }

  @override
  void removeSelf() {
    _edge.basePlanner.getSnapshotBuilder().removeFromSnapshot(_edge);

    _edge.parentProdLine.getStateBuilder()._children[_edge.item]!.remove(_edge);
    _edge.childProdLine.getStateBuilder()._parents[_edge.item]!.remove(_edge);
    _edge.parentGraph.getStateBuilder()._edges.remove(_edge);

    switch (_edge.edgeType) {
      case EdgeType.requestItems:
        _edge.childProdLine.getStateBuilder()._queueIoUpdate();

      case EdgeType.pushExcess:
        _edge.parentProdLine.getStateBuilder()._queueIoUpdate();

      case EdgeType.requestExcess:
        var edgesToUpdate = _edge.parentProdLine.children[_edge.item]!
            .where((edge) => edge.edgeType == EdgeType.requestItems)
            .followedBy(
              _edge.childProdLine.parents[_edge.item]!.where(
                (edge) => edge.edgeType == EdgeType.pushExcess,
              ),
            );

        for (var toUpdate in edgesToUpdate) {
          toUpdate.getStateBuilder()._queueIoUpdate();
        }
    }

    // If parent is a graph, this just creates a new statebuilder
    // This ensures graph.parents and graph.children, which are determined dynamically, are updated
    _edge.parent.getStateBuilder();
    _edge.child.getStateBuilder();
  }

  void updatePercentage(double newPercentage) {
    if (_percentage != newPercentage) {
      _percentage = newPercentage;
      _queueIoUpdate();
    }
  }

  void updateParentPriority(int newPriority) {
    if (_parentPriority != newPriority) {
      _parentPriority = newPriority;
      _queueIoUpdate();
    }
  }

  void updateChildPriority(int newPriority) {
    if (_childPriority != newPriority) {
      _childPriority = newPriority;
      _queueIoUpdate();
    }
  }

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

  void _queueChildrenAffectedByRemoval() {
    switch (_edge.edgeType) {
      case EdgeType.requestItems:
        _edge.childProdLine.getStateBuilder()._queueIoUpdate();

      case EdgeType.requestExcess:
        var edgesToUpdate = _edge.childProdLine.parents[_edge.item]!.where(
          (edge) => edge.edgeType == EdgeType.pushExcess,
        );

        for (var toUpdate in edgesToUpdate) {
          toUpdate.getStateBuilder()._queueIoUpdate();
        }

      case EdgeType.pushExcess:
        break;
    }
  }

  void _queueParentsAffectedByRemoval() {
    switch (_edge.edgeType) {
      case EdgeType.pushExcess:
        _edge.parentProdLine.getStateBuilder()._queueIoUpdate();

      case EdgeType.requestExcess:
        var edgesToUpdate = _edge.parentProdLine.children[_edge.item]!.where(
          (edge) => edge.edgeType == EdgeType.requestItems,
        );

        for (var toUpdate in edgesToUpdate) {
          toUpdate.getStateBuilder()._queueIoUpdate();
        }

      case EdgeType.requestItems:
        break;
    }
  }
}
