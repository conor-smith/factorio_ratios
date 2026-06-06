import 'dart:ui';

import 'package:factorio_ratios/factorio/base_planner/geometry/geometry.dart';

class EdgeGeometry implements Geometry {
  static const uninitialised = EdgeGeometry._uninitialised();

  @override
  final Rect minimalRect;

  final EdgeGeometryType geometryType;
  final List<Line> lines;

  EdgeGeometry.shortestPath(Rect startRect, Rect endRect)
    : geometryType = EdgeGeometryType.shortestPath,
      lines = List.unmodifiable([Line(startRect.center, endRect.center)]),
      minimalRect = Rect.fromPoints(startRect.center, endRect.center);

  const EdgeGeometry._uninitialised()
    : minimalRect = Rect.zero,
      geometryType = EdgeGeometryType.shortestPath,
      lines = const [Line(Offset.zero, Offset.zero)];

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

enum EdgeGeometryType { shortestPath }
