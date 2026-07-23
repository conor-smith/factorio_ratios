import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:factorio_ratios/factorio/factorio.dart';

part 'crafting_machines.dart';
part 'group.dart';
part 'icon.dart';
part 'item.dart';
part 'other_interfaces.dart';
part 'recipe.dart';
part 'resource.dart';
part 'subgroup.dart';
part 'surface.dart';
part 'technology.dart';

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

enum Effects {
  consumption('consumption', minMultiplier: 0.2),
  productivity('productivity', minMultiplier: 1),
  speed('speed', minMultiplier: 0.2),
  pollution('pollution'),
  quality('quality', defaultMultiplier: 0);

  final String name;
  final double defaultMultiplier;

  final double minMultiplier;
  final double maxMultiplier;

  final double minBonus;
  final double maxBonus;

  const Effects(
    this.name, {
    this.defaultMultiplier = 1,
    this.minMultiplier = double.negativeInfinity,
    this.maxMultiplier = double.infinity,
  }) : minBonus = minMultiplier - defaultMultiplier,
       maxBonus = maxMultiplier - defaultMultiplier;

  double bonusOrBound(double bonus) {
    if (bonus > maxBonus) {
      return maxBonus;
    } else if (bonus < minBonus) {
      return minBonus;
    } else {
      return bonus;
    }
  }

  @override
  String toString() => name;
}

/// Represents a database containing all items, recipes, machines, etc in the game.
///
/// All entities are created from the JSON output from `factorio --dump-data`.
/// Once instantiated, the database and all entities within it are immutable.
/// All constructors are private. Entities may only be created by the db and no new entities can be added.
/// In order to update the db to include mod entities, the entire db must be rebuilt.
/// Relationships can be accessed via the entities themselves.
class FactorioDatabase {
  /*
   * TODO
   * Better logging
   * Index for spoiled results
   * Index for burnt results
   * Index for fuel categories
   * Module entities
   * Beacon entities
   * Belt entities
   * Planet entities
   * Inserter entities (maybe)
   * Relationships between physical entities and items
   * Percent spoiled for items
   * Icons
   * Mod support
   * Heating energy (for Aquilo)
   * Crafting machine fixed recipes
   */

  late final Map<String, Item> itemMap;
  late final Map<String, Recipe> recipeMap;
  late final Map<String, CraftingMachine> craftingMachineMap;
  late final Map<String, ItemGroup> itemGroupMap;
  late final Map<String, ItemSubgroup> itemSubgroupMap;
  late final Map<String, Surface> surfaceMap;
  late final Map<String, Resource> resourceMap;

  // Each of these fields acts as an index when querying the db
  late final Map<String, List<Recipe>> _craftingCategoryToRecipes;
  late final Map<String, List<CraftingMachine>> _craftingCategoryToMachines;
  late final Map<String, List<SolidItem>> _fuelCategoryToItems;
  late final Map<String, List<SolidItem>> _placeResult;
  late final Map<Item, List<SolidItem>> _spoilResults;
  late final Map<Item, List<SolidItem>> _burnResults;
  late final Map<Item, List<Recipe>> _producedBy;
  late final Map<Item, List<Recipe>> _consumedBy;

  FactorioDatabase.fromJson(String rawJson) {
    _parseJson(rawJson);
    _buildIndices();
  }

  void _parseJson(String rawJson) {
    Map factorioRawData = jsonDecode(rawJson);

    Map<String, Item> items = {};
    Map<String, Technology> technologies = {};
    Map<String, Recipe> recipes = {};
    Map<String, CraftingMachine> craftingMachines = {};
    Map<String, ItemGroup> itemGroups = {};
    Map<String, ItemSubgroup> itemSubgroups = {};
    Map<String, Surface> surfaces = {};
    Map<String, Resource> resources = {};

    List<String> itemSections = [
      'item',
      'module',
      'gun',
      'ammo',
      'armor',
      'repair-tool',
      'tool',
      'item-with-entity-data',
      'capsule',
      'rail-planner',
      'item-with-entity-data',
      'space-platform-starter-pack',
      'blueprint',
      'blueprint-book',
      'deconstruction-item',
      'upgrade-item',
      'selection-tool',
      'fluid',
    ];
    List<String> machineSections = [
      'assembling-machine',
      'rocket-silo',
      'furnace',
    ];
    List<String> surfaceSections = ['planet', 'surface'];

    Map<String, Map> rawItems = {};
    for (var section in itemSections) {
      rawItems.addAll((factorioRawData[section] as Map).cast());
    }

    rawItems.forEach((name, itemJson) {
      try {
        if (itemJson['parameter'] != true) {
          items[name] = Item.fromJson(this, itemJson);
        }
      } catch (e) {
        throw FactorioException(
          'Encountered error when decoding item $name',
          e,
        );
      }
    });

    Map<String, Map> rawTechnologies = (factorioRawData['technology'] as Map)
        .cast();
    rawTechnologies.forEach((name, techJson) {
      try {
        if (techJson['parameter'] != true) {
          technologies[name] = Technology.fromJson(this, techJson);
        }
      } catch (e) {
        throw FactorioException(
          'Encountered error when decoding technology $name',
          e,
        );
      }
    });

    Set<String> unlockedRecipes = technologies.values
        .expand((tech) => tech.effects)
        .where((modifier) => modifier.type == 'unlock-recipe')
        .map((modifier) => modifier._recipeString)
        .nonNulls
        .toSet();

    Map<String, Map> rawRecipes = (factorioRawData['recipe'] as Map).cast();
    rawRecipes.forEach((name, recipeJson) {
      try {
        if (recipeJson['parameter'] != true) {
          recipes[name] = Recipe.fromJson(this, recipeJson);
        }
      } catch (e) {
        throw FactorioException(
          'Encountered error when decoding recipe $name',
          e,
        );
      }
    });

    recipes.removeWhere(
      (name, recipe) => !recipe.enabled && !unlockedRecipes.contains(name),
    );

    Map<String, Map> rawCraftingMachines = {};
    for (var machineSection in machineSections) {
      rawCraftingMachines.addAll(
        (factorioRawData[machineSection] as Map).cast(),
      );
    }
    rawCraftingMachines.forEach((name, machineJson) {
      try {
        craftingMachines[name] = CraftingMachine.fromJson(this, machineJson);
      } catch (e) {
        throw FactorioException(
          'Encountered error when decoding crafting machine $name',
          e,
        );
      }
    });

    Map<String, Map> rawItemGroups = (factorioRawData['item-group'] as Map)
        .cast();
    rawItemGroups.forEach((name, groupJson) {
      try {
        itemGroups[name] = ItemGroup.fromJson(this, groupJson);
      } catch (e) {
        throw FactorioException(
          'Encountered error when decoding item group $name',
          e,
        );
      }
    });

    Map<String, Map> rawItemSubgroups =
        (factorioRawData['item-subgroup'] as Map).cast();
    rawItemSubgroups.forEach((name, subgroupJson) {
      try {
        itemSubgroups[name] = ItemSubgroup.fromJson(this, subgroupJson);
      } catch (e) {
        throw FactorioException(
          'Encountered error when decoding item subgroup $name',
          e,
        );
      }
    });

    Map<String, Map> rawSurfaces = {};
    for (var surfaceSection in surfaceSections) {
      rawSurfaces.addAll((factorioRawData[surfaceSection] as Map).cast());
    }
    rawSurfaces.forEach((name, planetJson) {
      try {
        surfaces[name] = Surface.fromJson(this, planetJson);
      } catch (e) {
        throw FactorioException(
          'Encountered error when decoding surface $name',
          e,
        );
      }
    });

    Map<String, Map> rawResources = (factorioRawData['resource'] as Map).cast();
    rawResources.forEach((name, resourceJson) {
      try {
        resources[name] = Resource.fromJson(this, resourceJson);
      } catch (e) {
        throw FactorioException(
          'Encountered error when decoding resource $name',
          e,
        );
      }
    });

    itemMap = Map.unmodifiable(items);
    recipeMap = Map.unmodifiable(recipes);
    craftingMachineMap = Map.unmodifiable(craftingMachines);
    itemGroupMap = Map.unmodifiable(itemGroups);
    itemSubgroupMap = Map.unmodifiable(itemSubgroups);
    surfaceMap = Map.unmodifiable(surfaces);
    resourceMap = Map.unmodifiable(resources);
  }

  void _buildIndices() {
    Map<String, List<Recipe>> craftingCategoryToRecipes = {};
    Map<String, List<CraftingMachine>> craftingCategoryToMachines = {};
    Map<String, List<SolidItem>> fuelCategoryToItems = {};
    Map<Item, List<SolidItem>> spoilResults = {};
    Map<Item, List<SolidItem>> burntResults = {};
    Map<Item, List<Recipe>> consumedBy = {};
    Map<Item, List<Recipe>> producedBy = {};
    Map<String, List<SolidItem>> placeResult = {};

    recipeMap.forEach((name, recipe) {
      try {
        for (var category in recipe.categories) {
          craftingCategoryToRecipes.update(
            category,
            (recipeList) => recipeList..add(recipe),
            ifAbsent: () => [recipe],
          );
        }

        for (var ingredient in recipe.ingredients) {
          Item item = ingredient.item;

          consumedBy.update(
            item,
            (recipes) => recipes..add(recipe),
            ifAbsent: () => [recipe],
          );
        }

        for (var result in recipe.results) {
          Item item = result.item;

          producedBy.update(
            item,
            (recipes) => recipes..add(recipe),
            ifAbsent: () => [recipe],
          );
        }
      } catch (e) {
        throw FactorioException(
          'Encountered exception when building relationships for recipe $name',
          e,
        );
      }
    });

    craftingMachineMap.forEach((name, craftingMachine) {
      try {
        for (var category in craftingMachine.craftingCategories) {
          craftingCategoryToMachines.update(
            category,
            (machineList) => machineList..add(craftingMachine),
            ifAbsent: () => [craftingMachine],
          );
        }
      } catch (e) {
        throw FactorioException(
          'Encountered error when building relationships for crafting machine $name',
          e,
        );
      }
    });

    itemMap.forEach((name, item) {
      try {
        if (item is SolidItem) {
          if (item._burnResultString != null) {
            Item burntResult = itemMap[item._burnResultString]!;
            burntResults.update(
              burntResult,
              (items) => items..add(item),
              ifAbsent: () => [item],
            );
          }

          if (item._spoilResultString != null) {
            Item spoilResult = itemMap[item._spoilResultString]!;
            spoilResults.update(
              spoilResult,
              (items) => items..add(item),
              ifAbsent: () => [item],
            );
          }

          if (item._placeResultString != null) {
            placeResult.update(
              item._placeResultString,
              (items) => items..add(item),
              ifAbsent: () => [item],
            );
          }

          if (item.fuelCategory != null) {
            String category = item.fuelCategory!;

            fuelCategoryToItems.update(
              category,
              (items) => items..add(item),
              ifAbsent: () => [item],
            );
          }
        }
      } catch (e) {
        throw FactorioException(
          'Encountered error when building relationships for item $name',
          e,
        );
      }
    });

    _craftingCategoryToRecipes = Map.unmodifiable(craftingCategoryToRecipes);
    _craftingCategoryToMachines = Map.unmodifiable(craftingCategoryToMachines);
    _placeResult = Map.unmodifiable(placeResult);
    _fuelCategoryToItems = Map.unmodifiable(fuelCategoryToItems);
    _spoilResults = Map.unmodifiable(spoilResults);
    _burnResults = Map.unmodifiable(burntResults);
    _consumedBy = Map.unmodifiable(consumedBy);
    _producedBy = Map.unmodifiable(producedBy);
  }
}

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

Map<String, double> _parseStringDoubleMap(Map? json) {
  json ??= const {};

  // JSON interpreter sometimes returns ints rather than doubles
  // So this is the easiest solution
  Map<String, double> toReturn = {};
  json.forEach((key, value) => toReturn[key] = value.toDouble());

  return Map.unmodifiable(toReturn);
}
