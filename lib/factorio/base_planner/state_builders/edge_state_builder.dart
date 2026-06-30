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
      _geometry = EdgeGeometryImpl.uninitialised {
    if (_element.edgeType == EdgeType.requestExcess) {
      _parentPriority = 1;
      _childPriority = 1;
    } else {
      _percentage = 1.0;
    }

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

    // If parent is a graph, this just creates a new statebuilder
    // This ensures graph.parents and graph.children, which are determined dynamically, are updated
    _element.parent.getStateBuilder();
    _element.child.getStateBuilder();
  }

  void updatePercentage(double newPercentage) {
    _percentage = newPercentage;
  }

  void updateParentPriority(int newPriority) {
    _parentPriority = newPriority;
  }

  void updateChildPriority(int newPriority) {
    _childPriority = newPriority;
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
}
