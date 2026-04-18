import 'dart:collection';
import 'dart:ui';

import 'package:factorio_ratios/factorio/factorio.dart';
import 'package:factorio_ratios/factorio/models.dart';
import 'package:factorio_ratios/factorio/production_line.dart';
import 'package:factorio_ratios/state_traversal/stateful.dart';

part 'graph/base_graph.dart';
part 'graph/edge.dart';
part 'graph/node.dart';
part 'graph/geometry/geometry.dart';
part 'graph/geometry/graph_geometry.dart';
part 'graph/geometry/node_geometry.dart';
part 'graph/geometry/edge_geometry.dart';
part 'graph/state/global_state.dart';
part 'graph/state/graph_event.dart';
part 'graph/state/node_event.dart';
part 'graph/state/edge_event.dart';

class GraphException implements Exception {
  final String message;

  const GraphException(this.message);

  @override
  String toString() => 'GraphException: $message';
}

void _removedWhereBothContain(Set set1, Set set2) {
  for (var item in List.from(set1)) {
    if (set2.contains(item)) {
      set1.remove(item);
      set2.remove(item);
    }
  }
}
