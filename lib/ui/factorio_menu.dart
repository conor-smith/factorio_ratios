import 'dart:collection';

import 'package:factorio_ratios/factorio/models.dart';
import 'package:flutter/material.dart';

class FactorioItemMenuWidget extends StatefulWidget {
  final FactorioDatabase db;

  const FactorioItemMenuWidget({super.key, required this.db});

  @override
  State<FactorioItemMenuWidget> createState() => _FactorioItemMenuWidgetState();
}

class _FactorioItemMenuWidgetState extends State<FactorioItemMenuWidget> {
  late final LinkedHashMap<ItemGroup, ItemGroupWidget> itemGroups;

  late ItemGroup selectedGroup;

  @override
  void initState() {
    super.initState();

    var itemGroupList = widget.db.itemGroupMap.values
        .where(
          (itemGroup) =>
              itemGroup.subgroups.any((subgroup) => subgroup.items.isNotEmpty),
        )
        .toList();
    itemGroupList.sort((group1, group2) {
      var order = group1.order.compareTo(group2.order);
      return order != 0 ? order : group1.name.compareTo(group2.name);
    });

    selectedGroup = itemGroupList.first;

    LinkedHashMap<ItemGroup, ItemGroupWidget> itemGroups = LinkedHashMap();
    for (var itemGroup in itemGroupList) {
      List<ItemSubgroup> subgroupList = List.from(itemGroup.subgroups);
      subgroupList.sort((subgroup1, subgroup2) {
        var order = subgroup1.order.compareTo(subgroup2.order);
        return order != 0 ? order : subgroup1.name.compareTo(subgroup2.name);
      });

      itemGroups[itemGroup] = ItemGroupWidget(itemGroup);
    }

    this.itemGroups = itemGroups;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: itemGroups.keys
              .map(
                (itemGroup) => TextButton(
                  onPressed: () => setState(() {
                    selectedGroup = itemGroup;
                  }),
                  child: Container(
                    height: 128,
                    decoration: BoxDecoration(border: Border.all()),
                    child: Center(child: Text(itemGroup.name)),
                  ),
                ),
              )
              .toList(),
        ),
        itemGroups[selectedGroup]!,
      ],
    );
  }
}

class ItemGroupWidget extends StatelessWidget {
  final List<ItemSubgroupWidget> itemSubGroups;

  const ItemGroupWidget._(this.itemSubGroups);

  factory ItemGroupWidget(ItemGroup itemGroup) {
    List<ItemSubgroup> subgroups = itemGroup.subgroups
        .where((subgroup) => subgroup.items.isNotEmpty)
        .toList();
    subgroups.sort((subgroup1, subgroup2) {
      var order = subgroup1.order.compareTo(subgroup2.order);
      return order != 0 ? order : subgroup1.name.compareTo(subgroup2.name);
    });

    return ItemGroupWidget._(
      subgroups.map((subgroup) => ItemSubgroupWidget(subgroup)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: itemSubGroups);
  }
}

class ItemSubgroupWidget extends StatelessWidget {
  final List<Widget> itemWidgets;

  const ItemSubgroupWidget._(this.itemWidgets);

  factory ItemSubgroupWidget(ItemSubgroup itemSubgroup) {
    List<Item> items = List.from(itemSubgroup.items);
    items.sort((item1, item2) {
      var order = item1.order.compareTo(item2.order);
      return order != 0 ? order : item1.name.compareTo(item2.name);
    });

    return ItemSubgroupWidget._(
      items
          .map(
            (item) => Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
              ),
              width: 68,
              height: 68,
              padding: EdgeInsets.all(2),
              child: Tooltip(message: item.localisedName, child: Container()),
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: itemWidgets);
  }
}
