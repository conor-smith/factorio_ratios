part of 'geometry.dart';

/// Stores the geometry data for a graph object
///
/// Data comes in the form of leftMost, topMost, rightMost and bottomMost
/// geometry objects stored within graph
class GraphGeometry extends Geometry {
  /// Represents a graph that contains no objects
  static const uninitialised = GraphGeometry._();

  final Geometry? top, left, bottom, right;

  GraphGeometry.fromLTRB(
    Geometry left,
    Geometry top,
    Geometry right,
    Geometry bottom,
  ) : this._(
        left: left,
        top: top,
        right: right,
        bottom: bottom,
        minimalRect: Rect.fromLTRB(
          left.minimalRect.left,
          top.minimalRect.top,
          right.minimalRect.right,
          bottom.minimalRect.bottom,
        ),
      );

  const GraphGeometry._({
    this.left,
    this.top,
    this.right,
    this.bottom,
    Rect minimalRect = Rect.zero,
  }) : super(minimalRect);
}