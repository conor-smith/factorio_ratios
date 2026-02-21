import 'dart:io';

import 'package:factorio_ratios/factorio/models.dart';
import 'package:factorio_ratios/ui/factorio_menu.dart';
import 'package:factorio_ratios/ui/graph_ui.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

void main() {
  Logger.root.onRecord.listen(
    (event) => print(
      '${event.level.name}: ${event.time}: ${event.loggerName}: ${event.message}',
    ),
  );

  runApp(FactorioRatiosApp());
}

class FactorioRatiosApp extends StatelessWidget {
  FactorioRatiosApp({super.key});

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
            _ => Center(child: FactorioItemMenuWidget(db: snapShot.data!)),
          },
        ),
      ),
    );
  }
}
