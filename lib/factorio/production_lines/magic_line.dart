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
}
