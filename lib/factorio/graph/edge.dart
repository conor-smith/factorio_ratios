part of '../graph.dart';

enum ItemFlowDirection { parentToChild, childToParent }

enum Relationship {
  requestItems(ItemFlowDirection.childToParent),
  acceptExcess(ItemFlowDirection.childToParent);

  final ItemFlowDirection flowDirection;

  const Relationship(this.flowDirection);
}

enum Side { top, right, bottom, left }

// TODO - Add more linetypes
enum LineType { shortestPath }

class DirectedEdge {
  final BaseGraph parentGraph;
  final ItemData item;

  final ProdLineNode parent;
  final ProdLineNode child;

  final Relationship edgeType;
  double? _amount;

  Side _parentConnectionSide;
  Side _childConnectionSide;
  LineType _lineType;
  // List must always be ordered from parent to child
  final List<Offset> _lines = [];

  Function? _callbackOnChange;

  double? get amount => _amount;
  ItemFlowDirection get flowDirection => edgeType.flowDirection;
  LineType get lineType => _lineType;
  late final List<Offset> lines = UnmodifiableListView(_lines);

  DirectedEdge.addToGraph({
    required this.parentGraph,
    required this.item,
    required this.parent,
    required this.child,
    double? initialAmount,
    required this.edgeType,
    Side parentConnectionSide = Side.bottom,
    Side childConnectionSide = Side.top,
    LineType lineType = LineType.shortestPath,
  }) : _childConnectionSide = childConnectionSide,
       _parentConnectionSide = parentConnectionSide,
       _amount = initialAmount,
       _lineType = lineType {
    // Confirm both parent and child are valid
    if (parentGraph != parent.parentGraph || parentGraph != child.parentGraph) {
      throw const FactorioException(
        'Cannot connect two nodes from different graphs',
      );
    } else if (parent.children.contains(this)) {
      throw const FactorioException('Cannot create duplicate edge');
    }

    // Ensure no loops are created
    Set<ProdLineNode> visitedNodes = {};
    List<ProdLineNode> nodesToVisit = List.from(
      child.children.map((childEdge) => childEdge.child),
    );
    while (nodesToVisit.isNotEmpty) {
      ProdLineNode node = nodesToVisit.removeLast();
      if (node == parent) {
        throw const FactorioException('Cannot create loop');
      } else if (!visitedNodes.contains(node)) {
        visitedNodes.add(node);
        nodesToVisit.addAll(node.children.map((childEdge) => childEdge.child));
      }
    }

    parentGraph._edges.add(this);

    parentGraph._parents[child]!.add(this);
    parentGraph._children[parent]!.add(this);

    if (lineType == LineType.shortestPath) {
      _lines.add(_determineConnectionPoint(parent, parentConnectionSide));
      _lines.add(_determineConnectionPoint(child, childConnectionSide));
    }
  }

  void removeFromGraph() {
    parentGraph._edges.remove(this);

    parentGraph._parents[child]!.remove(this);
    parentGraph._children[parent]!.remove(this);
  }

  void setChangeCallback(Function changeCallback) {
    _callbackOnChange = changeCallback;
  }

  @override
  bool operator ==(Object other) {
    return other is DirectedEdge && other.hashCode == hashCode;
  }

  @override
  int get hashCode => parent.hashCode + child.hashCode + item.hashCode;

  void _parentUpdate(bool updateListener) {
    if (lineType == LineType.shortestPath) {
      _lines[0] = _determineConnectionPoint(parent, _parentConnectionSide);
    }

    if (updateListener) {
      _callbackOnChange!();
    }
  }

  void _childUpdate(bool updateListener) {
    if (lineType == LineType.shortestPath) {
      _lines[1] = _determineConnectionPoint(child, _childConnectionSide);
    }

    if (updateListener) {
      _callbackOnChange!();
    }
  }

  Offset _determineConnectionPoint(ProdLineNode node, Side side) =>
      switch (side) {
        Side.top => Offset(node.topLeft.dx + node.width / 2, node.topLeft.dy),
        Side.right => Offset(
          node.bottomRight.dx,
          node.topLeft.dy + node.height / 2,
        ),
        Side.bottom => Offset(
          node.topLeft.dx + node.width / 2,
          node.bottomRight.dy,
        ),
        Side.left => Offset(
          node._topLeft.dx,
          node.topLeft.dy + node.height / 2,
        ),
      };
}
