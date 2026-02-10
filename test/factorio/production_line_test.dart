import 'dart:io';

import 'package:factorio_ratios/factorio/models.dart';
import 'package:factorio_ratios/factorio/production_line.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

void main() async {
  Logger.root.onRecord.listen(
    (event) => print(
      '${event.level.name}: ${event.time}: ${event.loggerName}: ${event.message}',
    ),
  );

  File jsonFile = File('test_resources/data-raw-dump.json');
  String rawJson = await jsonFile.readAsString();
  FactorioDatabase db = FactorioDatabase.fromJson(rawJson);

  test('Test PlanetaryBase for adding one item', () {
    PlanetaryBase base = PlanetaryBase();

    base.createOutputNode(ItemData(db.itemMap['automation-science-pack']!));

    expect(base.nodes.length, 2);
  });
}