part of 'dynamic_models.dart';

class MachineEntity extends DelegatingCraftingMachine
    with QualityPrototype
    implements ToJson {
  // TODO - Quality effects

  @override
  final CraftingMachine internal;

  @override
  final Quality quality;
  @override
  final ItemEntity? item;

  factory MachineEntity(CraftingMachine machine, [Quality? quality]) {
    quality ??= machine.factorioDb.defaultQuality;

    if (machine is MachineEntity && machine.quality == quality) {
      return machine;
    } else if (machine is DelegatingCraftingMachine) {
      machine = machine.internal;
    }
    return MachineEntity._(machine, quality);
  }

  MachineEntity._(this.internal, this.quality)
    : item = internal.item != null
          ? ItemEntity(internal.item!, quality: quality)
          : null;

  @override
  bool operator ==(Object other) =>
      super == other ||
      other is MachineEntity &&
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
