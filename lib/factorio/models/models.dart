part 'item.dart';
part 'recipe.dart';
part 'crafting_machines.dart';

// TODO - either add fluid class or make item and fluid parent / child

double _convertStringToWatts(String? energyUsage) {
  // TODO
  return 0;
}

double _convertStringToJoules(String? energy) {
  // TODO
  return 0;
}

String? _getIcon(Map json) => json['icon'] ?? json['icons']?[0]?['icon'];

class FactorioDatabase {
  List<Item> items;
  List<Recipe> recipes;
  List<CraftingMachine> craftingMachines;

  FactorioDatabase(this.items, this.recipes, this.craftingMachines);
}

// TODO
const String _defaultIcon = 'TODO';