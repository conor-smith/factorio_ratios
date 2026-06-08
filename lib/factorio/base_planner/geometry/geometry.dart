import 'dart:ui';

import 'package:factorio_ratios/json/json.dart';

abstract interface class Geometry implements ToJson {
  Rect get minimalRect;
}

class Line {
  final Offset start;
  final Offset end;

  const Line(this.start, this.end);

  Line.shortestLine(Rect start, Rect end) : this(start.center, end.center);

  Line shift(Offset offset) => Line(start + offset, end + offset);
}
