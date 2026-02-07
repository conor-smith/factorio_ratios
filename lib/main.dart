import 'package:factorio_ratios/ui/graph_ui.dart';
import 'package:flutter/material.dart';

void main() {
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
        body: Center(child: InteractiveViewer(child: GraphUi())),
      ),
    );
  }
}
