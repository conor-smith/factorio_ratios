import 'dart:math';

part 'item.dart';
part 'recipe.dart';
part 'crafting_machines.dart';

final Map<String, double> _multipliers = {
  "k": pow(10, 3).toDouble(),
  "M": pow(10, 6).toDouble(),
  "G": pow(10, 9).toDouble(),
  "T": pow(10, 12).toDouble(),
  "P": pow(10, 15).toDouble(),
  "E": pow(10, 18).toDouble(),
  "Z": pow(10, 21).toDouble(),
  "Y": pow(10, 24).toDouble(),
  "R": pow(10, 27).toDouble(),
  "Q": pow(10, 30).toDouble(),
};

double? _convertStringToEnergy(String? energyUsage) {
  if (energyUsage == null) {
    return null;
  }

  String multiplier = energyUsage.substring(
    energyUsage.length - 2,
    energyUsage.length - 1,
  );

  if (_multipliers.containsKey(multiplier)) {
    return double.parse(energyUsage.substring(0, energyUsage.length - 2)) *
        _multipliers[multiplier]!;
  } else {
    return double.parse(energyUsage.substring(0, energyUsage.length - 1));
  }
}

class FactorioDatabase {
  List<Item> items;
  List<Recipe> recipes;
  List<CraftingMachine> craftingMachines;

  FactorioDatabase(this.items, this.recipes, this.craftingMachines);
}

// TODO
const String _defaultIcon = 'TODO';
