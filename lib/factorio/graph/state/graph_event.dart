part of 'state.dart';

class GraphEvent extends MutationEvent {
  final PlanetBase graph;

  final Set<GraphEventType> mutations;

  final List<ProdLineNode>? oldNodes, newNodes;
  final List<DirectedEdge>? oldEdges, newEdges;
  final GraphGeometry? oldGeometry, newGeometry;
  final Set<InGameItem>? oldInputs, oldOutputs, newInputs, newOutputs;
  final ItemIo? oldInputRatios,
      oldOutputRatios,
      newInputRatios,
      newOutputRatios;

  final GraphEvent? original;
  @override
  final bool isReversed;
  @override
  late final GraphEvent reversed = original ?? GraphEvent._reverse(this);

  List<ProdLineNode> get addedNodes => newNodes == null
      ? const []
      : newNodes!.where((node) => !oldNodes!.contains(node)).toList();
  List<ProdLineNode> get removedNodes => oldNodes == null
      ? const []
      : oldNodes!.where((node) => !newNodes!.contains(node)).toList();

  List<DirectedEdge> get addedEdges => newEdges == null
      ? const []
      : newEdges!.where((edge) => !oldEdges!.contains(edge)).toList();
  List<DirectedEdge> get removedEdges => oldEdges == null
      ? const []
      : oldEdges!.where((edge) => !newEdges!.contains(edge)).toList();

  GraphEvent.newNode(PlanetBase graph, ProdLineNode newNode)
    : this._(
        graph,
        const {GraphEventType.updateNodes},
        newNodes: [...graph.nodes, newNode],
      );

  GraphEvent.removeNode(PlanetBase graph, ProdLineNode removedNode)
    : this._(graph, const {
        GraphEventType.updateNodes,
      }, newNodes: List.from(graph.nodes)..remove(removedNode));

  GraphEvent.newEdge(PlanetBase graph, DirectedEdge newEdge)
    : this._(
        graph,
        const {GraphEventType.updateEdges},
        newEdges: [...graph.edges, newEdge],
      );

  GraphEvent.removeEdge(PlanetBase graph, DirectedEdge removedEdge)
    : this._(graph, const {
        GraphEventType.updateEdges,
      }, newEdges: List.from(graph.edges)..remove(removedEdge));

  GraphEvent.newInput(PlanetBase graph, InGameItem newInput)
    : this._(
        graph,
        const {GraphEventType.updateInput},
        newInputs: [...graph.inputItems, newInput],
      );

  GraphEvent.removeInput(PlanetBase graph, InGameItem removedInput)
    : this._(graph, const {
        GraphEventType.updateInput,
      }, newInputs: List.from(graph.inputItems)..remove(removedInput));

  GraphEvent.newOutput(PlanetBase graph, InGameItem newOutput)
    : this._(
        graph,
        const {GraphEventType.updateOutput},
        newOutputs: [...graph.outputItems, newOutput],
      );

  GraphEvent.removeOutput(PlanetBase graph, InGameItem removedOutput)
    : this._(graph, const {
        GraphEventType.updateOutput,
      }, newOutputs: List.from(graph.outputItems)..remove(removedOutput));

  GraphEvent.newIoRatios(
    PlanetBase graph, {
    required ItemIo newInputRatios,
    required ItemIo newOutputRatios,
  }) : this._(
         graph,
         {GraphEventType.updateRatios},
         oldInputRatios: graph.inputRatios,
         oldOutputRatios: graph.outputRatios,
         newInputRatios: newInputRatios,
         newOutputRatios: newOutputRatios,
       );

  GraphEvent.clearIoRatios(PlanetBase graph)
    : this._(
        graph,
        {GraphEventType.updateRatios},
        oldInputRatios: graph.inputRatios,
        oldOutputRatios: graph.outputRatios,
      );

  GraphEvent.updateGeometry(PlanetBase graph, GraphGeometry newGeometry)
    : this._(
        graph,
        {GraphEventType.geometryUpdate},
        oldGeometry: graph.geometry,
        newGeometry: newGeometry,
      );

  GraphEvent.clearGeometry(PlanetBase graph)
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
    ItemIo? newInputRatios,
    ItemIo? newOutputRatios,
    this.newGeometry,
  }) : mutations = Set.unmodifiable(mutations),
       newNodes = _unmodifiableOrNullList(newNodes),
       newEdges = _unmodifiableOrNullList(newEdges),
       newInputs = _unmodifiableOrNullSet(newInputs),
       newOutputs = _unmodifiableOrNullSet(newOutputs),
       newInputRatios = _unmodifiableOrNullMap(newInputRatios),
       newOutputRatios = _unmodifiableOrNullMap(newOutputRatios),
       isReversed = false,
       original = null;

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
      original = toReverse;
}

enum GraphEventType {
  geometryUpdate,
  updateNodes,
  updateEdges,
  updateInput,
  updateOutput,
  updateRatios,
}
