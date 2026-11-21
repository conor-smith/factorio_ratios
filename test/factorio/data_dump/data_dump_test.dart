import 'dart:convert';
import 'dart:io';

import 'package:factorio_ratios/factorio/data_dump/data_dump.dart';
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
    Map json = jsonDecode(rawJson);

    var dataDump = DDDatabase.fromJson(json);

    expect(dataDump, anything);
  });
}
