part of '../graph.dart';

class UpdateEvent {
  final Map<BaseGraph, GraphEvent> graphEvents;
  final Map<ProdLineNode, NodeEvent> nodeEvents;
  final Map<DirectedEdge, EdgeEvent> edgeEvents;

  UpdateEvent._({
    Map<BaseGraph, GraphEvent> graphEvents = const {},
    Map<ProdLineNode, NodeEvent> nodeEvents = const {},
    Map<DirectedEdge, EdgeEvent> edgeEvents = const {},
  }) : graphEvents = Map.unmodifiable(graphEvents),
       nodeEvents = Map.unmodifiable(nodeEvents),
       edgeEvents = Map.unmodifiable(edgeEvents);

  factory UpdateEvent._combine(List<UpdateEvent> orderedEvents) {
    Map<BaseGraph, List<GraphEvent>> graphEventList = {};
    Map<ProdLineNode, List<NodeEvent>> nodeEventList = {};
    Map<DirectedEdge, List<EdgeEvent>> edgeEventList = {};

    for (var event in orderedEvents) {
      event.graphEvents.forEach(
        (graph, eventList) => graphEventList.update(
          graph,
          (oldEvents) => oldEvents..add(eventList),
          ifAbsent: () => [eventList],
        ),
      );

      event.nodeEvents.forEach(
        (node, eventList) => nodeEventList.update(
          node,
          (oldEvents) => oldEvents..add(eventList),
          ifAbsent: () => [eventList],
        ),
      );

      event.edgeEvents.forEach(
        (edge, eventList) => edgeEventList.update(
          edge,
          (oldEvents) => oldEvents..add(eventList),
          ifAbsent: () => [eventList],
        ),
      );
    }

    return UpdateEvent._(
      graphEvents: graphEventList.map(
        (graph, eventList) => MapEntry(graph, GraphEvent._combine(eventList)),
      ),
      nodeEvents: nodeEventList.map(
        (node, eventList) => MapEntry(node, NodeEvent._combine(eventList)),
      ),
      edgeEvents: edgeEventList.map(
        (edge, eventList) => MapEntry(edge, EdgeEvent._combine(eventList)),
      ),
    );
  }
}

class GraphEvent {
  final bool positionUpdate;
  final Offset? oldTopLeft, newTopLeft, oldBottomRight, newBottomRight;

  final bool nodesUpdate;
  final List<ProdLineNode>? newNodes;
  final List<ProdLineNode>? removedNodes;

  final bool edgesUpdate;
  final List<DirectedEdge>? newEdges;
  final List<DirectedEdge>? removedEdges;

  // TODO - proper equality checks
  GraphEvent._({
    this.oldTopLeft,
    this.oldBottomRight,
    this.newTopLeft,
    this.newBottomRight,
    List<ProdLineNode>? newNodes,
    List<ProdLineNode>? removedNodes,
    List<DirectedEdge>? newEdges,
    List<DirectedEdge>? removedEdges,
  }) : newNodes = newNodes != null ? List.unmodifiable(newNodes) : null,
       removedNodes = removedNodes != null
           ? List.unmodifiable(removedNodes)
           : null,
       newEdges = newEdges != null ? List.unmodifiable(newEdges) : null,
       removedEdges = removedEdges != null
           ? List.unmodifiable(removedEdges)
           : null,
       positionUpdate =
           oldTopLeft != newTopLeft || oldBottomRight != newBottomRight,
       nodesUpdate = newNodes != null || removedNodes != null,
       edgesUpdate = newEdges != null || removedEdges != null;

  factory GraphEvent._combine(List<GraphEvent> orderedEvents) {
    Offset? oldTopLeft, newTopLeft, oldBottomRight, newBottomRight;
    List<ProdLineNode> allNewNodes = [];
    List<ProdLineNode> allRemovedNodes = [];
    List<DirectedEdge> allNewEdges = [];
    List<DirectedEdge> allRemovedEdges = [];

    for (var event in orderedEvents) {
      if (event.positionUpdate) {
        oldTopLeft ??= event.oldTopLeft;
        oldBottomRight ??= event.oldBottomRight;
        newTopLeft = event.newTopLeft;
        newBottomRight = event.newBottomRight;
      }

      if (event.nodesUpdate) {
        allNewNodes.addAll(event.newNodes ?? const []);
        allRemovedNodes.addAll(event.removedNodes ?? const []);
      }

      if (event.edgesUpdate) {
        allNewEdges.addAll(event.newEdges ?? const []);
        allRemovedEdges.addAll(event.newEdges ?? const []);
      }
    }

    return GraphEvent._(
      oldTopLeft: oldTopLeft,
      newTopLeft: newTopLeft,
      oldBottomRight: oldBottomRight,
      newBottomRight: newBottomRight,
      newNodes: List.unmodifiable(allNewNodes),
      removedNodes: List.unmodifiable(allRemovedNodes),
      newEdges: List.unmodifiable(allNewEdges),
      removedEdges: List.unmodifiable(allRemovedEdges),
    );
  }
}

class NodeEvent {
  final bool positionUpdate;
  final Offset? oldTopLeft, newTopLeft, oldBottomRight, newBottomRight;

  final bool requirementUpdate;
  final ItemIo? oldRequirement, newRequirement;

  final bool typeUpdate;
  final NodeType? oldType, newType;

  final bool productionLineUpdate;
  final ProductionLine? oldProductionLine, newProductionLine;

  // TODO - Proper equality checks
  const NodeEvent._({
    this.oldTopLeft,
    this.newTopLeft,
    this.oldBottomRight,
    this.newBottomRight,
    this.oldRequirement,
    this.newRequirement,
    this.oldType,
    this.newType,
    this.oldProductionLine,
    this.newProductionLine,
  }) : positionUpdate =
           oldTopLeft != newTopLeft || oldBottomRight != newBottomRight,
       requirementUpdate = oldRequirement != newRequirement,
       typeUpdate = oldType != newType,
       productionLineUpdate = oldProductionLine != newProductionLine;

  factory NodeEvent._combine(List<NodeEvent> orderedEvents) {
    Offset? oldTopLeft, newTopLeft, oldBottomRight, newBottomRight;

    bool requirementUpdate = false;
    ItemIo? oldRequirement, newRequirement;

    NodeType? oldType, newType;
    ProductionLine? oldProductionLine, newProductionLine;

    for (var event in orderedEvents) {
      if (event.positionUpdate) {
        oldTopLeft ??= event.oldTopLeft;
        oldBottomRight ??= event.oldBottomRight;
        newTopLeft = event.newTopLeft;
        newBottomRight = event.newBottomRight;
      }

      if (event.requirementUpdate) {
        // These values can actually be null, so we need to be more careful
        if (!requirementUpdate) {
          requirementUpdate = true;
          oldRequirement = event.oldRequirement;
        }
        newRequirement = event.newRequirement;
      }

      oldType ??= event.oldType;
      newType = event.newType;

      oldProductionLine ??= event.oldProductionLine;
      newProductionLine = event.newProductionLine;
    }

    return NodeEvent._(
      oldTopLeft: oldTopLeft,
      newTopLeft: newTopLeft,
      oldBottomRight: oldBottomRight,
      newBottomRight: newBottomRight,
      oldRequirement: oldRequirement,
      newRequirement: newRequirement,
      oldType: oldType,
      newType: newType,
      oldProductionLine: oldProductionLine,
      newProductionLine: newProductionLine,
    );
  }
}

class EdgeEvent {
  final bool lineTypeUpdate;
  final LineType? oldLineType, newLineType;

  final bool amountUpdate;
  final double? oldAmount, newAmount;

  final bool parentConnectionUpdate;
  final Side? oldParentConnection, newParentConnection;

  final bool childConnectionUpdate;
  final Side? oldChildConnection, newChildConnection;

  final bool linesUpdate;
  final List<Offset>? oldLines, newLines;

  // TODO - proper equality checks
  EdgeEvent._({
    this.oldLineType,
    this.newLineType,
    this.oldAmount,
    this.newAmount,
    this.oldParentConnection,
    this.newParentConnection,
    this.oldChildConnection,
    this.newChildConnection,
    List<Offset>? oldLines,
    List<Offset>? newLines,
  }) : oldLines = oldLines != null ? List.unmodifiable(oldLines) : null,
       newLines = newLines != null ? List.unmodifiable(newLines) : null,
       lineTypeUpdate = oldLineType != newLineType,
       amountUpdate = oldAmount != newAmount,
       parentConnectionUpdate = oldParentConnection != newParentConnection,
       childConnectionUpdate = oldChildConnection != newChildConnection,
       linesUpdate = oldLines != newLines;

  factory EdgeEvent._combine(List<EdgeEvent> orderedEvents) {
    LineType? oldLineType, newLineType;

    bool amountUpdate = false;
    double? oldAmount, newAmount;

    Side? oldParentConnection,
        newParentConnection,
        oldChildConnection,
        newChildConnection;
    List<Offset>? oldLines, newLines;

    for (var event in orderedEvents) {
      if (event.lineTypeUpdate) {
        oldLineType ??= event.oldLineType;
        newLineType = event.newLineType;
      }

      if (event.amountUpdate) {
        // These values can actually be null, so we need to be more careful
        if (!amountUpdate) {
          amountUpdate = true;
          oldAmount = event.oldAmount;
        }
        newAmount = event.newAmount;
      }

      if (event.parentConnectionUpdate) {
        oldParentConnection ??= event.oldParentConnection;
        newParentConnection = event.newParentConnection;
      }

      if (event.childConnectionUpdate) {
        oldChildConnection ??= event.oldChildConnection;
        newChildConnection = event.newChildConnection;
      }

      if (event.linesUpdate) {
        oldLines ??= event.oldLines;
        newLines = event.newLines;
      }
    }

    return EdgeEvent._(
      oldLineType: oldLineType,
      newLineType: newLineType,
      oldAmount: oldAmount,
      newAmount: newAmount,
      oldParentConnection: oldParentConnection,
      newParentConnection: newParentConnection,
      oldChildConnection: oldChildConnection,
      newChildConnection: newChildConnection,
      oldLines: oldLines,
      newLines: newLines,
    );
  }
}
