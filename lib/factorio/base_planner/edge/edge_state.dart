part of 'edge.dart';

abstract class EdgeState {
  double get amount;

  double get percentage;
  int get parentPriority;
  int get childPriority;

  EdgeGeometryImpl get geometry;
}

class EdgeStateImpl implements EdgeState, ToJson {
  static const uninitialised = EdgeStateImpl._uninitialised();

  @override
  final double amount;
  @override
  final double percentage;
  @override
  final int parentPriority;
  @override
  final int childPriority;

  @override
  final EdgeGeometryImpl geometry;

  EdgeStateImpl(
    Edge edge, {
    required this.amount,
    required this.percentage,
    required this.geometry,
    required this.parentPriority,
    required this.childPriority,
  }) {
    if (edge.edgeType == EdgeType.requestExcess) {
      if (percentage != 0) {
        throw const EdgeException('requestExcess edge cannot use percentages');
      }
    } else {
      if (edge.parentPriority > 0 || edge.childPriority > 0) {
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
      percentage = 0,
      parentPriority = 0,
      childPriority = 0,
      geometry = EdgeGeometryImpl.uninitialised;

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}
