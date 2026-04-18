part of '../../graph.dart';

class EdgeGeometry extends Geometry {
  final LineType lineType;
  // Goes from parent to child
  final List<Line> lines;

  const EdgeGeometry.uninitialised()
    : lineType = LineType.shortestPath,
      lines = const [Line.uninitialised()],
      super(Rect.zero);

  EdgeGeometry.shortestPath(Line line)
    : lineType = LineType.shortestPath,
      lines = List.unmodifiable([line]),
      super(Rect.fromPoints(line.start, line.end));
}

class _MutableEdgeGeometry implements EdgeGeometry {
  final DirectedEdge edge;

  final NodeGeometry parentNodeData, childNodeData;

  @override
  final Rect minimalRect;
  @override
  final LineType lineType;

  final List<Line> _baseLines;
  final List<Line> _transformedLines;
  @override
  late final List<Line> lines = UnmodifiableListView(_transformedLines);

  _MutableEdgeGeometry.from(this.edge, this.parentNodeData, this.childNodeData)
    : minimalRect = edge._geometry.minimalRect,
      lineType = edge.lineType,
      _baseLines = edge.lines,
      _transformedLines = List.from(edge.lines);

  void update() {
    switch (lineType) {
      case LineType.shortestPath:
        _transformedLines[1] = Line.shortest(
          parentNodeData.minimalRect,
          childNodeData.minimalRect,
        );
    }
  }

  void shiftAllLines(Offset offset) {
    for (var i = 0; i < _baseLines.length; i++) {
      _transformedLines[i] = _baseLines[i].shift(offset);
    }
  }

  EdgeGeometry finish() => switch (lineType) {
    LineType.shortestPath => EdgeGeometry.shortestPath(_baseLines[0]),
  };
}
