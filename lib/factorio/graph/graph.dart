import 'dart:collection';
import 'dart:ui';

import 'package:factorio_ratios/factorio/factorio.dart';
import 'package:factorio_ratios/factorio/graph/geometry/geometry.dart';
import 'package:factorio_ratios/factorio/graph/state/state.dart';
import 'package:factorio_ratios/factorio/models/models.dart';
import 'package:factorio_ratios/factorio/production_lines/production_line.dart';

part 'base_graph.dart';
part 'edge.dart';
part 'event_history.dart';
part 'node.dart';

class GraphException implements Exception {
  final String message;

  const GraphException(this.message);

  @override
  String toString() => 'GraphException: $message';
}
