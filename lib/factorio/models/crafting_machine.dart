part of 'models.dart';

class CraftingMachine extends PrototypeWithIcon {
  @override
  final CraftingMachineJson internalJson;

  CraftingMachine({required super.database, required this.internalJson});
}
