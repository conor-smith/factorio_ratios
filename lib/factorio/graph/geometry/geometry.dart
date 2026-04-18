part of '../../graph.dart';

abstract class Geometry {
  final Rect minimalRect;

  const Geometry(this.minimalRect);

  static int topMost(Geometry data1, Geometry data2) =>
      -data1.minimalRect.top.compareTo(data2.minimalRect.top);
  static int leftMost(Geometry data1, Geometry data2) =>
      -data1.minimalRect.left.compareTo(data2.minimalRect.left);
  static int bottomMost(Geometry data1, Geometry data2) =>
      data1.minimalRect.bottom.compareTo(data2.minimalRect.bottom);
  static int rightMost(Geometry data1, Geometry data2) =>
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
  Line.shortest(Rect start, Rect end) : this(start.center, end.center);

  const Line.uninitialised() : this(Offset.zero, Offset.zero);

  Line shift(Offset shift) => Line(start + shift, end + shift);
}
