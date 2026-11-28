part of 'models.dart';

class CraftingMachine extends PrototypeWithIcon {
  @override
  final CraftingMachineJson internalJson;
  final double energyConsumption;

  CraftingMachine({required super.database, required this.internalJson})
    : energyConsumption = _convertStringToEnergy(internalJson.energyUsage);
}
