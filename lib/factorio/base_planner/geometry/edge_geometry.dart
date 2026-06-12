import 'dart:ui';

import 'package:factorio_ratios/factorio/base_planner/geometry/geometry.dart';
import 'package:factorio_ratios/factorio/base_planner/geometry/node_geometry.dart';

class EdgeGeometry implements Geometry {
  static const uninitialised = EdgeGeometry._uninitialised();

  @override
  final Rect minimalRect;

  final EdgeGeometryType geometryType;
  final List<Line> lines;

  EdgeGeometry(this.geometryType, List<Line> lines)
    : lines = List.unmodifiable(lines),
      minimalRect = determineMinimalRect(lines);

  EdgeGeometry.shortestPath(NodeGeometry start, NodeGeometry end)
    : geometryType = EdgeGeometryType.shortestPath,
      lines = List.unmodifiable([
        Line(start.minimalRect.center, end.minimalRect.center),
      ]),
      minimalRect = Rect.fromPoints(start.minimalRect.center, end.minimalRect.center);

  const EdgeGeometry._uninitialised()
    : minimalRect = Rect.zero,
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
