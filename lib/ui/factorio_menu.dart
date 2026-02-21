import 'package:factorio_ratios/factorio/models.dart';
import 'package:flutter/material.dart';

class FactorioMenuWidget extends StatefulWidget {
  final FactorioDatabase db;

  const FactorioMenuWidget({super.key, required this.db});

  @override
  State<FactorioMenuWidget> createState() => _FactorioMenuWidgetState();
}

class _FactorioMenuWidgetState extends State<FactorioMenuWidget> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class ItemGroup {
  final String group;
  final String icon;
  final List<ItemSubGroup> subgroups;

  ItemGroup(this.group, this.icon, this.subgroups);
}

class ItemSubGroup {
  final String subgroup;
  final List<ItemButton> items;

  ItemSubGroup(this.subgroup, this.items);
}

class ItemButton extends StatelessWidget {
  final Item item;

  const ItemButton({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
