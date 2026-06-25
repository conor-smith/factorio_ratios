import 'dart:collection';
import 'dart:ui';

import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/base_planner/edge/edge.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/edge_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/node_geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/graph/graph.dart';
import 'package:factorio_ratios/factorio/base_planner/node/node.dart';

class GeometryOperation {
  final BasePlanner _basePlanner;

  final Map<NodeElement, NodeGeometryBuilder> _nodeGeometries = {};
  final Map<Edge, EdgeGeometryBuilder> _edgeGeometries = {};
  final Map<Edge, EdgeGeometryBuilder> _affectedEdgeGeometries = {};

  GeometryOperation.drag(
    BasePlanner basePlanner,
    Graph parentGraph, {
    Iterable<NodeElement> selectedNodes = const [],
  }) : _basePlanner = basePlanner {
    for (var node in selectedNodes) {
      _nodeGeometries[node] = NodeGeometryBuilder.from(node.geometry);
    }

    var allEdges = selectedNodes
        .expand((node) => node.parents.followedBy(node.children))
        .toSet();
    for (var edge in allEdges) {
      var parentGeometry = _nodeGeometries[edge.parent];
      var childGeometry = _nodeGeometries[edge.child];

      if (parentGeometry != null && childGeometry != null) {
        _edgeGeometries[edge] = EdgeGeometryBuilder.from(
          edge.geometry,
          parentGeometry,
          childGeometry,
        );
      } else {
        _affectedEdgeGeometries[edge] = EdgeGeometryBuilder.from(
          edge.geometry,
          parentGeometry ?? edge.parent.geometry,
          childGeometry ?? edge.child.geometry,
        );
      }
    }
  }

  void performOperation(Offset shiftFromStart) {
    _nodeGeometries.forEach((node, builder) {
      builder.shift(shiftFromStart);
      node.notifyListenersOfGeometryUpdate(builder);
    });

    _edgeGeometries.forEach((edge, builder) {
      builder.shift(shiftFromStart);
      edge.notifyListenersOfGeometryUpdate(builder);
    });

    _affectedEdgeGeometries.forEach((edge, builder) {
      builder.nodeUpdateRedraw();
      edge.notifyListenersOfGeometryUpdate(builder);
    });
  }

  void applyUpdate() {
    _basePlanner.buildNextSnapshot(() {
      _nodeGeometries.forEach(
        (node, builder) =>
            node.getStateBuilder().updateGeometry(builder.build()),
      );

      Map<Edge, EdgeGeometryBuilder>.from(_edgeGeometries)
        ..addAll(_affectedEdgeGeometries)
        ..forEach(
          (edge, builder) =>
              edge.getStateBuilder().updateGeometry(builder.build()),
        );
    });
  }
}

class NodeGeometryBuilder
    implements GeometryBuilder<NodeGeometryImpl>, NodeGeometry {
  final NodeGeometryImpl _original;

  Rect _minimalRect;

  @override
  Rect get rect => _minimalRect;

  NodeGeometryBuilder.from(NodeGeometryImpl geometry)
    : _original = geometry,
      _minimalRect = geometry.rect;

  @override
  void shift(Offset offset) => _minimalRect = _original.rect.shift(offset);

  void updateRect(Rect newRect) => _minimalRect = newRect;

  @override
  NodeGeometryImpl build() => NodeGeometryImpl(_minimalRect);
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
  Rect get rect => original.rect;
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
