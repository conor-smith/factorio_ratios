import 'dart:collection';

import 'package:factorio_ratios/factorio/models.dart';
import 'package:factorio_ratios/ui/icon_widgets.dart';
import 'package:flutter/material.dart';

class FactorioGroupMenuWidget<T extends OrderedWithSubgroup>
    extends StatefulWidget {
  final List<T> items;
  final Function(T item) onSelected;
  // TODO - Set bounds on these values
  final double width;
  final double height;

  const FactorioGroupMenuWidget({
    super.key,
    required this.items,
    required this.onSelected,
    this.height = 1000,
    this.width = 1000,
  });

  @override
  State<FactorioGroupMenuWidget> createState() =>
      _FactorioGroupMenuWidgetState<T>();
}

class _FactorioGroupMenuWidgetState<T extends OrderedWithSubgroup>
    extends State<FactorioGroupMenuWidget<T>> {
  final Map<ItemGroup?, Widget> itemGroupWidgets = {};
  final List<Widget> itemGroupButtons = [];

  ItemGroup? selectedGroup;

  @override
  void initState() {
    super.initState();

    var sortedGroupMap = _groupAndSortItems(widget.items);

    selectedGroup = sortedGroupMap.keys.first;

    sortedGroupMap.forEach((group, subgroups) {
      itemGroupButtons.add(
        Container(
          decoration: BoxDecoration(border: Border.all()),
          constraints: BoxConstraints(
            minWidth: 128,
            minHeight: 128,
            maxHeight: 128,
          ),
          child: TextButton(
            onPressed: () => setState(() {
              selectedGroup = group;
            }),
            child: Center(child: Text(group?.name ?? 'null')),
          ),
        ),
      );

      itemGroupWidgets[group] = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: subgroups.values
            .map(
              (items) => Row(
                children: items
                    .map(
                      (item) => TextButton(
                        onPressed: () => widget.onSelected(item),
                        child: Container(
                          decoration: BoxDecoration(border: Border.all()),
                          width: 64,
                          height: 64,
                          child: Tooltip(
                            message: item.name,
                            child: getIcon(item, 64),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            )
            .toList(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
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
            child: itemGroupWidgets[selectedGroup]!,
          ),
        ),
      ],
    );
  }

  Map<ItemGroup?, Map<ItemSubgroup?, List<T>>> _groupAndSortItems(
    List<T> items,
  ) {
    Map<ItemGroup?, Map<ItemSubgroup?, List<T>>> groupMap = {};

    for (var item in widget.items) {
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

      LinkedHashMap<ItemSubgroup?, List<T>> sortedMap =
          LinkedHashMap.fromEntries(subgroupSortedEntries);
      sortedMap.updateAll((subgroup, items) => items..sort());

      return sortedMap;
    });

    return sortedGroupMap;
  }
}
