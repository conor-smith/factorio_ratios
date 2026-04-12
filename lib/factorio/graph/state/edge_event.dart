part of '../../graph.dart';

class EdgeEvent extends MutationEvent {
  final DirectedEdge edge;

  final Set<EdgeEventType> mutations;

  final double? oldAmount, newAmount;

  final LineType? oldLineType, newLineType;
  final Side? oldParentConnection,
      oldChildConnection,
      newParentConnection,
      newChildConnection;
  final List<Offset>? oldLines, newLines;

  final bool isReversed;
  final EdgeEvent? original;
  late final EdgeEvent reversed = original ?? EdgeEvent._reverse(this);

  EdgeEvent.addToGraph(DirectedEdge edge)
    : this._(edge, {EdgeEventType.addedToGraph});

  EdgeEvent.removeFromGraph(DirectedEdge edge)
    : this._(edge, {EdgeEventType.removedFromGraph});

  EdgeEvent.newAmount(DirectedEdge edge, double newAmount)
    : this._(
        edge,
        {EdgeEventType.newAmount},
        oldAmount: edge.amount,
        newAmount: newAmount,
      );

  EdgeEvent.clearAmount(DirectedEdge edge)
    : this._(edge, {EdgeEventType.newAmount}, oldAmount: edge.amount);

  EdgeEvent.updateLines(
    DirectedEdge edge,
    List<Offset> newLines,
    Side newParentConnectionSide,
    Side newChildConnectionSide,
  ) : this.updateLineType(
        edge,
        newLines,
        edge.lineType,
        newParentConnectionSide,
        newChildConnectionSide,
      );

  EdgeEvent.updateLineType(
    DirectedEdge edge,
    List<Offset> newLines,
    LineType newLineType,
    Side newParentConnectionSide,
    Side newChildConnectionSide,
  ) : this._(
        edge,
        {EdgeEventType.newLines},
        oldLines: edge.lines,
        oldLineType: edge.lineType,
        oldParentConnection: edge.parentConnection,
        oldChildConnection: edge.childConnection,
        newLines: newLines,
        newLineType: newLineType,
        newParentConnection: newParentConnectionSide,
        newChildConnection: newChildConnectionSide,
      );

  factory EdgeEvent.combine(List<EdgeEvent> orderedEvents) {
    Set<EdgeEventType> mutations = {};

    EdgeEvent? oldAmountEvent, newAmountEvent;
    double? oldAmount, newAmount;

    EdgeEvent? oldLinesEvent, newLinesEvent;
    Side? oldParentConnection,
        oldChildConnection,
        newParentConnection,
        newChildConnection;
    LineType? oldLineType, newLineType;
    List<Offset>? oldLines, newLines;

    for (var event in orderedEvents) {
      mutations.addAll(event.mutations);
      for (var mutation in event.mutations) {
        switch (mutation) {
          case EdgeEventType.newAmount:
            oldAmountEvent ??= event;
            newAmountEvent = event;

          case EdgeEventType.newLines:
            oldLinesEvent ??= event;
            newLinesEvent = event;

          case EdgeEventType.addedToGraph:
          case EdgeEventType.removedFromGraph:
            break;
        }
      }
    }

    if (mutations.containsAll(EdgeEventType.creationEvents)) {
      mutations.removeAll(EdgeEventType.creationEvents);
    }

    if (oldAmountEvent != null) {
      oldAmount = oldAmountEvent.oldAmount;
      newAmount = newAmountEvent!.newAmount;
    }

    if (oldLinesEvent != null) {
      oldParentConnection = oldLinesEvent.oldParentConnection;
      oldChildConnection = oldLinesEvent.oldChildConnection;
      oldLineType = oldLinesEvent.oldLineType;
      oldLines = oldLinesEvent.oldLines;
      newParentConnection = newLinesEvent!.newParentConnection;
      newChildConnection = newLinesEvent.newChildConnection;
      newLineType = newLinesEvent.newLineType;
      newLines = newLinesEvent.newLines;
    }

    return EdgeEvent._(
      orderedEvents.first.edge,
      mutations,
      oldAmount: oldAmount,
      oldLineType: oldLineType,
      oldParentConnection: oldParentConnection,
      oldChildConnection: oldChildConnection,
      oldLines: oldLines,
      newAmount: newAmount,
      newLineType: newLineType,
      newParentConnection: newParentConnection,
      newChildConnection: newChildConnection,
      newLines: newLines,
    );
  }

  EdgeEvent._(
    this.edge,
    Set<EdgeEventType> mutations, {
    this.oldAmount,
    this.oldLineType,
    this.oldParentConnection,
    this.oldChildConnection,
    this.oldLines, // This list should already be unmodifiable
    this.newAmount,
    this.newLineType,
    this.newParentConnection,
    this.newChildConnection,
    List<Offset>? newLines,
  }) : mutations = Set.unmodifiable(mutations),
       newLines = newLines != null ? List.unmodifiable(newLines) : null,
       isReversed = false,
       original = null;

  EdgeEvent._reverse(EdgeEvent toReverse)
    : edge = toReverse.edge,
      mutations = Set.unmodifiable(
        toReverse.mutations.map((eventType) => eventType.reverse),
      ),
      oldAmount = toReverse.newAmount,
      oldLineType = toReverse.newLineType,
      oldParentConnection = toReverse.newParentConnection,
      oldChildConnection = toReverse.newChildConnection,
      oldLines = toReverse.newLines,
      newAmount = toReverse.oldAmount,
      newLineType = toReverse.oldLineType,
      newParentConnection = toReverse.oldParentConnection,
      newChildConnection = toReverse.oldChildConnection,
      newLines = toReverse.oldLines,
      isReversed = true,
      original = toReverse;
}

enum GraphEventType {
  positionalNodesUpdate,
  updateNodes,
  updateEdges,
  updateInput,
  updateOutput,
}

enum NodeEventType {
  newPosition,
  newRequirements,
  newNodeType,
  newProductionLine,
  parentOfUpdate,
  childOfUpdate,
  addedToGraph,
  removedFromGraph;

  NodeEventType get reverse => switch (this) {
    newPosition => newPosition,
    newRequirements => newRequirements,
    newNodeType => newNodeType,
    newProductionLine => newProductionLine,
    parentOfUpdate => parentOfUpdate,
    childOfUpdate => childOfUpdate,
    addedToGraph => removedFromGraph,
    removedFromGraph => addedToGraph,
  };

  static const List<NodeEventType> creationEvents = [
    addedToGraph,
    removedFromGraph,
  ];
}

enum EdgeEventType {
  newAmount,
  newLines,
  addedToGraph,
  removedFromGraph;

  EdgeEventType get reverse => switch (this) {
    newAmount => newAmount,
    newLines => newLines,
    addedToGraph => removedFromGraph,
    removedFromGraph => addedToGraph,
  };

  static const List<EdgeEventType> creationEvents = [
    addedToGraph,
    removedFromGraph,
  ];
}
