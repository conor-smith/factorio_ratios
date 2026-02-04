import 'dart:collection';

import 'package:factorio_ratios/factorio/factorio.dart';
import 'package:factorio_ratios/factorio/models.dart';

part 'production_lines/infinite_line.dart';
part 'production_lines/item_metadata.dart';
part 'production_lines/single_recipe.dart';

enum ProductionLineType { noRecipe, singleRecipe, multiRecipe }

abstract class ProductionLine implements ConditionalUpdateable {
  ProductionLineType get type;
  Map<ItemData, double> get ioPerSecond;
}

class BasicUpdateable implements ConditionalUpdateable {
  final Map<ItemData, double> _existingConditions;
  @override
  late final Map<ItemData, double> existingConditions = UnmodifiableMapView(
    _existingConditions,
  );

  @override
  Map<ItemData, double> conditionsToAddAndUpdate = {};
  @override
  Set<ItemData> conditionsToRemove = {};

  BasicUpdateable([Map<ItemData, double>? existingConditions])
    : _existingConditions = existingConditions ?? {};

  @override
  bool get awaitingUpdate =>
      conditionsToAddAndUpdate.isNotEmpty || conditionsToRemove.isNotEmpty;

  @override
  void update() {
    for (var key in conditionsToRemove) {
      _existingConditions.remove(key);
    }

    _existingConditions.addAll(conditionsToAddAndUpdate);

    conditionsToRemove = {};
    conditionsToAddAndUpdate = {};
  }
}

abstract class ConditionalUpdateable implements Updateable {
  Map<ItemData, double> get existingConditions;
  Map<ItemData, double> get conditionsToAddAndUpdate;
  Set<ItemData> get conditionsToRemove;
  set conditionsToAddAndUpdate(Map<ItemData, double> conditions);
  set conditionsToRemove(Set<ItemData> conditions);
}

abstract class Updateable {
  bool get awaitingUpdate;

  void update();
}
