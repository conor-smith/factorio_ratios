import 'dart:collection';

import 'package:factorio_ratios/factorio/models.dart';
import 'package:factorio_ratios/factorio/production_line.dart';

part 'graph/vertex_and_edge.dart';

class Graph extends BasicUpdateable implements ProductionLine {
  final List<Vertex> _vertices = [];
  final List<Edge> _edges = [];

  late final List<Vertex> vertices = UnmodifiableListView(_vertices);
  late final List<Edge> edges = UnmodifiableListView(_edges);

  @override
  void update() {
    // TODO: implement update
    super.update();
  }
  
  @override
  // TODO: implement inputPerSecond
  Map<ItemData, double> get ioPerSecond => throw UnimplementedError();
}