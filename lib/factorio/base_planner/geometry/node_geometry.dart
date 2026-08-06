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

  factory NodeGeometryImpl.fromLTRB(
    double left,
    double top,
    double right,
    double bottom, [
    double? snapValue,
  ]) {
    Rect rect = snapValue == null
        ? Rect.fromLTRB(left, top, right, bottom)
        : Rect.fromLTRB(
            roundToNearestSnapValue(left, snapValue),
            roundToNearestSnapValue(top, snapValue),
            roundToNearestSnapValue(right, snapValue),
            roundToNearestSnapValue(bottom, snapValue),
          );

    return NodeGeometryImpl(rect);
  }

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}
