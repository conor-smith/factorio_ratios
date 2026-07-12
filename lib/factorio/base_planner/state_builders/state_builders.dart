import 'dart:collection';

import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/edge/edge.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/edge_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/node_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/factorio/base_planner/node/node.dart';
import 'package:factorio_ratios/factorio/base_planner/snapshot_builder/snapshot_builder.dart';
import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/factorio/models/models.dart';
import 'package:factorio_ratios/factorio/production_lines/production_line.dart';
import 'package:factorio_ratios/utility/builder.dart';

part 'node_state_builder.dart';
part 'edge_state_builder.dart';
part 'graph_state_builder.dart';

abstract class StateBuilder<T> implements Builder<T> {
  BasePlannerElement get _element;
  late final SnapshotBuilder _snapshotBuilder = _element.basePlanner
      .getSnapshotBuilder();

  StateBuilder.from() {
    _snapshotBuilder
      ..throwIfNotStage(SnapshotBuildStage.userOperations)
      ..addToSnapshot(_element, this);
  }

  StateBuilder.initial() {
    _snapshotBuilder
      ..throwIfNotStage(SnapshotBuildStage.userOperations)
      ..addToSnapshot(_element, this)
      ..queueCircularDependencyCheck(_element)
      ..queueRequiredIoUpdate(_element)
      ..queueLayoutUpdate(_element.parentGraph);
  }

  void removeSelf();
}

abstract class NodeStateBuilder<T> extends StateBuilder<T> {
  NodeStateBuilder.from() : super.from();
  NodeStateBuilder.initial() : super.initial();

  void updateUnusedIo(ItemIoImpl newUnusedIo);
  void updateGeometry(NodeGeometryImpl geometry);
}
