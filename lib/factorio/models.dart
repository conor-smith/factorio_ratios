import 'dart:math';

import 'package:logging/logging.dart';

part 'models/crafting_machines.dart';
part 'models/dynamic_models.dart';
part 'models/item.dart';
part 'models/recipe.dart';

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

// Relationships between entities are lazily evaluated
// The exception to this are the relationships between recipes and items
// to iterate over all recipes for items, categories, etc, than to search through them
class FactorioDatabase {
  late final Map<String, Item> _itemMap;
  late final Map<String, Recipe> _recipeMap;
  late final Map<String, CraftingMachine> _craftingMachineMap;

  Map<String, List<Recipe>> _craftingCategoriesAndRecipes = {};
  Map<String, List<CraftingMachine>> _craftingCategoriesAndMachines = {};

  static final Logger _logger = Logger('FactorioDb');

  void initialise(
    Map<String, Item> itemMap,
    Map<String, Recipe> recipeMap,
    Map<String, CraftingMachine> craftingMachineMap,
  ) {
    _itemMap = Map.unmodifiable(itemMap);
    _recipeMap = Map.unmodifiable(recipeMap);
    _craftingMachineMap = Map.unmodifiable(craftingMachineMap);

    _buildNonLazyRelationships();
  }

  void _buildNonLazyRelationships() {
    _logger.info('Building non-lazy relationships');
    
    _recipeMap.forEach((name, recipe) {
      _logger.info('Building relationships for recipe $name');
      for (var category in recipe.categories) {
        _craftingCategoriesAndRecipes.update(
          category,
          (recipeList) => recipeList..add(recipe),
          ifAbsent: () => [],
        );
      }

      for (var ingredient in recipe.ingredients) {
        Item item = _itemMap[ingredient._name]!;

        ingredient.item = _itemMap[ingredient._name]!;
        item._consumedBy.add(recipe);
      }

      for (var result in recipe.results) {
        Item item = _itemMap[result._name]!;

        result.item = item;
        item._producedBy.add(recipe);
      }
    });

    _craftingMachineMap.forEach((name, craftingMachine) {
      for (var category in craftingMachine.craftingCategories) {
        _craftingCategoriesAndMachines.update(
          category,
          (machineList) => machineList..add(craftingMachine),
          ifAbsent: () => [],
        );
      }
    });

    _craftingCategoriesAndRecipes.updateAll(
      (category, recipeList) => List.unmodifiable(recipeList)
    );
    _craftingCategoriesAndRecipes = Map.unmodifiable(
      _craftingCategoriesAndRecipes,
    );

    _craftingCategoriesAndMachines.updateAll(
      (category, machineList) => List.unmodifiable(machineList)
    );
    _craftingCategoriesAndMachines = Map.unmodifiable(
      _craftingCategoriesAndMachines,
    );

    _itemMap.forEach((name, item) {
      item._consumedBy = List.unmodifiable(item._consumedBy);
      item._producedBy = List.unmodifiable(item._producedBy);
    });
  }

  Map<String, Item> get itemMap => _itemMap;
  Map<String, Recipe> get recipeMap => _recipeMap;
  Map<String, CraftingMachine> get craftingMachineMap => _craftingMachineMap;
}
