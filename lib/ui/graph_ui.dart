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
  late Future<Null> _dbFuture;
  late FactorioDatabase _db;
  PlanetaryBase _base = PlanetaryBase();

  @override
  void initState() {
    super.initState();

    _dbFuture = File('test_resources/data-raw-dump.json')
        .readAsString()
        .then((rawJson) => decodeRawDataDumpJson(rawJson))
        .then((db) {
          _db = db;
        });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder(
        future: _dbFuture,
        builder: (context, dbSnapshot) {
          if (dbSnapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else {
            return GestureDetector(
              child: Stack(children: [const Text('Placeholder')]),
              onTap: () => setState(() {}),
            );
          }
        },
      ),
    );
  }
}

class BaseNodeWidget extends StatefulWidget {
  final ProdLineNode prodLineNode;
  final double initialX;
  final double initialY;

  const BaseNodeWidget({
    super.key,
    required this.prodLineNode,
    required this.initialX,
    required this.initialY,
  });

  @override
  State<BaseNodeWidget> createState() => _BaseNodeWidgetState();
}

class _BaseNodeWidgetState extends State<BaseNodeWidget> {
  double x = 0;
  double y = 0;

  @override
  void initState() {
    super.initState();

    x = widget.initialX;
    y = widget.initialY;
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
