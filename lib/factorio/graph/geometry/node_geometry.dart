part of '../../graph.dart';

class NodeGeometry extends Geometry {
  const NodeGeometry(super.minimalRect);

  const NodeGeometry.uninitialised() : this(Rect.zero);
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
