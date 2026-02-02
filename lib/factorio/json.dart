import 'dart:convert';

import 'package:factorio_ratios/factorio/models.dart';
import 'package:logging/logging.dart';

final _logger = Logger('DecodeFactorioJson');

// TODO - Add structure verification
FactorioDatabase decodeRawDataDumpJson(String rawJson) {
  FactorioDatabase db = FactorioDatabase();

  _logger.info('Decoding raw data dump');
  Map factorioRawData = jsonDecode(rawJson);

  Map<String, Item> items = {};
  Map<String, Recipe> recipes = {};
  Map<String, CraftingMachine> craftingMachines = {};

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
  ];
  List<String> machineSections = [
    'assembling-machine',
    'rocket-silo',
    'furnace'
  ];

  Map<String, Map> rawItems = {};
  for (var section in itemSections) {
    rawItems.addAll((factorioRawData[section] as Map).cast());
  }

  rawItems.forEach((name, itemJson) {
    if (itemJson['parameter'] != true) {
      _logger.info('decoding item $name');

      items[name] = SolidItem.fromJson(db, itemJson);
    }
  });

  Map<String, Map> rawFluids = (factorioRawData['fluid'] as Map).cast();
  rawFluids.forEach((name, fluidJson) {
    if (fluidJson['parameter'] != true) {
      _logger.info('decoding fluid $name');

      items[name] = FluidItem.fromJson(db, fluidJson);
    }
  });

  _logger.info('decoding recipes');
  Map<String, Map> rawRecipes = (factorioRawData['recipe'] as Map).cast();
  rawRecipes.forEach((name, recipeJson) {
    if (recipeJson['parameter'] != true) {
      _logger.info('decoding recipe $name');

      recipes[name] = Recipe.fromJson(db, recipeJson);
    }
  });

  _logger.info('decoding machines');
  Map<String, Map> rawCraftingMachines = {};
  for(var machineSection in machineSections) {
    rawCraftingMachines.addAll((factorioRawData[machineSection] as Map).cast());
  }
  rawCraftingMachines.forEach((name, machineJson) {
    _logger.info('decoding crafting machine $name');

    craftingMachines[name] = CraftingMachine.fromJson(db, machineJson);
  });

  db.initialise(items, recipes, craftingMachines);
  return db;
}
