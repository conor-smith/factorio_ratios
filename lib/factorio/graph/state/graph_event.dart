part of 'state.dart';

/// Represents a single, reversible
class GraphEvent extends MutationEvent {
  final PlanetBase graph;

  final Set<GraphEventType> mutations;

  final GraphGeometry? oldGeometry, newGeometry;
  final Set<ProdLineNode> newNodes, removedNodes;
  final Set<DirectedEdge> newEdges, removedEdges;
  final Set<InGameItem> newInputs, newOutputs, removedInputs, removedOutputs;

  final GraphEvent? original;
  @override
  final bool isReversed;
  @override
  late final GraphEvent reversed = original ?? GraphEvent._reverse(this);

  GraphEvent.newNode(PlanetBase graph, ProdLineNode newNode)
    : this._(graph, {GraphEventType.updateNodes}, newNodes: {newNode});

  GraphEvent.removeNode(PlanetBase graph, ProdLineNode removedNode)
    : this._(graph, {GraphEventType.updateNodes}, removedNodes: {removedNode});

  GraphEvent.newEdge(PlanetBase graph, DirectedEdge newEdge)
    : this._(graph, {GraphEventType.updateEdges}, newEdges: {newEdge});

  GraphEvent.removeEdge(PlanetBase graph, DirectedEdge removedEdge)
    : this._(graph, {GraphEventType.updateEdges}, removedEdges: {removedEdge});

  GraphEvent.newInput(PlanetBase graph, InGameItem newInput)
    : this._(graph, {GraphEventType.updateInput}, newInputs: {newInput});

  GraphEvent.removeInput(PlanetBase graph, InGameItem removedInput)
    : this._(
        graph,
        {GraphEventType.updateInput},
        removedInputs: {removedInput},
      );

  GraphEvent.newOutput(PlanetBase graph, InGameItem newOutput)
    : this._(graph, {GraphEventType.updateOutput}, newOutputs: {newOutput});

  GraphEvent.removeOutput(PlanetBase graph, InGameItem removedOutput)
    : this._(
        graph,
        {GraphEventType.updateOutput},
        removedOutputs: {removedOutput},
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

    Set<ProdLineNode> newNodes = {};
    Set<ProdLineNode> removedNodes = {};
    Set<DirectedEdge> newEdges = {};
    Set<DirectedEdge> removedEdges = {};

    Set<InGameItem> newInputs = {};
    Set<InGameItem> removedInputs = {};
    Set<InGameItem> newOutputs = {};
    Set<InGameItem> removedOutputs = {};

    GraphEvent? oldGeometryEvent, newGeometryEvent;
    GraphGeometry? oldGeometry, newGeometry;

    for (var event in orderedEvents) {
      mutations.addAll(event.mutations);
      for (var mutation in event.mutations) {
        switch (mutation) {
          case GraphEventType.geometryUpdate:
            oldGeometryEvent ??= event;
            newGeometryEvent = event;

          case GraphEventType.updateNodes:
            newNodes.addAll(event.newNodes);
            removedNodes.addAll(event.removedNodes);

          case GraphEventType.updateEdges:
            newEdges.addAll(event.newEdges);
            removedEdges.addAll(event.removedEdges);

          case GraphEventType.updateInput:
            newInputs.addAll(event.newInputs);
            removedInputs.addAll(event.removedInputs);

          case GraphEventType.updateOutput:
            newOutputs.addAll(event.newOutputs);
            removedOutputs.addAll(event.removedOutputs);
        }
      }
    }

    if (oldGeometryEvent != null) {
      oldGeometry = oldGeometryEvent.oldGeometry;
      newGeometry = newGeometryEvent!.newGeometry;
    }

    _removedWhereBothContain(newNodes, removedNodes);
    _removedWhereBothContain(newEdges, removedEdges);
    _removedWhereBothContain(newInputs, removedInputs);
    _removedWhereBothContain(newOutputs, removedOutputs);

    return GraphEvent._(
      orderedEvents.first.graph,
      mutations,
      removedNodes: removedNodes,
      removedEdges: removedEdges,
      removedInputs: removedInputs,
      removedOutputs: removedOutputs,
      oldGeometry: oldGeometry,
      newNodes: newNodes,
      newEdges: newEdges,
      newInputs: newInputs,
      newOutputs: newOutputs,
      newGeometry: newGeometry,
    );
  }

  GraphEvent._(
    this.graph,
    Set<GraphEventType> mutations, {
    this.oldGeometry,
    Set<ProdLineNode> removedNodes = const {},
    Set<DirectedEdge> removedEdges = const {},
    Set<InGameItem> removedInputs = const {},
    Set<InGameItem> removedOutputs = const {},
    this.newGeometry,
    Set<ProdLineNode> newNodes = const {},
    Set<DirectedEdge> newEdges = const {},
    Set<InGameItem> newInputs = const {},
    Set<InGameItem> newOutputs = const {},
  }) : mutations = Set.unmodifiable(mutations),
       removedNodes = Set.unmodifiable(removedNodes),
       removedEdges = Set.unmodifiable(removedEdges),
       removedInputs = Set.unmodifiable(removedInputs),
       removedOutputs = Set.unmodifiable(removedOutputs),
       newNodes = Set.unmodifiable(newNodes),
       newEdges = Set.unmodifiable(newEdges),
       newInputs = Set.unmodifiable(newInputs),
       newOutputs = Set.unmodifiable(newOutputs),
       isReversed = false,
       original = null;

  GraphEvent._reverse(GraphEvent toReverse)
    : graph = toReverse.graph,
      mutations = toReverse.mutations,
      oldGeometry = toReverse.newGeometry,
      removedNodes = toReverse.newNodes,
      removedEdges = toReverse.newEdges,
      removedInputs = toReverse.newInputs,
      removedOutputs = toReverse.newOutputs,
      newGeometry = toReverse.oldGeometry,
      newNodes = toReverse.removedNodes,
      newEdges = toReverse.removedEdges,
      newInputs = toReverse.removedInputs,
      newOutputs = toReverse.removedOutputs,
      isReversed = true,
      original = toReverse;
}

enum GraphEventType {
  geometryUpdate,
  updateNodes,
  updateEdges,
  updateInput,
  updateOutput,
}
