part of 'geometry.dart';

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

  final _OperationType _operationType;
  bool _isFinished = false;

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
      affectedEdges.addAll([...node.children, ...node.parents]);
    }

    affectedEdges.removeAll(edges);
    var affectedEdgeData = _buildEdgeData(affectedEdges, nodeData);
    var edgeData = _buildEdgeData(edges, nodeData);

    return GeometryOperation._(
      nodeData.values.toList(),
      edgeData,
      affectedEdgeData,
      _OperationType.drag,
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
      affectedEdges.addAll([...node.children, ...node.parents]);
    }

    var affectedEdgeData = _buildEdgeData(affectedEdges, nodeData);

    return GeometryOperation._(
      nodeData.values.toList(),
      const [],
      affectedEdgeData,
      _OperationType.resize,
    );
  }

  GeometryOperation._(
    this._nodeGeometry,
    this._edgeGeometry,
    this._affectedEdgeGeometry,
    this._operationType,
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
    if (_operationType != _OperationType.drag) {
      throw const GraphException('Geometry operation is not a drag operation');
    } else if (_isFinished) {
      throw const GraphException('Geometry operation is finished');
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
    if (_operationType != _OperationType.resize) {
      throw const GraphException('Geometry is not a resize operation');
    } else if (_isFinished) {
      throw const GraphException('Geometry operation is finished');
    }

    for (var nodeData in _nodeGeometry) {
      nodeData.resize(leftOffset, topOffset, rightOffset, bottomOffset);
    }

    for (var edgeData in _affectedEdgeGeometry) {
      edgeData.update();
    }

    _notifyAllListeners();
  }

  void applyNewGeometryAndFinish() {
    for (var nodeGeometry in _nodeGeometry) {
      nodeGeometry.node.apply(
        NodeEvent.updateGeometry(nodeGeometry.node, nodeGeometry.finish()),
      );
    }

    for (var edgeGeometry in [..._affectedEdgeGeometry, ..._edgeGeometry]) {
      edgeGeometry.edge.apply(
        EdgeEvent.updateGeometry(edgeGeometry.edge, edgeGeometry.finish()),
      );
    }
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

enum _OperationType { drag, resize }
