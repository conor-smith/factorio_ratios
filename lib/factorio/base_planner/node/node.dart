import 'dart:collection';

import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/edge/edge.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/node_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/factorio/production_lines/production_line.dart';
import 'package:factorio_ratios/json/json.dart';

part 'production_line_node.dart';

abstract interface class NodeElement<St extends ToJson, E>
    implements BasePlannerElement<St, E> {
  Graph? get parentGraph;
  NodeType get nodeType;

  ProductionLine get productionLine;
  ProductionLineIo? get io;

  NodeGeometry get nodeGeometry;

  @override
  NodeStateBuilder<St> getStateBuilder();

  Set<Edge> get parents;
  Set<Edge> get children;

  Set<InGameItem> get inputItems;
  Set<InGameItem> get outputItems;
}

abstract interface class NodeStateBuilder<T extends ToJson>
    implements Builder<T> {
  void updateGeometry(NodeGeometry nodeGeometry);
  void addParent(Edge parentEdge);
  void removeParent(Edge parentEdge);
  void addChild(Edge chidEdge);
  void removeChild(Edge childEdge);
}
