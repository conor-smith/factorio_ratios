part of 'edge.dart';

abstract class EdgeState {
  double get amount;
  double get percentage;

  EdgeGeometryImpl get geometry;
}

class EdgeStateImpl implements EdgeState, ToJson {
  @override
  final double amount;
  @override
  final double percentage;

  @override
  final EdgeGeometryImpl geometry;

  EdgeStateImpl._initial({
    required this.amount,
    required this.percentage,
    required this.geometry,
  });

  EdgeStateImpl(
    Edge edge, {
    required this.amount,
    required this.percentage,
    required this.geometry,
  }) {
    if (percentage > 1.0 || percentage < 0.0) {
      throw EdgeException('Edge $edge had invalid percentage: $percentage');
    }

    if (amount < 0) {
      throw EdgeException('Edge $edge had invalid amount: $amount');
    }
  }

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}
