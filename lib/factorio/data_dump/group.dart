part of 'data_dump.dart';

class ItemGroupJson extends PrototypeWithIconJson {
  ItemGroupJson._({
    required super.name,
    required super.type,
    required super.order,
    required super.localisedName,
    required super.icon,
  }) : super._(subgroupName: null);

  ItemGroupJson.fromJson(Map json)
    : this._(
        name: json['name'],
        type: json['type'],
        order: json['order'],
        localisedName: json['localised_name'],
        icon: Icon.fromTopLevelJson(json, ExpectedIconSize.itemGroup),
      );
}
