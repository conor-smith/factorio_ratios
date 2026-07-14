part of 'change_trackers.dart';

class GraphStateBuilder extends NodeStateBuilder<GraphStateImpl>
    implements GraphState {
  String _name;
  Icon? _icon;
  final Set<ProdLineNode> _prodLineNodes;
  final Set<Graph> _graphNodes;
  final Map<InGameItem, ProdLineNode> _inputNodes;
  final Map<InGameItem, ProdLineNode> _outputNodes;
  final Set<Edge> _edges;
  NodeGeometryImpl _geometry;

  GraphLayout _layout;
  LayoutOrientation _orientation;

  Map<InGameItem, Set<Edge>>? _cachedParents;
  Map<InGameItem, Set<Edge>>? _cachedChildren;

  GraphIo _ioData;
  ItemIoImpl _ioRatios;
  ItemIoImpl _unusedIo;

  @override
  String get name => _name;
  @override
  Icon? get icon => _icon;
  @override
  late final Set<ProdLineNode> prodLineNodes = UnmodifiableSetView(
    _prodLineNodes,
  );
  @override
  late final Set<Graph> graphNodes = UnmodifiableSetView(_graphNodes);
  @override
  late final Map<InGameItem, ProdLineNode> inputNodes = UnmodifiableMapView(
    _inputNodes,
  );
  @override
  late final Map<InGameItem, ProdLineNode> outputNodes = UnmodifiableMapView(
    _outputNodes,
  );
  @override
  late final Set<Edge> edges = UnmodifiableSetView(_edges);
  @override
  NodeGeometryImpl get geometry => _geometry;

  @override
  ItemIoImpl get ioRatios => _ioRatios;
  @override
  ItemIoImpl get edgeConstraints => _ioData.constraints;
  @override
  ItemIoImpl get unusedIo => _unusedIo;

  @override
  GraphIo get ioData => _ioData;

  @override
  Set<InGameItem> get inputItems => _inputNodes.keys.toSet();
  @override
  Set<InGameItem> get outputItems => _outputNodes.keys.toSet();
  @override
  Map<InGameItem, Set<Edge>> get parents {
    _cachedParents ??= GraphState.calculateParents(outputNodes);
    return _cachedParents!;
  }

  @override
  Map<InGameItem, Set<Edge>> get children {
    _cachedChildren ??= GraphState.calculateChildren(inputNodes);
    return _cachedChildren!;
  }

  @override
  Set<NodeElement> get allNodes => GraphState.calculateAllNodes(
    _prodLineNodes,
    _graphNodes,
    _inputNodes,
    _outputNodes,
  ).toSet();

  @override
  GraphLayout get layout => _layout;
  @override
  LayoutOrientation get orientation => _orientation;

  GraphStateBuilder.initial([Icon? icon])
    : _name = 'graph',
      _icon = icon,
      _ioData = const GraphIo.empty(),
      _ioRatios = ItemIoImpl.empty,
      _unusedIo = ItemIoImpl.empty,
      _prodLineNodes = {},
      _graphNodes = {},
      _inputNodes = {},
      _outputNodes = {},
      _edges = {},
      _geometry = NodeGeometryImpl.uninitialised,
      _layout = GraphLayout.table,
      _orientation = LayoutOrientation.up,
      _cachedParents = {},
      _cachedChildren = {};

  GraphStateBuilder.from(GraphStateImpl previousState)
    : _name = previousState.name,
      _icon = previousState.icon,
      _prodLineNodes = Set.from(previousState.prodLineNodes),
      _graphNodes = Set.from(previousState.graphNodes),
      _inputNodes = Map.from(previousState.inputNodes),
      _outputNodes = Map.from(previousState.outputNodes),
      _edges = Set.from(previousState.edges),
      _cachedParents = previousState.parents,
      _cachedChildren = previousState.children,
      _geometry = previousState.geometry,
      _layout = previousState.layout,
      _orientation = previousState.orientation,
      _ioRatios = previousState.ioRatios,
      _ioData = previousState.ioData,
      _unusedIo = previousState.unusedIo;

  void updateName(String newName) => _name = newName;

  void updateIcon(Icon newIcon) => _icon = newIcon;
  void clearIcon() => _icon = null;

  @override
  void updateGeometry(NodeGeometryImpl geometry) => _geometry = geometry;

  void updateLayout(GraphLayout newLayout) => _layout = newLayout;
  void updateOrientation(LayoutOrientation newOrientation) =>
      _orientation = newOrientation;

  @override
  void _updateUnusedIo(ItemIoImpl newUnusedIo) => _unusedIo = newUnusedIo;
  void _updateIoData(GraphIo newIoData) {
    _ioData = newIoData;
    _ioRatios = newIoData.itemIo.convertToRatios();
  }

  @override
  GraphStateImpl build() => GraphStateImpl(
    icon: _icon,
    name: _name,
    prodLineNodes: _prodLineNodes,
    graphNodes: _graphNodes,
    inputNodes: _inputNodes,
    outputNodes: _outputNodes,
    edges: _edges,
    geometry: _geometry,
    ioRatios: _ioRatios,
    unusedIo: _unusedIo,
    layout: _layout,
    orientation: _orientation,
    ioData: _ioData,
  );
}
