part of '../../graph.dart';

class EdgeEvent extends MutationEvent {
  final DirectedEdge edge;

  final Set<EdgeEventType> mutations;

  final double? oldAmount, newAmount;

  final EdgeCartesianData? oldCartesianData, newCartesianData;

  final EdgeEvent? original;
  @override
  final bool isReversed;
  @override
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

  EdgeEvent.newCartesianData(
    DirectedEdge edge,
    EdgeCartesianData newCartesianData,
  ) : this._(
        edge,
        {EdgeEventType.newCartesianData},
        oldCartesianData: edge.cartesianData,
        newCartesianData: newCartesianData,
      );

  EdgeEvent.tempCartesianData(
    DirectedEdge edge,
    EdgeCartesianData tempCartesianData,
  ) : this._(edge, {
        EdgeEventType.tempCartesianData,
      }, newCartesianData: tempCartesianData);

  EdgeEvent.clearAmount(DirectedEdge edge)
    : this._(edge, {EdgeEventType.newAmount}, oldAmount: edge.amount);

  factory EdgeEvent.combine(List<EdgeEvent> orderedEvents) {
    Set<EdgeEventType> mutations = {};

    EdgeEvent? oldAmountEvent, newAmountEvent;
    double? oldAmount, newAmount;

    EdgeEvent? oldCartesianEvent, newCartesianEvent;
    EdgeCartesianData? oldCartesianData, newCartesianData;

    for (var event in orderedEvents) {
      mutations.addAll(event.mutations);
      for (var mutation in event.mutations) {
        switch (mutation) {
          case EdgeEventType.newAmount:
            oldAmountEvent ??= event;
            newAmountEvent = event;

          case EdgeEventType.newCartesianData:
            oldCartesianEvent ??= event;
            newCartesianEvent = event;

          case EdgeEventType.addedToGraph:
          case EdgeEventType.removedFromGraph:
            break;

          case EdgeEventType.tempCartesianData:
            throw const GraphException(
              'Cannot combine edge temp position event',
            );
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

    if (oldCartesianEvent != null) {
      oldCartesianData = oldCartesianEvent.oldCartesianData;
      newCartesianData = newCartesianEvent!.newCartesianData;
    }

    return EdgeEvent._(
      orderedEvents.first.edge,
      mutations,
      oldAmount: oldAmount,
      oldCartesianData: oldCartesianData,
      newAmount: newAmount,
      newCartesianData: newCartesianData,
    );
  }

  EdgeEvent._(
    this.edge,
    Set<EdgeEventType> mutations, {
    this.oldAmount,
    this.oldCartesianData,
    this.newAmount,
    this.newCartesianData,
  }) : mutations = Set.unmodifiable(mutations),
       isReversed = false,
       original = null;

  EdgeEvent._reverse(EdgeEvent toReverse)
    : edge = toReverse.edge,
      mutations = Set.unmodifiable(
        toReverse.mutations.map((eventType) => eventType.reverse),
      ),
      oldAmount = toReverse.newAmount,
      oldCartesianData = toReverse.newCartesianData,
      newAmount = toReverse.oldAmount,
      newCartesianData = toReverse.oldCartesianData,
      isReversed = true,
      original = toReverse;
}

enum EdgeEventType {
  newAmount,
  newCartesianData,
  tempCartesianData,
  addedToGraph,
  removedFromGraph;

  EdgeEventType get reverse => switch (this) {
    newAmount => newAmount,
    newCartesianData => newCartesianData,
    tempCartesianData => tempCartesianData,
    addedToGraph => removedFromGraph,
    removedFromGraph => addedToGraph,
  };

  static const List<EdgeEventType> creationEvents = [
    addedToGraph,
    removedFromGraph,
  ];
}
