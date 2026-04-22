import 'dart:collection';
import 'dart:ui';

import 'package:factorio_ratios/factorio/graph.dart';
import 'package:factorio_ratios/factorio/graph/state.dart';

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

/// Geometry object for node
class NodeGeometry extends Geometry {
  /// Represents a node that has not yet been positioned
  static const uninitialised = NodeGeometry(Rect.zero);

  const NodeGeometry(super.minimalRect);
}

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
    var shortestLine = _shortestLine(
      edge.parent.geometry,
      edge.parent.geometry,
    );

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

/// Represents a drag or resize operation of one or multiple objects in a graph
/// Sends events to all affected object listeners on update containing new geometry data
/// However, none of these changes will actually be reflected in the affected objects
/// Only the graph itself can "commit" the geometry changes
class GeometryOperation {
  // All of these elements are affected by drag operations
  final List<_MutableNodeGeometry> _nodeGeometry;
  final List<_MutableEdgeGeometry> _edgeGeometry;

  // These elements are only affected their connected nodes
  final List<_MutableEdgeGeometry> _affectedEdgeGeometry;

  final bool _isDragOperation;

  /// Create a GeometryOperation to drag one or multiple nodes
  /// Any edges that connect selected nodes should also be added
  /// If they are not added, they will still be dragged, but results may be unexpected
  ///
  /// Any edges only connected to one of the dragged nodes will also be affected
  factory GeometryOperation.dragOperation(
    Set<ProdLineNode> nodes, [
    Set<DirectedEdge> edges = const {},
  ]) {
    Map<ProdLineNode, _MutableNodeGeometry> nodeData = {};
    Set<DirectedEdge> affectedEdges = {};

    for (var node in nodes) {
      nodeData[node] = _MutableNodeGeometry.from(node);
      affectedEdges.addAll([...node.parentOf, ...node.childOf]);
    }

    affectedEdges.removeAll(edges);
    var affectedEdgeData = _buildEdgeData(affectedEdges, nodeData);
    var edgeData = _buildEdgeData(edges, nodeData);

    return GeometryOperation._(
      nodeData.values.toList(),
      edgeData,
      affectedEdgeData,
      true,
    );
  }

  /// This is used to resize one or more nodes
  /// If multiple nodes are selected, all will be immediately resized
  /// to the same size as the node being operated on
  factory GeometryOperation.resizeOperation(
    Set<ProdLineNode> nodes,
    ProdLineNode selectedNode,
    RectPoint selectedPoint,
  ) {
    Map<ProdLineNode, _MutableNodeGeometry> nodeData = {};
    Set<DirectedEdge> affectedEdges = {};
    var opposite = selectedPoint.opposite;

    for (var node in nodes) {
      if (node == selectedNode) {
        nodeData[node] = _MutableNodeGeometry.from(node);
      } else {
        var offset =
            opposite.getPoint(node.rect) - opposite.getPoint(selectedNode.rect);
        var newBaseRect = selectedNode.rect.shift(offset);
        nodeData[node] = _MutableNodeGeometry.from(node, baseRect: newBaseRect);
      }
      affectedEdges.addAll([...node.parentOf, ...node.childOf]);
    }

    var affectedEdgeData = _buildEdgeData(affectedEdges, nodeData);

    return GeometryOperation._(
      nodeData.values.toList(),
      const [],
      affectedEdgeData,
      false,
    );
  }

  GeometryOperation._(
    this._nodeGeometry,
    this._edgeGeometry,
    this._affectedEdgeGeometry,
    this._isDragOperation,
  );

  static List<_MutableEdgeGeometry> _buildEdgeData(
    Iterable<DirectedEdge> edges,
    Map<ProdLineNode, _MutableNodeGeometry> nodeData,
  ) => edges
      .map(
        (edge) => _MutableEdgeGeometry.from(
          edge,
          nodeData[edge.parent] ?? edge.parent.geometry,
          nodeData[edge.child] ?? edge.child.geometry,
        ),
      )
      .toList();

  void drag(Offset offset) {
    if (!_isDragOperation) {
      throw const GraphException(
        'Current cartesian operation is not a drag operation',
      );
    }

    for (var nodeData in _nodeGeometry) {
      nodeData.shift(offset);
    }
    for (var edgeData in _edgeGeometry) {
      edgeData.shiftAllLines(offset);
    }
    for (var edgeData in _affectedEdgeGeometry) {
      edgeData.update();
    }

    _notifyAllListeners();
  }

  void resizeNodes(
    double leftOffset,
    double topOffset,
    double rightOffset,
    double bottomOffset,
  ) {
    for (var nodeData in _nodeGeometry) {
      nodeData.resize(leftOffset, topOffset, rightOffset, bottomOffset);
    }

    for (var edgeData in _affectedEdgeGeometry) {
      edgeData.update();
    }

    _notifyAllListeners();
  }

  void _notifyAllListeners({bool cancel = false}) {
    for (var nodeData in _nodeGeometry) {
      nodeData.node.notifyListeners(
        NodeEvent.tempGeometry(
          nodeData.node,
          cancel ? nodeData.node.geometry : nodeData,
        ),
      );
    }

    for (var edgeData in _edgeGeometry.followedBy(_affectedEdgeGeometry)) {
      edgeData.edge.notifyListeners(
        EdgeEvent.tempGeometry(
          edgeData.edge,
          cancel ? edgeData.edge.geometry : edgeData,
        ),
      );
    }
  }
}

class _MutableNodeGeometry implements NodeGeometry {
  final ProdLineNode node;

  final Rect baseRect;

  @override
  Rect minimalRect;

  _MutableNodeGeometry.from(this.node, {Rect? baseRect})
    : baseRect = baseRect ?? node.rect,
      minimalRect = baseRect ?? node.rect;

  void shift(Offset offset) {
    minimalRect = baseRect.shift(offset);
  }

  void resize(
    double leftOffset,
    double topOffset,
    double rightOffset,
    double bottomOffset,
  ) {
    minimalRect = Rect.fromLTRB(
      baseRect.left + leftOffset,
      baseRect.top + topOffset,
      baseRect.right + rightOffset,
      baseRect.bottom + bottomOffset,
    );
  }

  NodeGeometry finish() {
    return NodeGeometry(minimalRect);
  }
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
    : minimalRect = edge.geometry.minimalRect,
      lineType = edge.lineType,
      _baseLines = edge.lines,
      _transformedLines = List.from(edge.lines);

  void update() {
    switch (lineType) {
      case LineType.shortestPath:
        _transformedLines[0] = EdgeGeometry._shortestLine(
          edge.parent.geometry,
          edge.child.geometry,
        );
    }
  }

  void shiftAllLines(Offset offset) {
    for (var i = 0; i < _baseLines.length; i++) {
      _transformedLines[i] = _baseLines[i].shift(offset);
    }
  }

  EdgeGeometry finish() => switch (lineType) {
    LineType.shortestPath => EdgeGeometry._(
      lineType: LineType.shortestPath,
      lines: List.unmodifiable(_transformedLines),
      minimalRect: Rect.fromPoints(
        _transformedLines[0].start,
        _transformedLines[0].end,
      ),
    ),
  };
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
