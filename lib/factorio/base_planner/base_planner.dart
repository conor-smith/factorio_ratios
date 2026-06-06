import 'package:factorio_ratios/factorio/base_planner/edge.dart';
import 'package:factorio_ratios/factorio/base_planner/graph.dart';
import 'package:factorio_ratios/factorio/base_planner/node.dart';
import 'package:factorio_ratios/json/json.dart';

class BasePlanner implements ToJson {
  GraphStateBuilder getGraphStateBuilder(Graph graph) {
    // TODO: implement getGraphStateBuilder
    throw UnimplementedError();
  }

  NodeStateBuilder getNodeStateBuilder(Node node) {
    // TODO: implement getGraphStateBuilder
    throw UnimplementedError();
  }

  EdgeStateBuilder getEdgeStateBuilder(Edge edge) {
    // TODO: implement getGraphStateBuilder
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class BasePlannerSnapshot implements ToJson {
  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class BasePlannerSnapshotBuilder {
  // TODO
}
