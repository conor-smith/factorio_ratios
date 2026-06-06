import 'dart:io';

import 'package:factorio_ratios/factorio/old_base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/models/models.dart';
import 'package:factorio_ratios/ui/graph/factorio_base_widget.dart';
import 'package:flutter/material.dart';

void main() {
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

  const FactorioRatiosApp({super.key, required this.factorioDb});

  @override
  Widget build(BuildContext context) {
    return FactorioBaseWidget(base: BasePlanner(factorioDb));
  }
}
