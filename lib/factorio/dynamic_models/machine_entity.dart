part of 'dynamic_models.dart';

class _MachineEntityImpl extends DelegatingCraftingMachine
    with QualityPrototype
    implements MachineEntity {
  // TODO - Quality effects

  @override
  final CraftingMachine internal;

  @override
  final Quality quality;
  @override
  final ItemEntity? item;

  factory _MachineEntityImpl(CraftingMachine machine, [Quality? quality]) {
    quality ??= machine.factorioDb.defaultQuality;

    if (machine is _MachineEntityImpl && machine.quality == quality) {
      return machine;
    } else if (machine is DelegatingCraftingMachine) {
      machine = machine.internal;
    }
    return _MachineEntityImpl._(machine, quality);
  }

  _MachineEntityImpl._(this.internal, this.quality)
    : item = internal.item != null
          ? ItemEntity(internal.item!, quality: quality)
          : null;

  @override
  bool operator ==(Object other) =>
      super == other ||
      other is _MachineEntityImpl &&
          internal == other.internal &&
          quality == other.quality;

  @override
  int get hashCode => internal.hashCode + quality.hashCode;

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}
