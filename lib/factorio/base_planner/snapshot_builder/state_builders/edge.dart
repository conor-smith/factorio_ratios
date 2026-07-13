part of '../snapshot_builder.dart';

class EdgeStateBuilder extends StateBuilder<EdgeStateImpl>
    implements EdgeState {
  final Edge edge;

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

  EdgeStateBuilder.initial(this.edge)
    : _amount = 0,
      _percentage = 0,
      _parentPriority = 0,
      _childPriority = 0,
      _geometry = EdgeGeometryImpl.uninitialised {
    if (edge.edgeType == EdgeType.requestExcess) {
      _parentPriority = 1;
      _childPriority = 1;
    } else {
      _percentage = 1.0;
    }
  }

  EdgeStateBuilder.from(this.edge, EdgeStateImpl previousState)
    : _amount = previousState.amount,
      _percentage = previousState.percentage,
      _parentPriority = previousState.parentPriority,
      _childPriority = previousState.childPriority,
      _geometry = previousState.geometry;

  void updateAmount(double newAmount) {
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
    edge,
    amount: _amount,
    percentage: _percentage,
    parentPriority: _parentPriority,
    childPriority: _childPriority,
    geometry: _geometry,
  );
}
