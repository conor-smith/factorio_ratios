part of 'models.dart';

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
  late final Map<String, Quality> qualityMap;

  // Each of these fields acts as an index when querying the db
  late final Map<String, List<Recipe>> _craftingCategoryToRecipes;
  late final Map<String, List<CraftingMachine>> _craftingCategoryToMachines;
  late final Map<String, List<SolidItem>> _fuelCategoryToItems;
  late final Map<String, List<SolidItem>> _placeResult;
  late final Map<Item, List<SolidItem>> _spoilResults;
  late final Map<Item, List<SolidItem>> _burnResults;
  late final Map<Item, List<Recipe>> _producedBy;
  late final Map<Item, List<Recipe>> _consumedBy;

  Surface get defaultSurface => surfaceMap[Surface.defaultName]!;
  Quality get defaultQuality => qualityMap[Quality.defaultName]!;

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
    Map<String, Quality> qualities = {};

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
      rawItems.addAll((factorioRawData[section] as Map? ?? const {}).cast());
    }

    rawItems.forEach((name, itemJson) {
      try {
        if (itemJson['parameter'] != true) {
          items[name] = Item.fromJson(this, itemJson);
        }
      } catch (e, st) {
        throw FactorioException.withCause(
          'Encountered error when decoding item $name',
          e,
          st,
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
      } catch (e, st) {
        throw FactorioException.withCause(
          'Encountered error when decoding technology $name',
          e,
          st,
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
      } catch (e, st) {
        throw FactorioException.withCause(
          'Encountered error when decoding recipe $name',
          e,
          st,
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
      } catch (e, st) {
        throw FactorioException.withCause(
          'Encountered error when decoding crafting machine $name',
          e,
          st,
        );
      }
    });

    Map<String, Map> rawItemGroups = (factorioRawData['item-group'] as Map)
        .cast();
    rawItemGroups.forEach((name, groupJson) {
      try {
        itemGroups[name] = ItemGroup.fromJson(this, groupJson);
      } catch (e, st) {
        throw FactorioException.withCause(
          'Encountered error when decoding item group $name',
          e,
          st,
        );
      }
    });

    Map<String, Map> rawItemSubgroups =
        (factorioRawData['item-subgroup'] as Map).cast();
    rawItemSubgroups.forEach((name, subgroupJson) {
      try {
        itemSubgroups[name] = ItemSubgroup.fromJson(this, subgroupJson);
      } catch (e, st) {
        throw FactorioException.withCause(
          'Encountered error when decoding item subgroup $name',
          e,
          st,
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
      } catch (e, st) {
        throw FactorioException.withCause(
          'Encountered error when decoding surface $name',
          e,
          st,
        );
      }
    });

    Map<String, Map> rawResources = (factorioRawData['resource'] as Map).cast();
    rawResources.forEach((name, resourceJson) {
      try {
        resources[name] = Resource.fromJson(this, resourceJson);
      } catch (e, st) {
        throw FactorioException.withCause(
          'Encountered error when decoding resource $name',
          e,
          st,
        );
      }
    });

    Map<String, Map> rawQualities = (factorioRawData['quality'] as Map).cast();
    rawQualities.forEach((name, qualityJson) {
      try {
        if (qualityJson['hidden'] != true) {
          qualities[name] = Quality.fromJson(this, qualityJson);
        }
      } catch (e, st) {
        throw FactorioException.withCause(
          'Encountered error when decoding quality $name',
          e,
          st,
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
    qualityMap = Map.unmodifiable(qualities);
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
      } catch (e, st) {
        throw FactorioException.withCause(
          'Encountered exception when building relationships for recipe $name',
          e,
          st,
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
      } catch (e, st) {
        throw FactorioException.withCause(
          'Encountered error when building relationships for crafting machine $name',
          e,
          st,
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
      } catch (e, st) {
        throw FactorioException.withCause(
          'Encountered error when building relationships for item $name',
          e,
          st,
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
