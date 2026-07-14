part of 'graph.dart';

abstract class GraphState extends NodeState {
  String get name;
  Icon? get icon;
  Set<ProdLineNode> get prodLineNodes;
  Set<Graph> get graphNodes;
  Map<InGameItem, ProdLineNode> get inputNodes;
  Map<InGameItem, ProdLineNode> get outputNodes;
  Set<NodeElement> get allNodes;
  Set<Edge> get edges;

  GraphLayout get layout;
  LayoutOrientation get orientation;

  @override
  GraphIo get ioData;

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

class GraphStateImpl with NodeState implements GraphState, ToJson {
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
  final ItemIoImpl edgeConstraints;
  @override
  final ItemIoImpl ioRatios;
  @override
  final ItemIoImpl unusedIo;
  @override
  final GraphIo ioData;
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
  final GraphLayout layout;
  @override
  final LayoutOrientation orientation;

  GraphStateImpl({
    required this.name,
    required this.icon,
    required Iterable<ProdLineNode> prodLineNodes,
    required Iterable<Graph> graphNodes,
    required Iterable<Edge> edges,
    required Map<InGameItem, ProdLineNode> inputNodes,
    required Map<InGameItem, ProdLineNode> outputNodes,
    required this.ioRatios,
    required this.unusedIo,
    required this.edgeConstraints,
    required this.geometry,
    required this.ioData,
    required this.layout,
    required this.orientation,
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
       outputItems = Set.unmodifiable(outputNodes.keys);

  GraphStateImpl.rootGraphFirstState(this.icon)
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
      edgeConstraints = ItemIoImpl.empty,
      ioRatios = ItemIoImpl.empty,
      unusedIo = ItemIoImpl.empty,
      geometry = NodeGeometryImpl.uninitialised,
      ioData = const GraphIo.empty(),
      layout = GraphLayout.table,
      orientation = LayoutOrientation.up;

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
      edgeConstraints = ItemIoImpl.empty,
      ioRatios = ItemIoImpl.empty,
      unusedIo = ItemIoImpl.empty,
      geometry = NodeGeometryImpl.uninitialised,
      ioData = const GraphIo.empty(),
      layout = GraphLayout.table,
      orientation = LayoutOrientation.up;

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}
