import 'dart:collection';

import 'package:factorio_ratios/factorio/factorio.dart';
import 'package:factorio_ratios/factorio/models/models.dart';
import 'package:factorio_ratios/json/json.dart';
import 'package:factorio_ratios/utility/builder.dart';
import 'package:factorio_ratios/utility/collections.dart';

part 'display_data.dart';
part 'in_game_item.dart';
part 'in_game_recipe.dart';
part 'in_game_machine.dart';

typedef ItemAmounts = Map<InGameItem, double>;

abstract class ItemIo {
  ItemAmounts get inputs;
  ItemAmounts get outputs;

  bool get isEmpty => inputs.isEmpty && outputs.isEmpty;
  bool get isNotEmpty => !isEmpty;

  bool get isZero =>
      isEmpty ||
      inputs.values.followedBy(outputs.values).every((amount) => amount <= 0);

  const ItemIo();
}

/// An immutable, and validated implementation of [ItemIo]
/// All values in [inputs] or [outputs] may be greater than or equal to 0
class ItemIoImpl extends ItemIo {
  static const empty = ItemIoImpl._empty();

  @override
  final ItemAmounts inputs;
  @override
  final ItemAmounts outputs;

  const ItemIoImpl._empty() : inputs = const {}, outputs = const {};

  ItemIoImpl({ItemAmounts inputs = const {}, ItemAmounts outputs = const {}})
    : inputs = Map.unmodifiable(inputs),
      outputs = Map.unmodifiable(outputs) {
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

  factory ItemIoImpl.sum(Iterable<ItemIoImpl> toSum) {
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

    return ItemIoImpl(inputs: inputSum, outputs: outputSum);
  }

  ItemIoImpl zeroAll() => multiplyValues(0);

  ItemIoImpl multiplyValues(double multiplier) {
    ItemAmounts newInputs = Map.from(inputs);
    ItemAmounts newOutputs = Map.from(outputs);

    newInputs.updateAll((item, amount) => amount * multiplier);
    newOutputs.updateAll((item, amount) => amount * multiplier);

    return ItemIoImpl(inputs: newInputs, outputs: newOutputs);
  }

  @override
  bool operator ==(Object other) {
    return super == other ||
        (other is ItemIoImpl &&
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

class ItemIoBuilder extends ItemIo implements Builder<ItemIoImpl> {
  final ItemAmounts _inputs;
  final ItemAmounts _outputs;

  @override
  late final ItemAmounts inputs = UnmodifiableMapView(_inputs);
  @override
  late final ItemAmounts outputs = UnmodifiableMapView(_outputs);

  ItemIoBuilder() : _inputs = {}, _outputs = {};

  ItemIoBuilder.from(ItemIoImpl source)
    : _inputs = Map.from(source.inputs),
      _outputs = Map.from(source.outputs);

  void addToInputs(InGameItem key, double toAdd) =>
      _inputs.update(key, (amount) => amount + toAdd, ifAbsent: () => toAdd);
  void addToOutputs(InGameItem key, double toAdd) =>
      _outputs.update(key, (amount) => amount + toAdd, ifAbsent: () => toAdd);

  void removeFromInputs(InGameItem key) => _inputs.remove(key);
  void removeFromOutputs(InGameItem key) => _outputs.remove(key);

  @override
  ItemIoImpl build() => ItemIoImpl(inputs: _inputs, outputs: _outputs);
}
