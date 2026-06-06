part of 'state.dart';

class BasePlannerEvent extends MutationEvent {
  final Map<ProductionLineGraph, GraphEvent> graphEvents;
  final Map<ProdLineNode, NodeEvent> nodeEvents;
  final Map<DirectedEdge, EdgeEvent> edgeEvents;

  BasePlannerEvent({
    Map<ProductionLineGraph, GraphEvent> graphEvents = const {},
    Map<ProdLineNode, NodeEvent> nodeEvents = const {},
    Map<DirectedEdge, EdgeEvent> edgeEvents = const {},
  }) : graphEvents = Map.unmodifiable(graphEvents),
       nodeEvents = Map.unmodifiable(nodeEvents),
       edgeEvents = Map.unmodifiable(edgeEvents);
}
