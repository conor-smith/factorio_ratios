import 'dart:collection';

import 'package:factorio_ratios/factorio/factorio.dart';
import 'package:factorio_ratios/factorio/models.dart';
import 'package:flutter/foundation.dart';

part 'production_lines/dynamic_models.dart';
part 'production_lines/magic_line.dart';
part 'production_lines/single_recipe.dart';

// TODO - Use Typedef for Map<ItemData, double>

/*
 * Inputs and outputs must be known before IO is calculated
 * 
 * Initially requirements and IO will be empty maps
 * These two maps will only be populated upon a call to .update()
 * IO and requirements can be reset back to an empty map by calling .reset()
 */
abstract class ProductionLine {
  @mustCallSuper
  void update(Map<ItemData, double> newRequirements) {
    Set<ItemData> inputs = allInputs;
    Set<ItemData> outputs = allOutputs;

    newRequirements.forEach((itemData, amount) {
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
  }

  void reset();

  // Used for determining connections in graphs
  Set<ItemData> get allOutputs;
  Set<ItemData> get allInputs;

  // If false, allInputs and allOutputs are immutable
  bool get immutableIo;

  Map<ItemData, double> get requirements;
  Map<ItemData, double> get totalIoPerSecond;
}
