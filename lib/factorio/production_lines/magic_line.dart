part of '../production_line.dart';

// Acts as a "magic" line, consuming / producing all requirements with no buildings
// Used to represent natural resources or disposal
class MagicLine implements ProductionLine {
  final Map<ItemData, double> _totalIoPerSecond;

  @override
  late final Map<ItemData, double> totalIoPerSecond = UnmodifiableMapView(
    _totalIoPerSecond,
  );

  MagicLine({Map<ItemData, double> initialIo = const {}})
    : _totalIoPerSecond = Map.from(initialIo);

  @override
  Set<ItemData> get allInputs => Set.unmodifiable(
    _totalIoPerSecond.entries
        .where((entry) => entry.value < 0)
        .map((entry) => entry.key),
  );

  @override
  Set<ItemData> get allOutputs => Set.unmodifiable(
    _totalIoPerSecond.entries
        .where((entry) => entry.value > 0)
        .map((entry) => entry.key),
  );

  @override
  void update(Map<ItemData, double> requirements) {
    _totalIoPerSecond.clear();
    _totalIoPerSecond.addAll(requirements);
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
