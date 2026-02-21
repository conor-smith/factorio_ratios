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
      String machineList = recipe.craftingMachines.isEmpty
          ? 'None'
          : recipe.craftingMachines
                .map((machine) => machine.name)
                .fold('', (name1, name2) => '$name1, $name2');
      _logger.info(
        'Recipe $name is craftable on the following machines - $machineList',
      );
    });

    db.craftingMachineMap.forEach((name, machine) {
      _logger.info('Testing lazy relationships on machine $name');
      String recipeList = machine.recipes.isEmpty
          ? 'None'
          : machine.recipes
                .map((recipe) => recipe.name)
                .fold('', (name1, name2) => '$name1, $name2');
      _logger.info('Machine can craft the following recipes - $recipeList');
    });

    db.itemGroupMap.forEach((name, group) {
      _logger.info('Testing lazy relationships on group $name');
      String subgroupList = group.subgroups.isEmpty
          ? 'None'
          : group.subgroups
                .map((subGroup) => subGroup.name)
                .fold('', (name1, name2) => '$name1, $name2');
      _logger.info('Group has the following subgroups - $subgroupList');
    });

    db.itemSubgroupMap.forEach((name, subgroup) {
      _logger.info('Testing lazy relationships on subgroup $name');
      String itemList = subgroup.items.isEmpty
          ? 'None'
          : subgroup.items
                .map((item) => item.name)
                .fold('', (name1, name2) => '$name1, $name2');
      String recipeList = subgroup.recipes.isEmpty
          ? 'None'
          : subgroup.recipes
                .map((recipe) => recipe.name)
                .fold('', (name1, name2) => '$name1, $name2');
      _logger.info('subgroup has the following items - $itemList');
      _logger.info('subgroup has the following recipes - $recipeList');
    });

    expect(db, anything);
  });
}
