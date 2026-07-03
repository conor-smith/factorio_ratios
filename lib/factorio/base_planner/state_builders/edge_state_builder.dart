part of 'state_builders.dart';

class EdgeStateBuilder extends StateBuilder<EdgeState> implements EdgeState {
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
      super.from();

  @override
  void removeSelf() {
    _snapshotBuilder
      ..removeFromSnapshot(_element)
      ..queueLayoutUpdate(_element.parentGraph);

    _element.parentProdLine.getStateBuilder()._children[_element.item]!.remove(
      _element,
    );
    _element.childProdLine.getStateBuilder()._parents[_element.item]!.remove(
      _element,
    );
    _element.parentGraph.getStateBuilder()._edges.remove(_element);

    // If parent or child is a graph, this just creates a new statebuilder
    // This ensures graph.parents and graph.children, which are determined dynamically, are updated
    _element.parent.getStateBuilder();
    _element.child.getStateBuilder();

    switch (_element.edgeType) {
      case EdgeType.requestItems:
        _snapshotBuilder
          ..updateIoSatus(_element.childProdLine, UpdateStatus.required)
          ..queueUnfulfilledIoCheck(_element.parentProdLine);

      case EdgeType.pushExcess:
        _snapshotBuilder
          ..updateIoSatus(_element.parentProdLine, UpdateStatus.required)
          ..queueUnfulfilledIoCheck(_element.childProdLine);

      case EdgeType.requestExcess:
        var edgesToUpdate = [
          ..._element.parentProdLine.children[_element.item]!.where(
            (edge) => edge.edgeType == EdgeType.requestItems,
          ),
          ..._element.childProdLine.parents[_element.item]!.where(
            (edge) => edge.edgeType == EdgeType.pushExcess,
          ),
        ];

        for (var edge in edgesToUpdate) {
          _snapshotBuilder.updateIoSatus(edge, UpdateStatus.checkDependencies);
        }
    }
  }

  void updateAmount(double newAmount) {
    _snapshotBuilder.throwIfNotBuildingIo();

    _amount = newAmount;
  }

  void updatePercentage(double newPercentage) {
    _snapshotBuilder.updateIoSatus(_element, UpdateStatus.required);

    switch (_element.edgeType) {
      case EdgeType.requestItems:
        _snapshotBuilder.queueUnfulfilledIoCheck(_element.parentProdLine);

      case EdgeType.pushExcess:
        _snapshotBuilder.queueUnfulfilledIoCheck(_element.childProdLine);

      case EdgeType.requestExcess:
        throw const EdgeException(
          'Cannot update percentage on requestExcess edge',
        );
    }
    _percentage = newPercentage;
  }

  void updateParentPriority(int newPriority) {
    _snapshotBuilder.updateIoSatus(_element, UpdateStatus.required);
    _parentPriority = newPriority;
  }

  void updateChildPriority(int newPriority) {
    _snapshotBuilder.updateIoSatus(_element, UpdateStatus.required);
    _childPriority = newPriority;
  }

  @override
  void updateGeometry(EdgeGeometryImpl geometry) {
    if (_snapshotBuilder.stage != SnapshotBuildStage.updateGraphLayouts &&
        _element.parentGraph.layout != GraphLayout.custom) {
      _element.parentGraph.getStateBuilder()._layout = GraphLayout.custom;
    }

    _geometry = geometry;
  }

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
    _snapshotBuilder
      ..removeFromSnapshot(_element)
      ..queueLayoutUpdate(_element.parentGraph);

    _element.parentProdLine.children[_element.item]!.remove(_element);

    // If parent is a graph, this just creates a new statebuilder
    // This ensures graph.parents and graph.children, which are determined dynamically, are updated
    _element.parent.getStateBuilder();

    switch (_element.edgeType) {
      case EdgeType.requestItems:
        _snapshotBuilder.queueUnfulfilledIoCheck(_element.parentProdLine);

      case EdgeType.pushExcess:
        _snapshotBuilder.updateIoSatus(
          _element.parentProdLine,
          UpdateStatus.required,
        );

      case EdgeType.requestExcess:
        var edgesToUpdate = _element.childProdLine.parents[_element.item]!
            .where((edge) => edge.edgeType == EdgeType.pushExcess);

        for (var edge in edgesToUpdate) {
          _snapshotBuilder.updateIoSatus(edge, UpdateStatus.checkDependencies);
        }
    }
  }

  void _removeSelfAndUpdateChildOnly() {
    _snapshotBuilder
      ..removeFromSnapshot(_element)
      ..queueLayoutUpdate(_element.parentGraph);

    _element.childProdLine.parents[_element.item]!.remove(_element);

    // If child is a graph, this just creates a new statebuilder
    // This ensures graph.parents and graph.children, which are determined dynamically, are updated
    _element.child.getStateBuilder();

    switch (_element.edgeType) {
      case EdgeType.requestItems:
        _snapshotBuilder.updateIoSatus(
          _element.childProdLine,
          UpdateStatus.required,
        );

      case EdgeType.pushExcess:
        _snapshotBuilder.queueUnfulfilledIoCheck(_element.childProdLine);

      case EdgeType.requestExcess:
        var edgesToUpdate = _element.childProdLine.parents[_element.item]!
            .where((edge) => edge.edgeType == EdgeType.pushExcess);

        for (var edge in edgesToUpdate) {
          _snapshotBuilder.updateIoSatus(edge, UpdateStatus.checkDependencies);
        }
    }
  }
}
