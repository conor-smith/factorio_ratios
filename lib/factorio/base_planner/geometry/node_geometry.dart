import 'dart:ui';

import 'package:factorio_ratios/factorio/base_planner/geometry/geometry.dart';

class NodeGeometry implements Geometry {
  static const uninitialised = NodeGeometry(Rect.zero);
  static const double defaultWidth = 100,
      defaultHeight = 100,
      defaultPadding = 50;

  @override
  final Rect minimalRect;

  const NodeGeometry(this.minimalRect);

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}
