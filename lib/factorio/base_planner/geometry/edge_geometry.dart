import 'dart:ui';

import 'package:factorio_ratios/factorio/base_planner/geometry/geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/node_geometry.dart';
import 'package:factorio_ratios/json/json.dart';

abstract interface class EdgeGeometry implements Geometry {
  EdgeGeometryType get geometryType;
  List<Line> get lines;
}

class EdgeGeometryImpl implements EdgeGeometry, ToJson {
  static const uninitialised = EdgeGeometryImpl._uninitialised();

  @override
  final Rect rect;

  @override
  final EdgeGeometryType geometryType;
  @override
  final List<Line> lines;

  EdgeGeometryImpl(this.geometryType, List<Line> lines)
    : lines = List.unmodifiable(lines),
      rect = determineMinimalRect(lines);

  EdgeGeometryImpl.shortestPath(NodeGeometryImpl start, NodeGeometryImpl end)
    : geometryType = EdgeGeometryType.shortestPath,
      lines = List.unmodifiable([Line(start.rect.center, end.rect.center)]),
      rect = Rect.fromPoints(start.rect.center, end.rect.center);

  const EdgeGeometryImpl._uninitialised()
    : rect = Rect.zero,
      geometryType = EdgeGeometryType.shortestPath,
      lines = const [];

  static Rect determineMinimalRect(List<Line> lines) {
    if (lines.isEmpty) {
      return Rect.zero;
    } else if (lines.length == 1) {
      return Rect.fromPoints(lines[0].start, lines[0].end);
    } else {
      // TODO
      throw UnimplementedError();
    }
  }

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

enum EdgeGeometryType { shortestPath }
