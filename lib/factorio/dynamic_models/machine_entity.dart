part of 'dynamic_models.dart';

class MachineEntity extends DelegatingCraftingMachine
    implements QualityPrototype, ToJson {
  // TODO - Quality effects

  @override
  final CraftingMachine internal;

  @override
  final Quality quality;
  @override
  final String name;
  @override
  final ItemEntity? item;
  @override
  final Icon? icon;

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
    : name = quality.name != Quality.defaultName
          ? '$quality ${internal.name}'
          : internal.name,
      item = internal.item != null
          ? ItemEntity(internal.item!, quality: quality)
          : null,
      icon = internal.icon?.withQuality(quality);

  // Ensure that machines of different quality are separated
  @override
  int compareTo(Prototype other) {
    if (other is MachineEntity) {
      if (quality > other.quality) {
        return -1;
      } else if (quality < other.quality) {
        return 1;
      }
    }
    return internal.compareTo(other);
  }

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
