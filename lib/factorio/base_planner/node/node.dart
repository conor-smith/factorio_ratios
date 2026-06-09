import 'dart:collection';

import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/edge/edge.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/node_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/factorio/production_lines/production_line.dart';
import 'package:factorio_ratios/json/json.dart';

part 'production_line_node.dart';

abstract interface class NodeElement<
  St extends ToJson,
  B extends NodeStateBuilder<St>,
  E
>
    implements BasePlannerElement<St, B, E> {
  Graph? get parentGraph;

  ProductionLineIo? get io;
  NodeGeometry get nodeGeometry;

  Set<Edge> get parents;
  Set<Edge> get children;
}

abstract interface class NodeStateBuilder<T extends ToJson>
    implements Builder<T> {
  void updateGeometry(NodeGeometry nodeGeometry);
}
