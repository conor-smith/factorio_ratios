import 'dart:io';

import 'package:factorio_ratios/factorio/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

Logger _logger = Logger('Test');

void main() {
  Logger.root.onRecord.listen(
    (event) => print(
      '${event.level.name}: ${event.time}: ${event.loggerName}: ${event.message}',
    ),
  );

  test('Test JSON decoding against space age raw data', () async {
    File jsonFile = File('test_resources/data-raw-dump.json');
    String rawJson = await jsonFile.readAsString();
    FactorioDatabase db = FactorioDatabase.fromJson(rawJson);

    db.itemMap.forEach((name, item) {
      if (item is SolidItem) {
        _logger.info('Testing lazy relationships for item $name');
        _logger.info(
          'Item $name has burn result ${item.burntResult?.name ?? 'empty'}',
        );
        _logger.info(
          'Item $name has spoil result ${item.spoilResult?.name ?? 'empty'}',
        );
      }
    });

    db.recipeMap.forEach((name, recipe) {
      _logger.info('Testing lazy relationships on recipe $name');
      List<String> machineNameList = recipe.craftingMachines
          .map((recipe) => recipe.name)
          .toList();
      machineNameList.sort();

      String machineList = machineNameList.isEmpty
          ? 'None'
          : machineNameList.reduce((name1, name2) => '$name1, $name2');
      _logger.info(
        'Recipe $name is craftable on the following machines - $machineList',
      );
    });

    db.craftingMachineMap.forEach((name, machine) {
      _logger.info('Testing lazy relationships on machine $name');
      List<String> recipeNameList = machine.recipes
          .map((recipe) => recipe.name)
          .toList();
      recipeNameList.sort();

      String recipeList = recipeNameList.isEmpty
          ? 'None'
          : recipeNameList.reduce((name1, name2) => '$name1, $name2');
      _logger.info('Machine can craft the following recipes - $recipeList');
    });

    db.surfaceMap.forEach((name, surface) {
      _logger.info('Testing lazy relationships on surface $name');

      List<String> recipeNameList = surface.recipes
          .map((recipe) => recipe.name)
          .toList();
      recipeNameList.sort();

      String recipeList = recipeNameList.isEmpty
          ? 'None'
          : recipeNameList.reduce((name1, name2) => '$name1, $name2');
      _logger.info(
        'The following recipes are craftable on this surface - $recipeList',
      );
    });

    expect(db, anything);
  });
}
