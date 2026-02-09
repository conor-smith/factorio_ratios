import 'package:factorio_ratios/ui/graph_ui.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

void main() {
  Logger.root.onRecord.listen(
    (event) => print(
      '${event.level.name}: ${event.time}: ${event.loggerName}: ${event.message}',
    ),
  );

  runApp(const FactorioRatiosApp());
}

class FactorioRatiosApp extends StatelessWidget {
  const FactorioRatiosApp({super.key});

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
        body: GraphUi(),
      ),
    );
  }
}
