part of 'edge.dart';

abstract class EdgeState {
  double get amount;

  double get requestedAmount;

  double get percentage;
  int get priority;

  EdgeGeometryImpl get geometry;
}

class EdgeStateImpl implements EdgeState, ToJson {
  static const uninitialised = EdgeStateImpl._uninitialised();

  @override
  final double amount;
  @override
  final double requestedAmount;
  @override
  final double percentage;
  @override
  final int priority;

  @override
  final EdgeGeometryImpl geometry;

  EdgeStateImpl(
    Edge edge, {
    required this.amount,
    required this.requestedAmount,
    required this.percentage,
    required this.geometry,
    required this.priority,
  }) {
    if (edge.edgeType.usesPriority) {
      if (percentage != 0) {
        throw EdgeException(
          'Edge of type ${edge.edgeType} cannot use percentages',
        );
      } else if (priority < 1) {
        throw EdgeException(
          'Edge of type ${edge.edgeType} has invalid priority $priority',
        );
      }
    } else {
      if (priority != 0) {
        throw EdgeException(
          'Edge of type ${edge.edgeType} cannot use priorities',
        );
      } else if (percentage > 1.0 || percentage < 0.0) {
        throw EdgeException(
          'Edge of type ${edge.edgeType} had invalid percentage: $percentage',
        );
      }
    }

    if (amount < 0) {
      throw EdgeException('Edge $edge had invalid amount: $amount');
    }
  }

  const EdgeStateImpl._uninitialised()
    : amount = 0,
      requestedAmount = 0,
      percentage = 0,
      priority = 0,
      geometry = EdgeGeometryImpl.uninitialised;

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}
