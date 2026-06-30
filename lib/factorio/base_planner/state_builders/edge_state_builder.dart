part of 'state_builders.dart';

class EdgeStateBuilder extends StateBuilder<EdgeState> implements EdgeState {
  @override
  final Edge _element;

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

  EdgeStateBuilder.initial(this._element)
    : _amount = 0,
      _requestedAmount = 0,
      _percentage = 0,
      _parentPriority = 0,
      _childPriority = 0,
      _geometry = EdgeGeometryImpl.uninitialised,
      super.initial() {
    if (_element.edgeType == EdgeType.requestExcess) {
      _parentPriority = 1;
      _childPriority = 1;
    } else {
      _percentage = 1.0;
    }
    _queueIoUpdate();

    _element.parentGraph.getStateBuilder()._edges.add(_element);

    _element.parentProdLine.getStateBuilder()._children.update(
      _element.item,
      (edges) => edges..add(_element),
      ifAbsent: () => {_element},
    );

    _element.childProdLine.getStateBuilder()._parents.update(
      _element.item,
      (edges) => edges..add(_element),
      ifAbsent: () => {_element},
    );

    // If parent is a graph, this just creates a new statebuilder
    // This ensures graph.parents and graph.children, which are determined dynamically, are updated
    _element.parent.getStateBuilder();
    _element.child.getStateBuilder();
  }

  EdgeStateBuilder.from(this._element, EdgeStateImpl previousState)
    : _amount = previousState.amount,
      _percentage = previousState.percentage,
      _parentPriority = previousState.parentPriority,
      _childPriority = previousState.childPriority,
      _geometry = previousState.geometry,
      _requestedAmount = previousState.requestedAmount;

  @override
  void removeSelf() {
    _snapshotBuilder.removeFromSnapshot(_element);

    _element.parentProdLine.getStateBuilder()._children[_element.item]!.remove(
      _element,
    );
    _element.childProdLine.getStateBuilder()._parents[_element.item]!.remove(
      _element,
    );
    _element.parentGraph.getStateBuilder()._edges.remove(_element);

    switch (_element.edgeType) {
      case EdgeType.requestItems:
        _element.childProdLine.getStateBuilder()._queueIoUpdate();

      case EdgeType.pushExcess:
        _element.parentProdLine.getStateBuilder()._queueIoUpdate();

      case EdgeType.requestExcess:
        var edgesToUpdate = _element.parentProdLine.children[_element.item]!
            .where((edge) => edge.edgeType == EdgeType.requestItems)
            .followedBy(
              _element.childProdLine.parents[_element.item]!.where(
                (edge) => edge.edgeType == EdgeType.pushExcess,
              ),
            );

        for (var toUpdate in edgesToUpdate) {
          toUpdate.getStateBuilder()._queueIoUpdate();
        }
    }

    // If parent is a graph, this just creates a new statebuilder
    // This ensures graph.parents and graph.children, which are determined dynamically, are updated
    _element.parent.getStateBuilder();
    _element.child.getStateBuilder();
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

  @override
  void updateGeometry(EdgeGeometryImpl geometry) => _geometry = geometry;

  @override
  EdgeStateImpl build() => EdgeStateImpl(
    _element,
    amount: _amount,
    requestedAmount: _requestedAmount,
    percentage: _percentage,
    parentPriority: _parentPriority,
    childPriority: _childPriority,
    geometry: _geometry,
  );

  void _queueChildrenAffectedByRemoval() {
    switch (_element.edgeType) {
      case EdgeType.requestItems:
        _element.childProdLine.getStateBuilder()._queueIoUpdate();

      case EdgeType.requestExcess:
        var edgesToUpdate = _element.childProdLine.parents[_element.item]!
            .where((edge) => edge.edgeType == EdgeType.pushExcess);

        for (var toUpdate in edgesToUpdate) {
          toUpdate.getStateBuilder()._queueIoUpdate();
        }

      case EdgeType.pushExcess:
        break;
    }
  }

  void _queueParentsAffectedByRemoval() {
    switch (_element.edgeType) {
      case EdgeType.pushExcess:
        _element.parentProdLine.getStateBuilder()._queueIoUpdate();

      case EdgeType.requestExcess:
        var edgesToUpdate = _element.parentProdLine.children[_element.item]!
            .where((edge) => edge.edgeType == EdgeType.requestItems);

        for (var toUpdate in edgesToUpdate) {
          toUpdate.getStateBuilder()._queueIoUpdate();
        }

      case EdgeType.requestItems:
        break;
    }
  }
}
