part of 'geometry.dart';

/// Geometry object for node
class NodeGeometry extends Geometry {
  /// Represents a node that has not yet been positioned
  static const uninitialised = NodeGeometry(Rect.zero);

  const NodeGeometry(super.minimalRect);
}

