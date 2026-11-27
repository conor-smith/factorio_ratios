part of 'models.dart';

class CraftingMachine extends PrototypeWithQuality {
  @override
  final CraftingMachineJson _internalJson;

  CraftingMachine({
    required super.database,
    required super.qualityName,
    required this._internalJson,
  });
}
