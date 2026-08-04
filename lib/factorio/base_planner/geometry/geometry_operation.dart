import 'dart:collection';
import 'dart:ui';

import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/edge/edge.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/edge_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/node_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/factorio/base_planner/node/node.dart';
import 'package:flutter/foundation.dart';

class GeometryOperation with ChangeNotifier {
  final BasePlanner basePlanner;
  final Graph parentGraph;

  final Map<NodeElement, NodeGeometryBuilder> _nodeGeometries;
  final Map<Edge, EdgeGeometryBuilder> _edgeGeometries;
  final Map<Edge, EdgeGeometryBuilder> _affectedEdgeGeometries;

  GeometryOperation._(
    this.basePlanner,
    this.parentGraph,
    Map<NodeElement, NodeGeometryBuilder> nodeGeometries,
    Map<Edge, EdgeGeometryBuilder> edgeGeometries,
    Map<Edge, EdgeGeometryBuilder> affectedEdgeGeometries,
  ) : _nodeGeometries = Map.unmodifiable(nodeGeometries),
      _edgeGeometries = Map.unmodifiable(edgeGeometries),
      _affectedEdgeGeometries = Map.unmodifiable(affectedEdgeGeometries);

  factory GeometryOperation.drag(
    BasePlanner basePlanner,
    Graph parentGraph,
    Iterable<NodeElement> selectedNodes,
  ) {
    Map<NodeElement, NodeGeometryBuilder> nodeGeometries = {};
    for (var node in selectedNodes) {
      nodeGeometries[node] = NodeGeometryBuilder.from(node.geometry);
    }

    Map<Edge, EdgeGeometryBuilder> edgeGeometries = {};
    Map<Edge, EdgeGeometryBuilder> affectedEdgeGeometries = {};
    var allEdges = selectedNodes
        .expand((node) => node.allParents.followedBy(node.allChildren))
        .toSet();

    for (var edge in allEdges) {
      var parentGeometry = nodeGeometries[edge.parentNode];
      var childGeometry = nodeGeometries[edge.childNode];

      if (parentGeometry != null && childGeometry != null) {
        edgeGeometries[edge] = EdgeGeometryBuilder.from(
          edge.geometry,
          parentGeometry,
          childGeometry,
        );
      } else {
        affectedEdgeGeometries[edge] = EdgeGeometryBuilder.from(
          edge.geometry,
          parentGeometry ?? edge.parentNode.geometry,
          childGeometry ?? edge.childNode.geometry,
        );
      }
    }

    return GeometryOperation._(
      basePlanner,
      parentGraph,
      nodeGeometries,
      edgeGeometries,
      affectedEdgeGeometries,
    );
  }

  Iterable<BasePlannerElement> allAffectedElements() =>
      Iterable<BasePlannerElement>.empty()
          .followedBy(_nodeGeometries.keys)
          .followedBy(_edgeGeometries.keys)
          .followedBy(_affectedEdgeGeometries.keys);

  NodeGeometryBuilder? getNodeGeometryBuilder(NodeElement node) =>
      _nodeGeometries[node];

  EdgeGeometryBuilder? getEdgeGeometryBuilder(Edge edge) =>
      _edgeGeometries[edge] ?? _affectedEdgeGeometries[edge];

  void performOperation(Offset shiftFromStart) {
    _nodeGeometries.forEach((node, builder) {
      builder.shift(shiftFromStart);
    });

    _edgeGeometries.forEach((edge, builder) {
      builder.shift(shiftFromStart);
    });

    _affectedEdgeGeometries.forEach((edge, builder) {
      builder.nodeUpdateRedraw();
    });

    notifyListeners();
  }

  void applyUpdate() {
    dispose();

    basePlanner.buildNextSnapshot(() {
      if (parentGraph.layout != GraphLayout.custom) {
        parentGraph.getStateBuilder().updateLayout(GraphLayout.custom);
      }

      _nodeGeometries.forEach(
        (node, builder) =>
            node.getStateBuilder().updateGeometry(builder.build()),
      );

      var allEdges = _edgeGeometries..addAll(_affectedEdgeGeometries);
      allEdges.forEach(
        (edge, builder) =>
            edge.getStateBuilder().updateGeometry(builder.build()),
      );
    });
  }

  void cancel() => dispose();
}

class NodeGeometryBuilder
    implements GeometryBuilder<NodeGeometryImpl>, NodeGeometry {
  final NodeGeometryImpl _original;

  Rect _rect;

  @override
  Rect get rect => _rect;

  NodeGeometryBuilder.from(NodeGeometryImpl geometry)
    : _original = geometry,
      _rect = geometry.rect;

  @override
  void shift(Offset offset) => _rect = _original.rect.shift(offset);

  void updateRect(Rect newRect) => _rect = newRect;

  @override
  NodeGeometryImpl build() => NodeGeometryImpl(_rect);
}

class EdgeGeometryBuilder
    implements GeometryBuilder<EdgeGeometryImpl>, EdgeGeometry {
  final EdgeGeometryImpl original;
  final NodeGeometry parent;
  final NodeGeometry child;

  final List<Line> _lines;

  @override
  EdgeGeometryType get geometryType => original.geometryType;
  @override
  Rect get rect => Rect.largest;
  @override
  late final List<Line> lines = UnmodifiableListView(_lines);

  EdgeGeometryBuilder.from(this.original, this.parent, this.child)
    : _lines = List.from(original.lines);

  @override
  void shift(Offset offset) {
    for (var i = 0; i < original.lines.length; i++) {
      _lines[i] = original.lines[i].shift(offset);
    }
  }

  void nodeUpdateRedraw() {
    switch (original.geometryType) {
      case EdgeGeometryType.shortestPath:
        _lines[0] = Line.shortestLine(parent.rect, child.rect);
    }
  }

  @override
  EdgeGeometryImpl build() => EdgeGeometryImpl(original.geometryType, _lines);
}
