import 'dart:collection';

import 'package:factorio_ratios/factorio/factorio.dart';
import 'package:factorio_ratios/factorio/models.dart';
import 'package:flutter/foundation.dart';

part 'production_lines/dynamic_models.dart';
part 'production_lines/magic_line.dart';
part 'production_lines/single_recipe.dart';

abstract class ProductionLine {
  @mustCallSuper
  void update(Map<ItemData, double> requirements) {
    Set<ItemData> inputs = allInputs;
    Set<ItemData> outputs = allOutputs;

    requirements.forEach((itemData, amount) {
      if (amount > 0 && !outputs.contains(itemData)) {
        throw FactorioException(
          '"$itemData" is not an output for this production line',
        );
      } else if (amount < 0 && !inputs.contains(itemData)) {
        throw FactorioException(
          '"$itemData" is not an output for this production line',
        );
      } else if (amount == 0) {
        throw FactorioException(
          '0 is an invalid value for requirement "$itemData"',
        );
      }
    });

    var allIo = {...inputs, ...outputs};
    for (var io in allIo) {
      if (!requirements.containsKey(io)) {
        throw FactorioException('Input/output amount for "$io" not specified');
      }
    }
  }

  // Used for determining connections in graphs
  Set<ItemData> get allOutputs;
  Set<ItemData> get allInputs;

  Map<ItemData, double> get totalIoPerSecond;
}
