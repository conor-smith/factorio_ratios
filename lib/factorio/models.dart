import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:factorio_ratios/factorio/factorio.dart';
import 'package:logging/logging.dart';

part 'models/crafting_machines.dart';
part 'models/group.dart';
part 'models/item.dart';
part 'models/other_interfaces.dart';
part 'models/recipe.dart';
part 'models/subgroup.dart';

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

/*
 * All entities (items, recipes, etc) are created from the JSON output from `factorio --dump-data`
 * Once instantiated, the database and all entities within it are immutable
 * All constructors are private. Entities may only be created by the db and no new entities can be added
 * In order to update the db to include mod entities, the entire db must be rebuilt
 * Relationships can be accessed via the entities themselves
 * Some relationships are lazily evaluated, but most are determined when building the db
 */
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
   * Crafting machine defualt productivity
   */

  late final Map<String, Item> itemMap;
  late final Map<String, Recipe> recipeMap;
  late final Map<String, CraftingMachine> craftingMachineMap;
  late final Map<String, ItemGroup> itemGroupMap;
  late final Map<String, ItemSubgroup> itemSubgroupMap;

  // Each of these fields acts as an index when querying the db
  late final Map<String, List<Recipe>> _craftingCategoryToRecipes;
  late final Map<String, List<CraftingMachine>> _craftingCategoryToMachines;
  late final Map<String, List<SolidItem>> _fuelCategoryToItems;
  late final Map<Item, List<SolidItem>> _spoilResults;
  late final Map<Item, List<SolidItem>> _burnResults;
  late final Map<Item, List<Recipe>> _producedBy;
  late final Map<Item, List<Recipe>> _consumedBy;

  static final Logger _logger = Logger('FactorioDb');

  FactorioDatabase.fromJson(String rawJson) {
    _parseJson(rawJson);
    _buildIndices();
  }

  void _parseJson(String rawJson) {
    _logger.info('Decoding raw data dump');
    Map factorioRawData = jsonDecode(rawJson);

    Map<String, Item> items = {};
    Map<String, Recipe> recipes = {};
    Map<String, CraftingMachine> craftingMachines = {};
    Map<String, ItemGroup> itemGroups = {};
    Map<String, ItemSubgroup> itemSubgroups = {};

    // TODO - clean up
    _logger.info('decoding items');

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
        _logger.info('Encountered error when decoding item "$name"', e);
        rethrow;
      }
    });

    _logger.info('decoding recipes');
    Map<String, Map> rawRecipes = (factorioRawData['recipe'] as Map).cast();
    rawRecipes.forEach((name, recipeJson) {
      try {
        if (recipeJson['parameter'] != true) {
          recipes[name] = Recipe.fromJson(this, recipeJson);
        }
      } catch (e) {
        _logger.info('Encountered error when decoding recipe "$name"', e);
        rethrow;
      }
    });

    _logger.info('decoding machines');
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
        _logger.info(
          'Encountered error when decoding crafting machine "$name"',
          e,
        );
        rethrow;
      }
    });

    _logger.info('decoding item groups');
    Map<String, Map> rawItemGroups = (factorioRawData['item-group'] as Map)
        .cast();
    rawItemGroups.forEach((name, groupJson) {
      try {
        itemGroups[name] = ItemGroup.fromJson(this, groupJson);
      } catch (e) {
        _logger.info('Encountered error when decoding item group "$name"', e);
        rethrow;
      }
    });

    _logger.info('decoding item subgroups');
    Map<String, Map> rawItemSubgroups =
        (factorioRawData['item-subgroup'] as Map).cast();
    rawItemSubgroups.forEach((name, subgroupJson) {
      try {
        itemSubgroups[name] = ItemSubgroup.fromJson(this, subgroupJson);
      } catch (e) {
        _logger.info(
          'Encountered error when decoding item subgroup "$name"',
          e,
        );
        rethrow;
      }
    });

    itemMap = Map.unmodifiable(items);
    recipeMap = Map.unmodifiable(recipes);
    craftingMachineMap = Map.unmodifiable(craftingMachines);
    itemGroupMap = Map.unmodifiable(itemGroups);
    itemSubgroupMap = Map.unmodifiable(itemSubgroups);
  }

  void _buildIndices() {
    _logger.info('Building non-lazy relationships');

    Map<String, List<Recipe>> craftingCategoryToRecipes = {};
    Map<String, List<CraftingMachine>> craftingCategoryToMachines = {};
    Map<String, List<SolidItem>> fuelCategoryToItems = {};
    Map<Item, List<SolidItem>> spoilResults = {};
    Map<Item, List<SolidItem>> burntResults = {};
    Map<Item, List<Recipe>> consumedBy = {};
    Map<Item, List<Recipe>> producedBy = {};

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
        _logger.info(
          'Encountered error when building relationships for recipe $name',
          e,
        );
        rethrow;
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
        _logger.info(
          'Encountered error when building relationships for crafting machine $name',
          e,
        );
        rethrow;
      }
    });

    itemMap.forEach((name, item) {
      try {
        if (item is SolidItem) {
          SolidItem solidItem = item;

          if (solidItem._burnResultString != null) {
            Item burntResult = itemMap[solidItem._burnResultString]!;
            solidItem.burntResult = burntResult;
            burntResults.update(
              burntResult,
              (items) => items..add(solidItem),
              ifAbsent: () => [solidItem],
            );
          } else {
            solidItem.burntResult = null;
          }

          if (solidItem._spoilResultString != null) {
            Item spoilResult = itemMap[solidItem._spoilResultString]!;
            solidItem.spoilResult = spoilResult;
            spoilResults.update(
              spoilResult,
              (items) => items..add(solidItem),
              ifAbsent: () => [solidItem],
            );
          } else {
            solidItem.spoilResult = null;
          }

          if (solidItem.fuelCategory != null) {
            String category = solidItem.fuelCategory!;

            fuelCategoryToItems.update(
              category,
              (items) => items..add(solidItem),
              ifAbsent: () => [solidItem],
            );
          }
        }
      } catch (e) {
        _logger.info(
          'Encountered error when building relationships for item $name',
          e,
        );
        rethrow;
      }
    });

    _craftingCategoryToRecipes = Map.unmodifiable(craftingCategoryToRecipes);
    _craftingCategoryToMachines = Map.unmodifiable(craftingCategoryToMachines);
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
