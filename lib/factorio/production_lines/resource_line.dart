part of '../production_line.dart';

// Represents either an infinite producer or consumer of items
class Resource extends ProductionLine {
  final ItemData itemData;
  final Map<ItemData, double> _ioPerSecond = {};
  @override
  late final Map<ItemData, double> ioPerSecond = UnmodifiableMapView(_ioPerSecond);

  Resource(this.itemData, double amount) {
    _ioPerSecond[itemData] = amount;
  }

  @override
  void update(Map<ItemData, double> requirements) {
    if(requirements.length != 1 || !requirements.containsKey(itemData)) {
      throw FactorioException('This resource only inputs / outputs item ${itemData.item.name}');
    } else {
      _ioPerSecond.addAll(requirements);
    }
  }

  @override
  String get name => 'Resource: ${itemData.item.name}';
}