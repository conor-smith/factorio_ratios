import 'dart:io';

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
  late PlanetaryBase _base = PlanetaryBase();

  final List<BaseNodeWidget> baseNodes = [];

  @override
  void initState() {
    super.initState();

    _dbFuture = File('test_resources/data-raw-dump.json')
        .readAsString()
        .then((rawJson) => FactorioDatabase.fromJson(rawJson))
        .then((db) {
          _db = db;
          _base = PlanetaryBase();
          
          _base.addOutputNode(
            ItemData(_db.itemMap['automation-science-pack']!),
          );
          double y = 50;
          for (var node in _base.nodes) {
            baseNodes.add(BaseNodeWidget(initialX: 50, initialY: y));
            y += 120;
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _dbFuture,
      builder: (context, snapShot) {
        if (snapShot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else {
          return GestureDetector(child: Stack(children: baseNodes));
        }
      },
    );
  }
}

class BaseNodeWidget extends StatefulWidget {
  final double initialX;
  final double initialY;

  const BaseNodeWidget({
    super.key,
    required this.initialX,
    required this.initialY,
  });

  @override
  State<BaseNodeWidget> createState() => _BaseNodeWidgetState();
}

class _BaseNodeWidgetState extends State<BaseNodeWidget> {
  double x = 0;
  double y = 0;

  Widget thisWidget = Container(
    width: 100,
    height: 100,
    decoration: BoxDecoration(
      color: Colors.blueGrey,
      border: Border.all(width: 2),
    ),
    child: Center(child: const Text('Test')),
  );

  @override
  void initState() {
    super.initState();

    x = widget.initialX;
    y = widget.initialY;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x,
      top: y,
      child: Draggable(
        feedback: thisWidget,
        onDragEnd: (details) {
          setState(() {
            x += details.offset.dx;
            y += details.offset.dy;
          });
        },
        child: thisWidget,
      ),
    );
  }
}
