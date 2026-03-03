part of '../production_line.dart';

// Acts as a "magic" line, consuming / producing all requirements with no buildings
// Used to represent natural resources or disposal
class IoLine extends ProductionLine {
  final Map<ItemData, double> _requirements = {};
  @override
  final Set<ItemData> allInputs;
  @override
  final Set<ItemData> allOutputs;

  // requirements and totalIOPerSecond point are all the same values
  @override
  late final Map<ItemData, double> requirements = UnmodifiableMapView(
    _requirements,
  );
  @override
  late final Map<ItemData, double> totalIoPerSecond = requirements;

  IoLine({Set<ItemData> inputs = const {}, Set<ItemData> outputs = const {}})
    : allInputs = Set.unmodifiable(inputs),
      allOutputs = Set.unmodifiable(outputs) {
    if (allInputs.isEmpty && allOutputs.isEmpty) {
      throw const FactorioException('Cannot create a IO line with no IO');
    }
  }

  @override
  void update(Map<ItemData, double> newRequirements) {
    super.update(newRequirements);

    // For IO line specifically, all io must be given a requirement
    var allIo = {...allInputs, ...allOutputs};
    for (var io in allIo) {
      if (!newRequirements.containsKey(io)) {
        throw FactorioException('Input/output amount for "$io" not specified');
      }
    }

    _requirements.addAll(newRequirements);
  }

  @override
  void reset() {
    _requirements.clear();
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
