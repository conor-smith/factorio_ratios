part of '../../graph.dart';

class GraphGeometry extends Geometry {
  final Geometry? top, left, bottom, right;

  GraphGeometry.fromLTRB(
    Geometry this.left,
    Geometry this.top,
    Geometry this.right,
    Geometry this.bottom,
  ) : super(
        Rect.fromLTRB(
          left.minimalRect.left,
          top.minimalRect.top,
          right.minimalRect.right,
          bottom.minimalRect.bottom,
        ),
      );

  const GraphGeometry.uninitialised()
    : top = null,
      left = null,
      bottom = null,
      right = null,
      super(Rect.zero);
}

class _GeometryOperation {
  // All of these elements are affected by drag operations
  final List<_MutableNodeGeometry> nodeGeometry;
  final List<_MutableEdgeGeometry> edgeGeometry;

  // These elements are only affected their connected nodes
  final List<_MutableEdgeGeometry> affectedEdgeGeometry;

  final bool isDragOperation;

  factory _GeometryOperation.dragOperation(
    Set<ProdLineNode> nodes,
    Set<DirectedEdge> edges,
  ) {
    Map<ProdLineNode, _MutableNodeGeometry> nodeData = {};
    Set<DirectedEdge> affectedEdges = {};

    for (var node in nodes) {
      nodeData[node] = _MutableNodeGeometry.from(node);
      affectedEdges.addAll([...node.parentOf, ...node.childOf]);
    }

    affectedEdges.removeAll(edges);
    var affectedEdgeData = buildEdgeData(affectedEdges, nodeData);
    var edgeData = buildEdgeData(edges, nodeData);

    return _GeometryOperation._(
      nodeData.values.toList(),
      edgeData,
      affectedEdgeData,
      true,
    );
  }

  factory _GeometryOperation.resizeOperation(
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

    var affectedEdgeData = buildEdgeData(affectedEdges, nodeData);

    return _GeometryOperation._(
      nodeData.values.toList(),
      const [],
      affectedEdgeData,
      false,
    );
  }

  _GeometryOperation._(
    this.nodeGeometry,
    this.edgeGeometry,
    this.affectedEdgeGeometry,
    this.isDragOperation,
  );

  static List<_MutableEdgeGeometry> buildEdgeData(
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
    if (!isDragOperation) {
      throw const GraphException(
        'Current cartesian operation is not a drag operation',
      );
    }

    for (var nodeData in nodeGeometry) {
      nodeData.shift(offset);
    }

    for (var edgeData in edgeGeometry) {
      edgeData.shiftAllLines(offset);
    }

    for (var edgeData in affectedEdgeGeometry) {
      edgeData.update();
    }

    notifyAllListeners();
  }

  void resizeNodes(
    double leftOffset,
    double topOffset,
    double rightOffset,
    double bottomOffset,
  ) {
    for (var nodeData in nodeGeometry) {
      nodeData.resize(leftOffset, topOffset, rightOffset, bottomOffset);
    }

    for (var edgeData in affectedEdgeGeometry) {
      edgeData.update();
    }

    notifyAllListeners();
  }

  void notifyAllListeners({bool cancel = false}) {
    for (var nodeData in nodeGeometry) {
      nodeData.node.notifyListeners(
        NodeEvent.tempGeometry(
          nodeData.node,
          cancel ? nodeData.node.geometry : nodeData,
        ),
      );
    }

    for (var edgeData in edgeGeometry.followedBy(affectedEdgeGeometry)) {
      edgeData.edge.notifyListeners(
        EdgeEvent.tempGeometry(
          edgeData.edge,
          cancel ? edgeData.edge.geometry : edgeData,
        ),
      );
    }
  }
}
