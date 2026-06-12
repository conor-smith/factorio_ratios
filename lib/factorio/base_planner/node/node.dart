import 'dart:collection';

import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/edge/edge.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/node_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/factorio/production_lines/production_line.dart';
import 'package:factorio_ratios/json/json.dart';

part 'production_line_node_state.dart';
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

  Map<InGameItem, List<Edge>> get outputEdges;
  Map<InGameItem, List<Edge>> get inputEdges;

  Set<InGameItem> get inputItems;
  Set<InGameItem> get outputItems;

  static Map<InGameItem, List<Edge>> calculateOutputEdges(
    Set<Edge> parents,
    Set<Edge> children,
  ) {
    Map<InGameItem, List<Edge>> outputEdges = {};

    for (var edge in parents) {
      if (edge.edgeType == EdgeType.requestItems) {
        outputEdges.update(
          edge.item,
          (edges) => edges..add(edge),
          ifAbsent: () => [edge],
        );
      }
    }
    for (var edge in children) {
      if (edge.edgeType == EdgeType.acceptExcess) {
        outputEdges.update(
          edge.item,
          (edges) => edges..add(edge),
          ifAbsent: () => [edge],
        );
      }
    }

    outputEdges.updateAll((item, edges) => List.unmodifiable(edges));
    return Map.unmodifiable(outputEdges);
  }

  static Map<InGameItem, List<Edge>> calculateInputEdges(
    Set<Edge> parents,
    Set<Edge> children,
  ) {
    Map<InGameItem, List<Edge>> inputEdges = {};

    for (var edge in parents) {
      if (edge.edgeType == EdgeType.acceptExcess) {
        inputEdges.update(
          edge.item,
          (edges) => edges..add(edge),
          ifAbsent: () => [edge],
        );
      }
    }
    for (var edge in children) {
      if (edge.edgeType == EdgeType.requestItems) {
        inputEdges.update(
          edge.item,
          (edges) => edges..add(edge),
          ifAbsent: () => [edge],
        );
      }
    }

    inputEdges.updateAll((item, edges) => List.unmodifiable(edges));
    return Map.unmodifiable(inputEdges);
  }
}

abstract interface class NodeStateBuilder<T extends ToJson>
    implements Builder<T> {
  void updateGeometry(NodeGeometry nodeGeometry);
  void addParent(Edge parentEdge);
  void removeParent(Edge parentEdge);
  void addChild(Edge chidEdge);
  void removeChild(Edge childEdge);
}

enum NodeType implements Comparable<NodeType> {
  input(true, 1),
  combiner(false, 2),
  producer(false, 3),
  resource(false, 4),
  productionLine(false, 5),
  consumer(false, 6),
  disposal(false, 7),
  output(true, 8);

  final bool isIo;
  final int outputPriority;

  const NodeType(this.isIo, this.outputPriority);

  @override
  int compareTo(NodeType other) =>
      outputPriority.compareTo(other.outputPriority);
}
