part of 'graph.dart';

abstract class GraphState implements NodeState {
  String get name;
  Icon? get icon;
  Set<ProdLineNode> get prodLineNodes;
  Set<Graph> get graphNodes;
  Map<InGameItem, ProdLineNode> get inputNodes;
  Map<InGameItem, ProdLineNode> get outputNodes;
  Set<NodeElement> get allNodes;
  Set<Edge> get edges;
  Set<InGameItem> get inputItems;
  Set<InGameItem> get outputItems;
  @override
  GraphIo get io;

  static Iterable<NodeElement> calculateAllNodes(
    Iterable<ProdLineNode> prodLineNodes,
    Iterable<Graph> graphNodes,
    Map<InGameItem, ProdLineNode> inputNodes,
    Map<InGameItem, ProdLineNode> outputNodes,
  ) => Iterable<NodeElement>.empty()
      .followedBy(prodLineNodes)
      .followedBy(graphNodes)
      .followedBy(inputNodes.values)
      .followedBy(outputNodes.values);
}

class GraphStateImpl implements GraphState, ToJson {
  @override
  final String name;
  @override
  final Icon? icon;
  @override
  final Set<ProdLineNode> prodLineNodes;
  @override
  final Set<Graph> graphNodes;
  @override
  final Map<InGameItem, ProdLineNode> inputNodes;
  @override
  final Map<InGameItem, ProdLineNode> outputNodes;
  @override
  final Set<Edge> edges;
  @override
  final NodeGeometryImpl geometry;
  @override
  final Set<Edge> parents;
  @override
  final Set<Edge> children;
  @override
  final Set<InGameItem> inputItems;
  @override
  final Set<InGameItem> outputItems;
  @override
  final GraphIo io;

  @override
  final Set<NodeElement> allNodes;

  GraphStateImpl._initial({
    required this.name,
    required this.icon,
    required this.geometry,
  }) : prodLineNodes = const {},
       graphNodes = const {},
       inputNodes = const {},
       outputNodes = const {},
       edges = const {},
       parents = const {},
       children = const {},
       inputItems = const {},
       outputItems = const {},
       allNodes = const {},
       io = const GraphIo.empty();

  GraphStateImpl({
    required Graph graph,
    required this.name,
    required this.icon,
    required Iterable<ProdLineNode> prodLineNodes,
    required Iterable<Graph> graphNodes,
    required Iterable<Edge> edges,
    required Map<InGameItem, ProdLineNode> inputNodes,
    required Map<InGameItem, ProdLineNode> outputNodes,
    required this.geometry,
    required this.io,
  }) : prodLineNodes = Set.unmodifiable(prodLineNodes),
       graphNodes = Set.unmodifiable(graphNodes),
       edges = Set.unmodifiable(edges),
       inputNodes = Map.unmodifiable(inputNodes),
       outputNodes = Map.unmodifiable(outputNodes),
       allNodes = Set.unmodifiable(
         GraphState.calculateAllNodes(
           prodLineNodes,
           graphNodes,
           inputNodes,
           outputNodes,
         ),
       ),
       parents = Set.unmodifiable(
         outputNodes.values.expand((node) => node.parents),
       ),
       children = Set.unmodifiable(
         inputNodes.values.expand((node) => node.children),
       ),
       inputItems = Set.unmodifiable(inputNodes.keys),
       outputItems = Set.unmodifiable(outputNodes.keys) {
    if (graph.isRoot &&
        (this.inputNodes.isNotEmpty || this.outputNodes.isNotEmpty)) {
      throw const GraphException(
        'Root graph is not permitted to have output or input nodes',
      );
    }
  }

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}
