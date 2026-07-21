part of 'dynamic_models.dart';

class SubgroupAndItems<T extends PrototypeWithIcon> {
  final ItemSubgroup? subgroup;
  final List<T> items;

  SubgroupAndItems._(this.subgroup, Iterable<T> items)
    : items = List.unmodifiable(items);
}

class GroupAndSubgroups<T extends PrototypeWithIcon> {
  final ItemGroup? itemGroup;
  final List<SubgroupAndItems<T>> subgroups;

  GroupAndSubgroups._(this.itemGroup, Iterable<SubgroupAndItems<T>> subgroups)
    : subgroups = List.unmodifiable(subgroups);
}

class SortedItemGroups<T extends PrototypeWithIcon> {
  final List<GroupAndSubgroups<T>> groups;

  SortedItemGroups._(List<GroupAndSubgroups<T>> groups)
    : groups = List.unmodifiable(groups);

  factory SortedItemGroups(Iterable<T> items) {
    Map<ItemGroup, Map<ItemSubgroup, Set<T>>> groupMap = {};
    Set<T> ungrouped = {};

    for (var item in items) {
      if (item.subgroup == null) {
        ungrouped.add(item);
      } else {
        groupMap.update(
          item.subgroup!.group,
          (subgroupMap) => subgroupMap
            ..update(
              item.subgroup!,
              (itemSet) => itemSet..add(item),
              ifAbsent: () => {item},
            ),
          ifAbsent: () => {
            item.subgroup!: {item},
          },
        );
      }
    }

    var groupsList =
        groupMap.entries
            .map(
              (groupAndSubgroups) => GroupAndSubgroups._(
                groupAndSubgroups.key,
                groupAndSubgroups.value.entries
                    .map(
                      (subgroupAndItems) => SubgroupAndItems._(
                        subgroupAndItems.key,
                        subgroupAndItems.value.toList()..sort(),
                      ),
                    )
                    .toList()
                  ..sort(
                    (subgroup1, subgroup2) =>
                        subgroup1.subgroup!.compareTo(subgroup2.subgroup!),
                  ),
              ),
            )
            .toList()
          ..sort(
            (group1, group2) => group1.itemGroup!.compareTo(group2.itemGroup!),
          );

    if (ungrouped.isNotEmpty) {
      groupsList.add(
        GroupAndSubgroups._(null, [
          SubgroupAndItems._(null, ungrouped.toList()..sort()),
        ]),
      );
    }

    return SortedItemGroups._(groupsList);
  }
}
