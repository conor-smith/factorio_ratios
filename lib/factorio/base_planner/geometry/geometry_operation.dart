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
      _nodeGeometries[node] = NodeGeometryBuilder.from(node.nodeGeometry);
    }

    var allEdges = selectedNodes
        .expand((node) => node.parents.followedBy(node.children))
        .toSet();
    for (var edge in allEdges) {
      var parentGeometry = _nodeGeometries[edge.parent];
      var childGeometry = _nodeGeometries[edge.child];

      if (parentGeometry != null && childGeometry != null) {
        _edgeGeometries[edge] = EdgeGeometryBuilder.from(
          edge.edgeGeometry,
          parentGeometry,
          childGeometry,
        );
      } else {
        _affectedEdgeGeometries[edge] = EdgeGeometryBuilder.from(
          edge.edgeGeometry,
          parentGeometry ?? edge.parent.nodeGeometry,
          childGeometry ?? edge.child.nodeGeometry,
        );
      }
    }
  }

  void performOperation(Offset shiftFromStart) {
    _nodeGeometries.forEach((node, geometry) {
      geometry.shift(shiftFromStart);
      node.notifyListenersOfGeometryUpdate(geometry);
    });
    _edgeGeometries.forEach((edge, geometry) {
      geometry.shift(shiftFromStart);
      edge.notifyListenersOfGeometryUpdate(geometry);
    });

    _affectedEdgeGeometries.forEach((edge, geometry) {
      geometry.nodeUpdateRedraw();
      edge.notifyListenersOfGeometryUpdate(geometry);
    });
  }

  void applyUpdate() {
    _basePlanner.buildNextSnapshot(() {
      _nodeGeometries.forEach(
        (node, geometry) => node.getStateBuilder().updateGeometry(geometry),
      );

      Map<Edge, EdgeGeometryBuilder>.from(_edgeGeometries)
        ..addAll(_affectedEdgeGeometries)
        ..forEach(
          (edge, geometry) => edge.getStateBuilder().updateGeometry(geometry),
        );
    });
  }
}

class NodeGeometryBuilder
    implements GeometryBuilder<NodeGeometry>, NodeGeometry {
  final NodeGeometry _original;

  Rect _minimalRect;

  @override
  Rect get minimalRect => _minimalRect;

  NodeGeometryBuilder.from(NodeGeometry nodeGeometry)
    : _original = nodeGeometry,
      _minimalRect = nodeGeometry.minimalRect;

  @override
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

class EdgeGeometryBuilder
    implements GeometryBuilder<EdgeGeometry>, EdgeGeometry {
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

  @override
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
