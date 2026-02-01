import 'dart:convert';

import 'package:factorio_ratios/factorio/models/models.dart';
import 'package:logging/logging.dart';

final _logger = Logger('DecodeFactorioJson');

// TODO - Add structure verification
FactorioDatabase decodeRawDataDumpJson(String rawJson) {
  _logger.info('Decoding raw data dump');
  Map factorioRawData = jsonDecode(rawJson);

  Map rawItemsMap = factorioRawData['item'];
  Map<String, Item> itemMap = {};
  rawItemsMap.forEach((key, itemJson) {
    if(itemJson['hidden'] == true || itemJson['parameter'] == true) {
      _logger.info('Item $key will not be decoded');
    } else {
      _logger.info('Decoding "$key"');
      itemMap[key] = Item.fromJson(itemJson);
    }
  });

  Map rawRecipeMap = factorioRawData['recipe'];
  List<Recipe> recipeList = [];
  rawRecipeMap.forEach((key, value) {
    if(value['hidden'] == true || value['parameter'] == true) {
      _logger.info('Recipe $key will not be decoded');
    } else {
      _logger.info('Decoding "$key"');
      recipeList.add(Recipe.fromJson(value));
    }
   });

  Map rawCraftingMachineMap = factorioRawData['assembling-machine'];
  List<CraftingMachine> craftingMachineList = [];
  rawCraftingMachineMap.forEach((key, value) {
    _logger.info('Decoding "$key"');
    craftingMachineList.add(CraftingMachine.fromJson(value));
  });

  return FactorioDatabase(itemMap.values.toList(), recipeList, craftingMachineList);
}