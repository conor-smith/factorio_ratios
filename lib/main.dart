import 'dart:io';

import 'package:factorio_ratios/factorio/models.dart';
import 'package:factorio_ratios/ui/db_widget_map.dart';
import 'package:factorio_ratios/ui/factorio_menu.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

void main() {
  Logger.root.onRecord.listen(
    (event) => print(
      '${event.level.name}: ${event.time}: ${event.loggerName}: ${event.message}',
    ),
  );

  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  MainApp({super.key});

  final Future<FactorioDatabase> _db = File(
    'test_resources/data-raw-dump.json',
  ).readAsString().then((rawJson) => FactorioDatabase.fromJson(rawJson));

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Factorio Ratios',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Factorio Ratios'),
        ),
        body: FutureBuilder(
          future: _db,
          builder: (context, snapShot) => switch (snapShot.connectionState) {
            ConnectionState.waiting => CircularProgressIndicator(),
            // _ => GraphUi(db: snapShot.data!),
            _ => FactorioRatiosApp(factorioDb: snapShot.data!),
          },
        ),
      ),
    );
  }
}

class FactorioRatiosApp extends StatelessWidget {
  final FactorioDatabase factorioDb;
  final FactorioWidgetMap widgetMap;

  FactorioRatiosApp({super.key, required this.factorioDb})
    : widgetMap = FactorioWidgetMap(factorioDb);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 1024,
        height: 1024,
        child: FactorioGroupMenuWidget<Item>(
          items: factorioDb.itemMap.values.toList(),
          widgetMap: widgetMap,
          onSelected: (item) => print(item),
        ),
      ),
    );
  }
}
