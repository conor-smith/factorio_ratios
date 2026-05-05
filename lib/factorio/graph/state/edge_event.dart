part of 'state.dart';

class EdgeEvent extends MutationEvent {
  final DirectedEdge edge;

  final Set<EdgeEventType> mutations;

  final double? oldAmount, newAmount;

  final EdgeGeometry? oldGeometry, newGeometry;

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

  EdgeEvent.updateGeometry(DirectedEdge edge, EdgeGeometry newGeometry)
    : this._(
        edge,
        {EdgeEventType.newGeometry},
        oldGeometry: edge.geometry,
        newGeometry: newGeometry,
      );

  EdgeEvent.tempGeometry(DirectedEdge edge, EdgeGeometry tempGeometry)
    : this._(edge, {EdgeEventType.tempGeometry}, newGeometry: tempGeometry);

  EdgeEvent.clearAmount(DirectedEdge edge)
    : this._(edge, {EdgeEventType.newAmount}, oldAmount: edge.amount);

  factory EdgeEvent.combine(List<EdgeEvent> orderedEvents) {
    Set<EdgeEventType> mutations = {};

    EdgeEvent? oldAmountEvent, newAmountEvent;

    EdgeEvent? oldGeometryEvent, newGeometryEvent;

    for (var event in orderedEvents) {
      mutations.addAll(event.mutations);
      for (var mutation in event.mutations) {
        switch (mutation) {
          case EdgeEventType.newAmount:
            oldAmountEvent ??= event;
            newAmountEvent = event;

          case EdgeEventType.newGeometry:
            oldGeometryEvent ??= event;
            newGeometryEvent = event;

          case EdgeEventType.addedToGraph:
          case EdgeEventType.removedFromGraph:
            break;

          case EdgeEventType.tempGeometry:
            throw const GraphException(
              'Cannot combine edge temp geometry event',
            );
        }
      }
    }

    if (mutations.containsAll(EdgeEventType.creationEvents)) {
      mutations.removeAll(EdgeEventType.creationEvents);
    }

    return EdgeEvent._(
      orderedEvents.first.edge,
      mutations,
      oldAmount: oldAmountEvent?.oldAmount,
      oldGeometry: oldGeometryEvent?.oldGeometry,
      newAmount: newAmountEvent?.newAmount,
      newGeometry: newGeometryEvent?.newGeometry,
    );
  }

  EdgeEvent._(
    this.edge,
    Set<EdgeEventType> mutations, {
    this.oldAmount,
    this.oldGeometry,
    this.newAmount,
    this.newGeometry,
  }) : mutations = Set.unmodifiable(mutations),
       isReversed = false,
       original = null;

  EdgeEvent._reverse(EdgeEvent toReverse)
    : edge = toReverse.edge,
      mutations = Set.unmodifiable(
        toReverse.mutations.map((eventType) => eventType.reverse),
      ),
      oldAmount = toReverse.newAmount,
      oldGeometry = toReverse.newGeometry,
      newAmount = toReverse.oldAmount,
      newGeometry = toReverse.oldGeometry,
      isReversed = true,
      original = toReverse;
}

enum EdgeEventType {
  newAmount,
  newGeometry,
  tempGeometry,
  addedToGraph,
  removedFromGraph;

  EdgeEventType get reverse => switch (this) {
    newAmount => newAmount,
    newGeometry => newGeometry,
    tempGeometry => tempGeometry,
    addedToGraph => removedFromGraph,
    removedFromGraph => addedToGraph,
  };

  static const List<EdgeEventType> creationEvents = [
    addedToGraph,
    removedFromGraph,
  ];
}
