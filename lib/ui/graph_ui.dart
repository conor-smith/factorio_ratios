import 'dart:io';

import 'package:factorio_ratios/factorio/json.dart';
import 'package:factorio_ratios/factorio/models.dart';
import 'package:factorio_ratios/factorio/production_line.dart';
import 'package:flutter/material.dart';

class GraphUi extends StatefulWidget {
  const GraphUi({super.key});

  @override
  State<GraphUi> createState() => _GraphUiState();
}

class _GraphUiState extends State<GraphUi> {
  Future<FactorioDatabase> _dbFuture = File(
    'test_resources/data-raw-dump.json',
  ).readAsString().then((rawJson) => decodeRawDataDumpJson(rawJson));
  PlanetaryBase _base = PlanetaryBase();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder(
        future: _dbFuture,
        builder: (context, dbSnapshot) {
          if (dbSnapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else {
            return const Text('Hello!');
          }
        },
      ),
    );
  }
}
