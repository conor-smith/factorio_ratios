part of 'graph.dart';

abstract class GraphState {
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

  Map<InGameItem, Set<Edge>> get parents;
  Map<InGameItem, Set<Edge>> get children;
  ItemIoImpl get ioRatios;
  GraphIo get ioData;
  NodeGeometryImpl get geometry;

  GraphLayout get layout;

  static Iterable<NodeElement> calculateAllNodes(
    Iterable<ProdLineNode> prodLineNodes,
    Iterable<Graph> graphNodes,
    Map<InGameItem, ProdLineNode> inputNodes,
    Map<InGameItem, ProdLineNode> outputNodes,
  ) => (prodLineNodes as Iterable<NodeElement>)
      .followedBy(graphNodes)
      .followedBy(inputNodes.values)
      .followedBy(outputNodes.values);

  static Map<InGameItem, Set<Edge>> calculateParents(
    Map<InGameItem, ProdLineNode> outputNodes,
  ) => outputNodes.map(
    (item, node) => MapEntry(item, node.parents[item] ?? const {}),
  )..removeWhere((item, edges) => edges.isEmpty);

  static Map<InGameItem, Set<Edge>> calculateChildren(
    Map<InGameItem, ProdLineNode> inputNodes,
  ) => inputNodes.map(
    (item, node) => MapEntry(item, node.children[item] ?? const {}),
  )..removeWhere((item, edges) => edges.isEmpty);
}

class GraphStateImpl implements GraphState, ToJson {
  static const uninitialised = GraphStateImpl._uninitialised();

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
  final Map<InGameItem, Set<Edge>> parents;
  @override
  final Map<InGameItem, Set<Edge>> children;
  @override
  final Set<InGameItem> inputItems;
  @override
  final Set<InGameItem> outputItems;

  @override
  final Set<NodeElement> allNodes;

  @override
  final ItemIoImpl ioRatios;
  @override
  final GraphIo ioData;

  @override
  final GraphLayout layout;

  GraphStateImpl({
    required Graph graph,
    required this.name,
    required this.icon,
    required Iterable<ProdLineNode> prodLineNodes,
    required Iterable<Graph> graphNodes,
    required Iterable<Edge> edges,
    required Map<InGameItem, ProdLineNode> inputNodes,
    required Map<InGameItem, ProdLineNode> outputNodes,
    required this.ioRatios,
    required this.geometry,
    required this.ioData,
    required this.layout,
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
       parents = Map.unmodifiable(
         GraphState.calculateParents(outputNodes)
           ..updateAll((item, edges) => Set.unmodifiable(edges)),
       ),
       children = Map.unmodifiable(
         GraphState.calculateChildren(inputNodes)
           ..updateAll((item, edges) => Set.unmodifiable(edges)),
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

  const GraphStateImpl._rootGraph(this.icon)
    : name = 'Root Graph',
      prodLineNodes = const {},
      graphNodes = const {},
      inputNodes = const {},
      outputNodes = const {},
      allNodes = const {},
      edges = const {},
      inputItems = const {},
      outputItems = const {},
      parents = const {},
      children = const {},
      ioRatios = ItemIoImpl.empty,
      geometry = NodeGeometryImpl.uninitialised,
      ioData = const GraphIo.empty(),
      layout = GraphLayout.table;

  const GraphStateImpl._uninitialised()
    : name = '',
      icon = null,
      prodLineNodes = const {},
      graphNodes = const {},
      inputNodes = const {},
      outputNodes = const {},
      allNodes = const {},
      edges = const {},
      inputItems = const {},
      outputItems = const {},
      parents = const {},
      children = const {},
      ioRatios = ItemIoImpl.empty,
      geometry = NodeGeometryImpl.uninitialised,
      ioData = const GraphIo.empty(),
      layout = GraphLayout.table;

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}
