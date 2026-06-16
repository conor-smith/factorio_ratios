import 'dart:ui';

import 'package:factorio_ratios/factorio/base_planner/base_planner.dart';

abstract interface class Geometry {
  Rect get rect;
}

abstract interface class GeometryBuilder<G extends Geometry>
    implements Builder<G> {
  void shift(Offset offset);
}

class Line {
  final Offset start;
  final Offset end;

  const Line(this.start, this.end);

  Line.shortestLine(Rect start, Rect end) : this(start.center, end.center);

  Line shift(Offset offset) => Line(start + offset, end + offset);
}
