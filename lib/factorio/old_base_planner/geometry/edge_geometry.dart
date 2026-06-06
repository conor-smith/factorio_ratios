part of 'geometry.dart';

/// Geometry object for Edge
/// Contains edge type as well as lines belonging to edge
class EdgeGeometry extends Geometry {
  /// Represents an edge between two nodes where one or both nodes
  /// have not yet been positioned
  static const uninitialised = EdgeGeometry._(
    lineType: LineType.shortestPath,
    lines: [],
    minimalRect: Rect.zero,
  );

  final LineType lineType;

  /// First point of first line connects to parent node
  /// Last point of last line ends at the child node
  final List<Line> lines;

  static Line _shortestLine(NodeGeometry start, NodeGeometry end) =>
      Line(start.minimalRect.center, end.minimalRect.center);

  /// Creates a shortest path line between 2 nodes
  factory EdgeGeometry.shortestPath(DirectedEdge edge) {
    var shortestLine = _shortestLine(edge.parent.geometry, edge.child.geometry);

    return EdgeGeometry._(
      lineType: LineType.shortestPath,
      lines: List.unmodifiable([shortestLine]),
      minimalRect: Rect.fromPoints(shortestLine.start, shortestLine.end),
    );
  }

  const EdgeGeometry._({
    required this.lineType,
    required this.lines,
    required Rect minimalRect,
  }) : super(minimalRect);
}
