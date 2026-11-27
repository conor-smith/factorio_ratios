part of 'models.dart';

class CraftingMachine extends PrototypeWithQuality<CraftingMachine> {
  @override
  final CraftingMachineJson internalJson;

  CraftingMachine({
    required super.database,
    required super.quality,
    required this.internalJson,
  });

  @override
  CraftingMachine withQuality(Quality quality) => throw UnimplementedError(); // TODO
}
