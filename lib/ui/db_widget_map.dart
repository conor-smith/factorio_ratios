import 'package:factorio_ratios/factorio/models.dart';
import 'package:flutter/material.dart';

class FactorioWidgetMap {
  final FactorioDatabase factorioDb;
  final Map<OrderedWithSubgroup, Widget> widgets = {};

  FactorioWidgetMap(this.factorioDb);

  Widget operator [](OrderedWithSubgroup item) => widgets.putIfAbsent(
    item,
    () => SizedBox(width: 64, height: 64, child: Tooltip(message: item.name)),
  );
}
