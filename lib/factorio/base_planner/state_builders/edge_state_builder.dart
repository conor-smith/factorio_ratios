part of 'state_builders.dart';

class EdgeStateBuilder extends StateBuilder<EdgeStateImpl>
    implements EdgeState {
  @override
  final Edge _element;

  double _amount;
  double _percentage;
  int _parentPriority;
  int _childPriority;
  EdgeGeometryImpl _geometry;

  @override
  double get amount => _amount;
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

    _updateParentIfParentIsGraphNode();
    _updateChildIfChildIsGraphNode();
  }

  EdgeStateBuilder.from(this._element, EdgeStateImpl previousState)
    : _amount = previousState.amount,
      _percentage = previousState.percentage,
      _parentPriority = previousState.parentPriority,
      _childPriority = previousState.childPriority,
      _geometry = previousState.geometry,
      super.from();

  @override
  void removeSelf() {
    // _snapshotBuilder
    //   ..removeFromSnapshot(_element)
    //   ..queueLayoutUpdate(_element.parentGraph);

    // _element.parentProdLine.getStateBuilder()._children[_element.item]!.remove(
    //   _element,
    // );
    // _element.childProdLine.getStateBuilder()._parents[_element.item]!.remove(
    //   _element,
    // );
    // _element.parentGraph.getStateBuilder()._edges.remove(_element);

    // _updateParentIfParentIsGraphNode();
    // _updateChildIfChildIsGraphNode();

    // for (var dependant in _element.determineDependants()) {
    //   _snapshotBuilder.queueRequiredIoUpdate(dependant);
    // }
  }

  void updateAmount(double newAmount) {
    _snapshotBuilder.throwIfNotStage(SnapshotBuildStage.buildIo);

    _amount = newAmount;
  }

  void updatePercentage(double newPercentage) {
    // _snapshotBuilder.queueRequiredIoUpdate(_element);
    // _percentage = newPercentage;
  }

  void updateParentPriority(int newPriority) {
    // _snapshotBuilder.queueRequiredIoUpdate(_element);
    // _parentPriority = newPriority;
  }

  void updateChildPriority(int newPriority) {
    // _snapshotBuilder.queueRequiredIoUpdate(_element);
    // _childPriority = newPriority;
  }

  void updateGeometry(EdgeGeometryImpl geometry) => _geometry = geometry;

  @override
  EdgeStateImpl build() => EdgeStateImpl(
    _element,
    amount: _amount,
    percentage: _percentage,
    parentPriority: _parentPriority,
    childPriority: _childPriority,
    geometry: _geometry,
  );

  void _removeSelfAndUpdateParentOnly() {
    //   _snapshotBuilder
    //     ..removeFromSnapshot(_element)
    //     ..queueLayoutUpdate(_element.parentGraph);

    //   _element.parentProdLine.children[_element.item]!.remove(_element);

    //   _updateParentIfParentIsGraphNode();

    //   for (var parentDependant in _element.determineParentDependants()) {
    //     _snapshotBuilder.queueRequiredIoUpdate(parentDependant);
    //   }
    // }

    // void _removeSelfAndUpdateChildOnly() {
    //   _snapshotBuilder
    //     ..removeFromSnapshot(_element)
    //     ..queueLayoutUpdate(_element.parentGraph);

    //   _element.childProdLine.parents[_element.item]!.remove(_element);

    //   _updateChildIfChildIsGraphNode();

    //   for (var childDependant in _element.determineChildDependants()) {
    //     _snapshotBuilder.queueRequiredIoUpdate(childDependant);
    //   }
  }

  void _updateParentIfParentIsGraphNode() {
    // if (_element.parentNode is Graph) {
    //   var parentGraphNode = (_element.parentNode as Graph);
    //   parentGraphNode.getStateBuilder()._clearCachedChildren();
    //   _snapshotBuilder.queueRequiredIoUpdate(parentGraphNode);
    // }
  }

  void _updateChildIfChildIsGraphNode() {
    // if (_element.childNode is Graph) {
    //   var childGraphNode = (_element.childNode as Graph);
    //   childGraphNode.getStateBuilder()._clearCachedParents();
    //   _snapshotBuilder.queueRequiredIoUpdate(childGraphNode);
    // }
  }
}
