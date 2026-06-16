part of 'node.dart';

class ProdLineNode implements NodeElement<ProdLineNodeState, NodeEvent> {
  final BasePlanner _basePlanner;

  @override
  final int id;

  @override
  final Graph parentGraph;
  @override
  final NodeType nodeType;

  // For convenience
  @override
  ItemIo? get requirements => state.requirements;
  @override
  ProductionLine get productionLine => _state.productionLine;
  @override
  NodeGeometry get nodeGeometry => state.nodeGeometry;
  @override
  Set<Edge> get parents => state.parents;
  @override
  Set<Edge> get children => state.children;
  @override
  Map<InGameItem, List<Edge>> get inputEdges => state.inputEdges;
  @override
  Map<InGameItem, List<Edge>> get outputEdges => state.outputEdges;
  @override
  ProductionLineIo? get io => state.io;
  @override
  Set<InGameItem> get inputItems => state.productionLine.inputItems;
  @override
  Set<InGameItem> get outputItems => state.productionLine.outputItems;

  final EventNotifier<NodeEvent> _notifier = EventNotifierImpl();
  ProdLineNodeStateImpl _state;
  ProdLineNodeStateBuilder? _builder;

  ProdLineNode.addToBasePlanner({
    required BasePlanner basePlanner,
    required this.parentGraph,
    required this.nodeType,
    required ProductionLine productionLine,
  }) : _basePlanner = basePlanner,
       id = BasePlannerElement.generateId(),
       _state = ProdLineNodeStateImpl._(
         productionLine: productionLine,
         isFirstState: true,
       ) {
    _builder = ProdLineNodeStateBuilder._new(this);
  }

  @override
  ProdLineNodeState get state => _builder ?? _state;
  @override
  set state(ProdLineNodeStateImpl state) {
    _basePlanner.throwIfMutationNotPermitted();

    // Validate state, update listeners
    _state = state;
  }

  @override
  void remove() => ProdLineNodeStateBuilder._remove(this);

  @override
  ProdLineNodeStateBuilder getStateBuilder() {
    _builder ??= ProdLineNodeStateBuilder._from(this);

    return _builder!;
  }

  @override
  void cancelStateBuilder() => _builder = null;

  @override
  void addListener(Object listener, Function(NodeEvent event) callback) =>
      _notifier.addListener(listener, callback);
  @override
  void removeListener(Object listener) => _notifier.removeListener(listener);
  @override
  void clearListeners() => _notifier.clearListeners();
  @override
  void notifyListeners(NodeEvent event) => _notifier.notifyListeners(event);

  @override
  bool get isSelected => _basePlanner.selectedElements.contains(this);

  @override
  void select() => _basePlanner.selectElement(this);

  @override
  void deselect() => _basePlanner.deselectElement(this);

  @override
  void notifyListenersOfGeometryUpdate(NodeGeometry nodeGeometry) {
    // TODO: implement notifyListenersOfGeometryUpdate
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

class NodeEvent {
  NodeEvent.geometryOp(NodeGeometry nodeGeometry) {
    throw UnimplementedError();
  }
}
