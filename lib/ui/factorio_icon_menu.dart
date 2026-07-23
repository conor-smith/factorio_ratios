import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/factorio/models/models.dart';
import 'package:factorio_ratios/ui/base_planner/base_planner_widget.dart';
import 'package:flutter/material.dart';

class FactorioIconMenuWidget<T extends PrototypeWithIcon>
    extends StatefulWidget {
  final Function(T item) onSelected;

  final SortedItemGroups<T> itemGroups;

  const FactorioIconMenuWidget({
    super.key,
    required this.itemGroups,
    required this.onSelected,
  });

  @override
  State<FactorioIconMenuWidget> createState() =>
      _FactorioIconMenuWidgetState<T>();
}

class _FactorioIconMenuWidgetState<T extends PrototypeWithIcon>
    extends State<FactorioIconMenuWidget<T>> {
  ItemGroup? selectedGroup;

  @override
  void initState() {
    super.initState();
    selectedGroup = widget.itemGroups.groups.first.itemGroup;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> itemGroupButtons = widget.itemGroups.groups
        .map(
          (group) => Container(
            decoration: BoxDecoration(border: Border.all()),
            constraints: BoxConstraints(
              minWidth: 128,
              minHeight: 128,
              maxHeight: 128,
            ),
            child: TextButton(
              onPressed: () => setState(() {
                selectedGroup = group.itemGroup;
              }),
              child: Center(child: Text(group.itemGroup?.name ?? 'null')),
            ),
          ),
        )
        .toList();

    var cache = BasePlannerGlobalState.of(context).iconCache;

    List<Widget> subgroups = widget.itemGroups.groups
        .firstWhere((group) => group.itemGroup == selectedGroup)
        .subgroups
        .map(
          (subgroup) => Row(
            children: subgroup.items
                .map(
                  (item) => TextButton(
                    onPressed: () => widget.onSelected(item),
                    child: Tooltip(
                      message: item.name,
                      child: cache.get(item.icon),
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
