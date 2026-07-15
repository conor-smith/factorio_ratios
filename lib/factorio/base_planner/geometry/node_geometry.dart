import 'dart:ui';

import 'package:factorio_ratios/factorio/base_planner/geometry/geometry.dart';
import 'package:factorio_ratios/utility/json.dart';

abstract interface class NodeGeometry implements Geometry {}

class NodeGeometryImpl implements NodeGeometry, ToJson {
  static const uninitialised = NodeGeometryImpl(Rect.zero);
  static const double defaultWidth = 100,
      defaultHeight = 100,
      defaultPadding = 50;

  @override
  final Rect rect;

  const NodeGeometryImpl(this.rect);

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}
