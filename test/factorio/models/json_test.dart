import 'dart:io';

import 'package:factorio_ratios/factorio/models/json.dart';
import 'package:factorio_ratios/factorio/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

void main() {
  Logger.root.onRecord.listen((event) =>
    print('${event.level.name}: ${event.time}: ${event.loggerName}: ${event.message}')
  );

  test('Test JSON decoding against space age raw data', () async {
    File jsonFile = File('test_resources/data-raw-dump.json');
    String rawJson = await jsonFile.readAsString();
    FactorioDatabase db = decodeRawDataDumpJson(rawJson);

    expect(db, anything);
  });
}