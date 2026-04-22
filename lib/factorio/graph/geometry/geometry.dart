import 'dart:collection';
import 'dart:ui';

import 'package:factorio_ratios/factorio/graph/graph.dart';
import 'package:factorio_ratios/factorio/graph/state/state.dart';

part 'edge_geometry.dart';
part 'geometry_operation.dart';
part 'graph_geometry.dart';
part 'node_geometry.dart';

/// Represents a simple 2D rectangle on a cartesian plane
abstract class Geometry {
  /// Minimal rectangle to contain all objects contained within this object
  final Rect minimalRect;

  const Geometry(this.minimalRect);

  /// Comparator that compares y values of the top side of geometry rectangle
  static Comparator<Geometry> topMost = (Geometry data1, Geometry data2) =>
      -data1.minimalRect.top.compareTo(data2.minimalRect.top);

  /// Comparator that compares x values of the left side of geometry rectangle
  static Comparator<Geometry> leftMost = (Geometry data1, Geometry data2) =>
      -data1.minimalRect.left.compareTo(data2.minimalRect.left);

  /// Comparator that compares y values of the bottom side of geometry rectangle
  static Comparator<Geometry> bottomMost = (Geometry data1, Geometry data2) =>
      data1.minimalRect.bottom.compareTo(data2.minimalRect.bottom);

  /// Comparator that compares x values of the right side of geometry rectangle
  static Comparator<Geometry> rightMost = (Geometry data1, Geometry data2) =>
      data1.minimalRect.right.compareTo(data2.minimalRect.right);
}

enum RectPoint {
  topLeft,
  top,
  topRight,
  right,
  bottomRight,
  bottom,
  bottomLeft,
  left;

  Offset getPoint(Rect rect) => switch (this) {
    topLeft => rect.topLeft,
    top => rect.topCenter,
    topRight => rect.topRight,
    right => rect.centerRight,
    bottomRight => rect.bottomRight,
    bottom => rect.bottomCenter,
    bottomLeft => rect.bottomLeft,
    left => rect.centerLeft,
  };

  RectPoint get opposite => switch (this) {
    topLeft => bottomRight,
    top => bottom,
    topRight => bottomLeft,
    right => left,
    bottomRight => topLeft,
    bottom => top,
    bottomLeft => topRight,
    left => right,
  };
}

class Line {
  final Offset start, end;

  const Line(this.start, this.end);

  Line shift(Offset shift) => Line(start + shift, end + shift);
}
