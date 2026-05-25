part of 'state.dart';

class GraphEvent extends MutationEvent {
  final PlanetBaseGraph graph;

  final Set<GraphEventType> mutations;

  final List<ProdLineNode>? oldNodes, newNodes;
  final List<DirectedEdge>? oldEdges, newEdges;
  final GraphGeometry? oldGeometry, newGeometry;
  final Set<InGameItem>? oldInputs, oldOutputs, newInputs, newOutputs;
  final ItemAmounts? oldInputRatios,
      oldOutputRatios,
      newInputRatios,
      newOutputRatios;

  final GraphEvent? _original;
  @override
  final bool isReversed;
  @override
  late final GraphEvent reversed = _original ?? GraphEvent._reverse(this);

  // These are useful for the UI
  late final List<ProdLineNode> addedNodes =
      _original?.removedNodes ??
      (newNodes == null
          ? const []
          : newNodes!.where((node) => !oldNodes!.contains(node)).toList());
  List<ProdLineNode> get removedNodes =>
      _original?.addedNodes ??
      (oldNodes == null
          ? const []
          : oldNodes!.where((node) => !newNodes!.contains(node)).toList());

  List<DirectedEdge> get addedEdges =>
      _original?.removedEdges ??
      (newEdges == null
          ? const []
          : newEdges!.where((edge) => !oldEdges!.contains(edge)).toList());
  List<DirectedEdge> get removedEdges =>
      _original?.addedEdges ??
      (oldEdges == null
          ? const []
          : oldEdges!.where((edge) => !newEdges!.contains(edge)).toList());

  GraphEvent.newNode(PlanetBaseGraph graph, ProdLineNode newNode)
    : this._(
        graph,
        const {GraphEventType.updateNodes},
        oldNodes: graph.nodes,
        newNodes: [...graph.nodes, newNode],
      );

  GraphEvent.removeNode(PlanetBaseGraph graph, ProdLineNode removedNode)
    : this._(
        graph,
        const {GraphEventType.updateNodes},
        oldNodes: graph.nodes,
        newNodes: List.from(graph.nodes)..remove(removedNode),
      );

  GraphEvent.newEdge(PlanetBaseGraph graph, DirectedEdge newEdge)
    : this._(
        graph,
        const {GraphEventType.updateEdges},
        oldEdges: graph.edges,
        newEdges: [...graph.edges, newEdge],
      );

  GraphEvent.removeEdge(PlanetBaseGraph graph, DirectedEdge removedEdge)
    : this._(
        graph,
        const {GraphEventType.updateEdges},
        oldEdges: graph.edges,
        newEdges: List.from(graph.edges)..remove(removedEdge),
      );

  GraphEvent.removeMultipleEdges(
    PlanetBaseGraph graph,
    Iterable<DirectedEdge> removedEdges,
  ) : this._(
        graph,
        const {GraphEventType.updateEdges},
        oldEdges: graph.edges,
        newEdges: Set.from(graph.edges)..removeAll(removedEdges),
      );

  GraphEvent.newInput(PlanetBaseGraph graph, InGameItem newInput)
    : this._(
        graph,
        const {GraphEventType.updateInput},
        oldInputs: graph.inputItems,
        newInputs: [...graph.inputItems, newInput],
      );

  GraphEvent.removeInput(PlanetBaseGraph graph, InGameItem removedInput)
    : this._(
        graph,
        const {GraphEventType.updateInput},
        oldInputs: graph.inputItems,
        newInputs: List.from(graph.inputItems)..remove(removedInput),
      );

  GraphEvent.newOutput(PlanetBaseGraph graph, InGameItem newOutput)
    : this._(
        graph,
        const {GraphEventType.updateOutput},
        oldOutputs: graph.outputItems,
        newOutputs: [...graph.outputItems, newOutput],
      );

  GraphEvent.removeOutput(PlanetBaseGraph graph, InGameItem removedOutput)
    : this._(
        graph,
        const {GraphEventType.updateOutput},
        oldOutputs: graph.outputItems,
        newOutputs: List.from(graph.outputItems)..remove(removedOutput),
      );

  GraphEvent.newIoRatios(
    PlanetBaseGraph graph, {
    required ItemAmounts newInputRatios,
    required ItemAmounts newOutputRatios,
  }) : this._(
         graph,
         {GraphEventType.updateRatios},
         oldInputRatios: graph.inputRatios,
         oldOutputRatios: graph.outputRatios,
         newInputRatios: newInputRatios,
         newOutputRatios: newOutputRatios,
       );

  GraphEvent.clearIoRatios(PlanetBaseGraph graph)
    : this._(
        graph,
        {GraphEventType.updateRatios},
        oldInputRatios: graph.inputRatios,
        oldOutputRatios: graph.outputRatios,
      );

  GraphEvent.updateGeometry(PlanetBaseGraph graph, GraphGeometry newGeometry)
    : this._(
        graph,
        {GraphEventType.geometryUpdate},
        oldGeometry: graph.geometry,
        newGeometry: newGeometry,
      );

  GraphEvent.clearGeometry(PlanetBaseGraph graph)
    : this._(
        graph,
        {GraphEventType.geometryUpdate},
        oldGeometry: graph.geometry,
        newGeometry: GraphGeometry.uninitialised,
      );

  factory GraphEvent.combine(List<GraphEvent> orderedEvents) {
    Set<GraphEventType> mutations = {};

    GraphEvent? oldNodeEvent, newNodeEvent;
    GraphEvent? oldEdgeEvent, newEdgeEvent;
    GraphEvent? oldInputEvent, newInputEvent;
    GraphEvent? oldOutputEvent, newOutputEvent;
    GraphEvent? oldRatiosEvent, newRatiosEvent;
    GraphEvent? oldGeometryEvent, newGeometryEvent;

    for (var event in orderedEvents) {
      mutations.addAll(event.mutations);
      for (var mutation in event.mutations) {
        switch (mutation) {
          case GraphEventType.updateNodes:
            oldNodeEvent ??= event;
            newNodeEvent = event;

          case GraphEventType.updateEdges:
            oldEdgeEvent ??= event;
            newEdgeEvent = event;

          case GraphEventType.updateInput:
            oldInputEvent ??= event;
            newInputEvent = event;

          case GraphEventType.updateOutput:
            oldOutputEvent ??= event;
            newOutputEvent = event;

          case GraphEventType.updateRatios:
            oldRatiosEvent ??= event;
            newRatiosEvent = event;

          case GraphEventType.geometryUpdate:
            oldGeometryEvent ??= event;
            newGeometryEvent = event;
        }
      }
    }

    return GraphEvent._(
      orderedEvents.first.graph,
      mutations,
      oldNodes: oldNodeEvent?.oldNodes,
      oldEdges: oldEdgeEvent?.oldEdges,
      oldInputs: oldInputEvent?.oldInputs,
      oldOutputs: oldOutputEvent?.oldOutputs,
      oldInputRatios: oldRatiosEvent?.oldInputRatios,
      oldOutputRatios: oldRatiosEvent?.oldOutputRatios,
      oldGeometry: oldGeometryEvent?.oldGeometry,
      newNodes: newNodeEvent?.newNodes,
      newEdges: newEdgeEvent?.newEdges,
      newInputs: newInputEvent?.newInputs,
      newOutputs: newOutputEvent?.newOutputs,
      newInputRatios: newRatiosEvent?.newInputRatios,
      newOutputRatios: newRatiosEvent?.newOutputRatios,
      newGeometry: newGeometryEvent?.newGeometry,
    );
  }

  GraphEvent._(
    this.graph,
    Iterable<GraphEventType> mutations, {
    this.oldNodes,
    this.oldEdges,
    this.oldInputs,
    this.oldOutputs,
    this.oldInputRatios,
    this.oldOutputRatios,
    this.oldGeometry,
    Iterable<ProdLineNode>? newNodes,
    Iterable<DirectedEdge>? newEdges,
    Iterable<InGameItem>? newInputs,
    Iterable<InGameItem>? newOutputs,
    ItemAmounts? newInputRatios,
    ItemAmounts? newOutputRatios,
    this.newGeometry,
  }) : mutations = Set.unmodifiable(mutations),
       newNodes = _unmodifiableOrNullList(newNodes),
       newEdges = _unmodifiableOrNullList(newEdges),
       newInputs = _unmodifiableOrNullSet(newInputs),
       newOutputs = _unmodifiableOrNullSet(newOutputs),
       newInputRatios = _unmodifiableOrNullMap(newInputRatios),
       newOutputRatios = _unmodifiableOrNullMap(newOutputRatios),
       isReversed = false,
       _original = null;

  GraphEvent._reverse(GraphEvent toReverse)
    : graph = toReverse.graph,
      mutations = toReverse.mutations,
      oldNodes = toReverse.newNodes,
      oldEdges = toReverse.newEdges,
      oldInputs = toReverse.newInputs,
      oldOutputs = toReverse.newOutputs,
      oldInputRatios = toReverse.oldInputRatios,
      oldOutputRatios = toReverse.oldOutputRatios,
      oldGeometry = toReverse.newGeometry,
      newNodes = toReverse.oldNodes,
      newEdges = toReverse.oldEdges,
      newInputs = toReverse.oldInputs,
      newOutputs = toReverse.oldOutputs,
      newInputRatios = toReverse.oldInputRatios,
      newOutputRatios = toReverse.oldOutputRatios,
      newGeometry = toReverse.oldGeometry,
      isReversed = true,
      _original = toReverse;
}

enum GraphEventType {
  geometryUpdate,
  updateNodes,
  updateEdges,
  updateInput,
  updateOutput,
  updateRatios,
}
