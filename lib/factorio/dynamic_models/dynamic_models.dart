import 'dart:collection';

import 'package:factorio_ratios/factorio/factorio.dart';
import 'package:factorio_ratios/factorio/models/models.dart';
import 'package:factorio_ratios/utility/json.dart';
import 'package:factorio_ratios/utility/builder.dart';
import 'package:factorio_ratios/utility/collections.dart';

part 'delegating_models.dart';
part 'display_data.dart';
part 'interfaces.dart';
part 'item_entity.dart';
part 'item_spec.dart';
part 'machine_entity.dart';
part 'quality_recipe.dart';
part 'sorted_item_groups.dart';

typedef ItemAmounts = Map<ItemEntity, double>;

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

  ItemIoImpl convertToRatios() {
    if (isEmpty) {
      return this;
    }

    double smallestValue = inputs.values
        .followedBy(outputs.values)
        .reduce((val1, val2) => val1 < val2 ? val1 : val2);

    if (smallestValue == 0.0) {
      return zeroAllValues();
    } else {
      return ItemIoImpl(
        inputs: divideMap(inputs, smallestValue),
        outputs: divideMap(outputs, smallestValue),
      );
    }
  }

  ItemIoImpl zeroAllValues() {
    if (isEmpty) {
      return this;
    }

    return ItemIoImpl(
      inputs: inputs.map((item, _) => MapEntry(item, 0.0)),
      outputs: outputs.map((item, _) => MapEntry(item, 0)),
    );
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

  ItemIoBuilder.from(ItemIo source)
    : _inputs = Map.from(source.inputs),
      _outputs = Map.from(source.outputs);

  void addToInputs(ItemEntity key, double toAdd) =>
      _inputs.update(key, (amount) => amount + toAdd, ifAbsent: () => toAdd);
  void addToOutputs(ItemEntity key, double toAdd) =>
      _outputs.update(key, (amount) => amount + toAdd, ifAbsent: () => toAdd);

  void removeFromInputs(ItemEntity key) => _inputs.remove(key);
  void removeFromOutputs(ItemEntity key) => _outputs.remove(key);

  void addAllToInputs(ItemAmounts toAdd) => sumMaps(_inputs, toAdd);
  void addAllToOutputs(ItemAmounts toAdd) => sumMaps(_outputs, toAdd);
  void addAll(ItemIo toAdd) {
    addAllToInputs(toAdd.inputs);
    addAllToOutputs(toAdd.outputs);
  }

  @override
  ItemIoImpl build() => ItemIoImpl(inputs: _inputs, outputs: _outputs);
}
