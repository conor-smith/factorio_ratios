part of '../production_line.dart';

// This production line only produces or consumes a single item at no cost
class InfiniteLine extends BasicUpdateable implements ProductionLine {
  final ItemData _item;
  double _amount;

  InfiniteLine._(this._item, [this._amount = 0]);

  @override
  bool get awaitingUpdate =>
      conditionsToAddAndUpdate.isNotEmpty || conditionsToRemove.isNotEmpty;

  @override
  Map<ItemData, double> get existingConditions =>
      Map.unmodifiable({_item: _amount});

  @override
  Map<ItemData, double> get ioPerSecond => existingConditions;

  @override
  void update() {
    if (conditionsToAddAndUpdate.length > 1 ||
        (conditionsToAddAndUpdate.length == 1 &&
            !conditionsToAddAndUpdate.containsKey(_item)) ||
        conditionsToRemove.contains(_item)) {
      throw FactorioException(
        'Cannot add or remove items from noRecipe production line for item "${_item.item.name}"',
      );
    }

    _amount = conditionsToAddAndUpdate[_item] ?? _amount;

    conditionsToAddAndUpdate = {};
    conditionsToRemove = {};
  }
}
