import 'dart:collection';
import 'dart:ui';

import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/edge.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/edge_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/node_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/graph.dart';
import 'package:factorio_ratios/factorio/base_planner/production_line_node.dart';
import 'package:factorio_ratios/factorio/base_planner/stateful.dart';

class GeometryOperation {
  final BasePlanner _basePlanner;

  final Map<ProductionLineNode, NodeGeometryBuilder> _nodes = {};
  final Map<Edge, EdgeGeometryBuilder> _edges = {};
  final Map<Graph, NodeGeometryBuilder> _graphs = {};

  final Map<Edge, EdgeGeometryBuilder> _affectedEdges = {};

  GeometryOperation.drag(
    BasePlanner basePlanner,
    Graph parentGraph, {
    Iterable<ProductionLineNode> selectedNodes = const [],
    Iterable<Graph> selectedChildGraphs = const [],
  }) : _basePlanner = basePlanner {
    // TODO: verification, optimisation
    for (var node in selectedNodes) {
      _nodes[node] = NodeGeometryBuilder.from(node.nodeGeometry);
    }
    for (var graph in selectedChildGraphs) {
      _graphs[graph] = NodeGeometryBuilder.from(graph.nodeGeometry);
    }

    // Makes lookup easier
    Map<Node, NodeGeometryBuilder> allNodeGeometries = Map.from(_nodes)
      ..addAll(_graphs);

    for (var edge
        in allNodeGeometries.keys
            .expand((node) => node.parents.followedBy(node.children))
            .toSet()) {
      var parentGeometry = allNodeGeometries[edge.parentNode];
      var childGeometry = allNodeGeometries[edge.childNode];

      if (parentGeometry != null && childGeometry != null) {
        _edges[edge] = EdgeGeometryBuilder.from(
          edge.edgeGeometry,
          parentGeometry,
          childGeometry,
        );
      } else {
        _affectedEdges[edge] = EdgeGeometryBuilder.from(
          edge.edgeGeometry,
          parentGeometry ?? edge.parentNode.nodeGeometry,
          childGeometry ?? edge.childNode.nodeGeometry,
        );
      }
    }
  }
}

class NodeGeometryBuilder implements Builder<NodeGeometry>, NodeGeometry {
  final NodeGeometry _original;

  Rect _minimalRect;

  @override
  Rect get minimalRect => _minimalRect;

  NodeGeometryBuilder.from(NodeGeometry nodeGeometry)
    : _original = nodeGeometry,
      _minimalRect = nodeGeometry.minimalRect;

  void shift(Offset offset) =>
      _minimalRect = _original.minimalRect.shift(offset);

  void updateRect(Rect newRect) => _minimalRect = newRect;

  @override
  NodeGeometry build() => NodeGeometry(_minimalRect);

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class EdgeGeometryBuilder implements Builder<EdgeGeometry>, EdgeGeometry {
  final EdgeGeometry _original;
  final NodeGeometry _parent;
  final NodeGeometry _child;

  final List<Line> _lines;

  @override
  EdgeGeometryType get geometryType => _original.geometryType;
  @override
  Rect get minimalRect => _original.minimalRect;
  @override
  late final List<Line> lines = UnmodifiableListView(_lines);

  EdgeGeometryBuilder.from(
    EdgeGeometry edgeGeometry,
    NodeGeometry parent,
    NodeGeometry child,
  ) : _original = edgeGeometry,
      _parent = parent,
      _child = child,
      _lines = List.from(edgeGeometry.lines);

  void shift(Offset offset) {
    for (var i = 0; i < _original.lines.length; i++) {
      _lines[i] = _original.lines[i].shift(offset);
    }
  }

  void nodeUpdateRedraw() {
    switch (_original.geometryType) {
      case EdgeGeometryType.shortestPath:
        _lines[0] = Line.shortestLine(_parent.minimalRect, _child.minimalRect);
    }
  }

  @override
  EdgeGeometry build() => EdgeGeometry(_original.geometryType, _lines);

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}
