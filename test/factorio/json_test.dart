import 'dart:io';

import 'package:factorio_ratios/factorio/json.dart';
import 'package:factorio_ratios/factorio/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

Logger _logger = Logger('Test');

void main() {
  Logger.root.onRecord.listen((event) =>
    print('${event.level.name}: ${event.time}: ${event.loggerName}: ${event.message}')
  );

  test('Test JSON decoding against space age raw data', () async {
    File jsonFile = File('test_resources/data-raw-dump.json');
    String rawJson = await jsonFile.readAsString();
    FactorioDatabase db = decodeRawDataDumpJson(rawJson);

    db.itemMap.forEach((name, item) {
      if(item is SolidItem) {
        _logger.info('Testing lazy relationships for item $name');
        _logger.info('Item $name has burn result ${item.burntResult?.name ?? 'empty'}');
        _logger.info('Item $name has spoil result ${item.spoiledResult?.name ?? 'empty'}');
      }
    });

    db.recipeMap.forEach((name, recipe) {
      _logger.info('Testing lazy relationships on recipe $name');
      _logger.info('Recipe $name is craftable on the following machines - ${recipe.craftingMachines.map((machine) => machine.name)}');
    });

    db.craftingMachineMap.forEach((name, machine) {
      _logger.info('Testing lazy relationships on machine $name');
      _logger.info('Machine can craft the following recipes - ${machine.recipes.map((recipe) => recipe.name)}');
    });

    expect(db, anything);
  });
}