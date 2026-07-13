part of '../snapshot_builder.dart';

abstract class StateBuilder<T> implements Builder<T> {}

abstract class NodeStateBuilder<T extends NodeState> extends StateBuilder<T>
    with NodeState {
  void updateUnusedIo(ItemIoImpl newUnusedIo);
  void updateGeometry(NodeGeometryImpl geometry);
}
