import 'dart:collection';

import 'package:factorio_ratios/factorio/models.dart';
import 'package:factorio_ratios/ui/icon_widgets.dart';
import 'package:flutter/material.dart';

class FactorioGroupMenuWidget<T extends OrderedWithSubgroup>
    extends StatefulWidget {
  final Function(T item) onSelected;

  final Map<ItemGroup?, Map<ItemSubgroup?, List<T>>> sortedItems;

  FactorioGroupMenuWidget({
    super.key,
    required List<T> items,
    required this.onSelected,
  }) : sortedItems = _groupAndSortItems(items);

  @override
  State<FactorioGroupMenuWidget> createState() =>
      _FactorioGroupMenuWidgetState<T>();
}

class _FactorioGroupMenuWidgetState<T extends OrderedWithSubgroup>
    extends State<FactorioGroupMenuWidget<T>> {
  ItemGroup? selectedGroup;

  @override
  void initState() {
    super.initState();
    selectedGroup = widget.sortedItems.keys.first;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> itemGroupButtons = widget.sortedItems.keys
        .map(
          (itemGroup) => Container(
            decoration: BoxDecoration(border: Border.all()),
            constraints: BoxConstraints(
              minWidth: 128,
              minHeight: 128,
              maxHeight: 128,
            ),
            child: TextButton(
              onPressed: () => setState(() {
                selectedGroup = itemGroup;
              }),
              child: Center(child: Text(itemGroup?.name ?? 'null')),
            ),
          ),
        )
        .toList();

    List<Widget> subgroups = widget.sortedItems[selectedGroup]!.entries
        .map(
          (entry) => Row(
            children: entry.value
                .map(
                  (item) => TextButton(
                    onPressed: () => widget.onSelected(item),
                    child: Tooltip(
                      message: item.name,
                      child: FactorioIconWidget(icon: item, size: 64),
                    ),
                  ),
                )
                .toList(),
          ),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: itemGroupButtons),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: subgroups,
            ),
          ),
        ),
      ],
    );
  }
}

Map<ItemGroup?, Map<ItemSubgroup?, List<T>>>
_groupAndSortItems<T extends OrderedWithSubgroup>(List<T> items) {
  Map<ItemGroup?, Map<ItemSubgroup?, List<T>>> groupMap = {};

  for (var item in items) {
    groupMap.update(
      item.subgroup?.group,
      (subgroupMap) => subgroupMap
        ..update(
          item.subgroup,
          (itemList) => itemList..add(item),
          ifAbsent: () => [item],
        ),
      ifAbsent: () => {
        item.subgroup: [item],
      },
    );
  }

  var groupSortedEntries = groupMap.entries.toList();
  groupSortedEntries.sort((entry1, entry2) {
    if (entry1.key == null) {
      return 1;
    } else if (entry2.key == null) {
      return -1;
    } else {
      return entry1.key!.compareTo(entry2.key!);
    }
  });

  var sortedGroupMap = LinkedHashMap.fromEntries(groupSortedEntries);

  sortedGroupMap.updateAll((group, subgroupMap) {
    var subgroupSortedEntries = subgroupMap.entries.toList();
    subgroupSortedEntries.sort((entry1, entry2) {
      if (entry1.key == null) {
        return 1;
      } else if (entry2.key == null) {
        return -1;
      } else {
        return entry1.key!.compareTo(entry2.key!);
      }
    });

    LinkedHashMap<ItemSubgroup?, List<T>> sortedMap = LinkedHashMap.fromEntries(
      subgroupSortedEntries,
    );
    sortedMap.updateAll((subgroup, items) => items..sort());

    return sortedMap;
  });

  return sortedGroupMap;
}
