import 'dart:collection';

import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/edge/edge.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/edge_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/node_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/factorio/base_planner/node/io_node/io_node.dart';
import 'package:factorio_ratios/factorio/base_planner/node/node.dart';
import 'package:factorio_ratios/factorio/base_planner/node/production_line_node/production_line_node.dart';
import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/factorio/models/models.dart';
import 'package:factorio_ratios/factorio/production_lines/production_line.dart';

part 'edge_state_builder.dart';
part 'graph_state_builder.dart';
part 'io_node_state_builder.dart';
part 'node_state_builder.dart';
part 'production_line_node_state_builder.dart';

abstract interface class StateBuilder<T> implements Builder<T> {
  void addSelf();
  void removeSelf();
}

abstract interface class NodeStateBuilder<T> implements StateBuilder<T> {
  void updateGeometry(NodeGeometryImpl nodeGeometry);
  void _addParent(Edge parentEdge);
  void _removeParent(Edge parentEdge);
  void _addChild(Edge chidEdge);
  void _removeChild(Edge childEdge);
}
