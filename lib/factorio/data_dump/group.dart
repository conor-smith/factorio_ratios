part of 'data_dump.dart';

class DDItemGroup extends DDPrototypeWithIcon {
  DDItemGroup._({
    required super.name,
    required super.type,
    required super.localisedName,
    required super.order,
    required super.icon,
  }) : super(subgroupName: null);

  factory DDItemGroup.fromJson(Map json) => DDItemGroup._(
    name: json['name'],
    type: json['type'],
    order: json['order'],
    localisedName: json['localised_name'],
    icon: Icon.fromTopLevelJson(json, ExpectedIconSize.itemGroup),
  );
}
