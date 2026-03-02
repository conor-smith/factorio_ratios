part of '../production_line.dart';

// Acts as a "magic" line, consuming / producing all requirements with no buildings
// Used to represent natural resources or disposal
class MagicLine extends ProductionLine {
  final Map<ItemData, double> _totalIoPerSecond = {};
  final Set<ItemData> _allInputs;
  final Set<ItemData> _allOutputs;

  @override
  late final Set<ItemData> allInputs = UnmodifiableSetView(_allInputs);
  @override
  late final Set<ItemData> allOutputs = UnmodifiableSetView(_allOutputs);
  @override
  late final Map<ItemData, double> totalIoPerSecond = UnmodifiableMapView(
    _totalIoPerSecond,
  );

  MagicLine({Set<ItemData> inputs = const {}, Set<ItemData> outputs = const {}})
    : _allInputs = Set.from(inputs),
      _allOutputs = Set.from(outputs);

  @override
  void update(Map<ItemData, double> requirements) {
    super.update(requirements);

    _totalIoPerSecond.clear();
    _totalIoPerSecond.addAll(requirements);
  }

  void addOutputs(Set<ItemData> items) {
    for (var output in items) {
      if (_allInputs.contains(output)) {
        throw FactorioException(
          '"$output" is an input and cannot be added to outputs',
        );
      }
    }

    _allOutputs.addAll(items);
  }

  void removeOutputs(Set<ItemData> items) {
    _allOutputs.removeAll(items);
  }

  void addInputs(Set<ItemData> items) {
    for (var input in items) {
      if (_allOutputs.contains(input)) {
        throw FactorioException(
          '"$input" is an output and cannot be added to inputs',
        );
      }
    }

    _allInputs.addAll(items);
  }

  void removeInputs(Set<ItemData> items) {
    _allInputs.removeAll(items);
  }

  @override
  String toString() {
    var inputs = allInputs;
    var outputs = allOutputs;

    if (inputs.isEmpty && outputs.isNotEmpty) {
      return _convertItemSetToString(outputs);
    } else if (inputs.isNotEmpty && outputs.isEmpty) {
      return _convertItemSetToString(inputs);
    } else if (inputs.isNotEmpty && outputs.isNotEmpty) {
      var inputsString = _convertItemSetToString(inputs);
      var outputsString = _convertItemSetToString(outputs);
      return 'Inputs: $inputsString\nOutputs: $outputsString';
    } else {
      return '';
    }
  }

  String _convertItemSetToString(Set<ItemData> items) {
    return items.map((item) => item.toString()).reduce((s1, s2) => '$s1, $s2');
  }
}
