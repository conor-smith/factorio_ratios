import 'package:factorio_ratios/factorio/factorio.dart';
import 'package:factorio_ratios/factorio/models/models.dart';
import 'package:factorio_ratios/json/json.dart';
import 'package:factorio_ratios/utility/collections.dart';

part 'display_data.dart';
part 'in_game_item.dart';
part 'in_game_recipe.dart';
part 'in_game_machine.dart';

typedef ItemAmounts = Map<InGameItem, double>;

/// An immutable, and validated implementation of [ItemIo]
/// All values in [inputs] or [outputs] may be greater than or equal to 0
class ItemIo {
  static const empty = ItemIo._empty();

  final ItemAmounts inputs;
  final ItemAmounts outputs;
  final bool isEmpty;
  bool get isNotEmpty => !isEmpty;
  final bool isZero;

  const ItemIo._empty()
    : inputs = const {},
      outputs = const {},
      isEmpty = true,
      isZero = true;

  ItemIo({ItemAmounts inputs = const {}, ItemAmounts outputs = const {}})
    : inputs = Map.unmodifiable(inputs),
      outputs = Map.unmodifiable(outputs),
      isEmpty = inputs.isEmpty && outputs.isEmpty,
      isZero = inputs.values
          .followedBy(outputs.values)
          .every((amount) => amount == 0) {
    inputs.forEach((input, amount) {
      if (amount < 0) {
        throw FactorioException('Input $input had invalid value $amount');
      }
    });

    outputs.forEach((output, amount) {
      if (amount < 0) {
        throw FactorioException('Output $output had invalid value $amount');
      }
    });
  }

  factory ItemIo.sum(Iterable<ItemIo> toSum) {
    ItemAmounts inputSum = {};
    ItemAmounts outputSum = {};

    for (var itemIo in toSum) {
      itemIo.inputs.forEach(
        (item, amount) => inputSum.update(
          item,
          (amountSum) => amountSum + amount,
          ifAbsent: () => amount,
        ),
      );
      itemIo.outputs.forEach(
        (item, amount) => outputSum.update(
          item,
          (amountSum) => amountSum + amount,
          ifAbsent: () => amount,
        ),
      );
    }

    return ItemIo(inputs: inputSum, outputs: outputSum);
  }

  ItemIo zeroAll() => multiplyValues(0);

  ItemIo multiplyValues(double multiplier) {
    ItemAmounts newInputs = Map.from(inputs);
    ItemAmounts newOutputs = Map.from(outputs);

    newInputs.updateAll((item, amount) => amount * multiplier);
    newOutputs.updateAll((item, amount) => amount * multiplier);

    return ItemIo(inputs: newInputs, outputs: newOutputs);
  }

  @override
  bool operator ==(Object other) {
    return super == other ||
        (other is ItemIo &&
            compareMaps(other.inputs, inputs) &&
            compareMaps(other.outputs, outputs));
  }

  @override
  int get hashCode => inputs.entries
      .followedBy(outputs.entries)
      .map((entry) => entry.key.hashCode * entry.value.hashCode)
      .reduce((val1, val2) => val1 + val2);

  @override
  String toString() => 'inputs: $inputs, outputs: $outputs';
}
