part of 'models.dart';

class CraftingMachine extends PrototypeWithQuality {
  @override
  final CraftingMachineJson internalJson;

  CraftingMachine({
    required super.database,
    required super.qualityName,
    required this.internalJson,
  });
}
