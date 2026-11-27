part of 'data_dump.dart';

class ItemGroupJson with PrototypeImpl implements PrototypeWithIconJson {
  @override
  final String name;
  @override
  final String type;
  @override
  final String order;
  @override
  final dynamic localisedName;
  @override
  final Icon? icon;

  @override
  String? get subgroupName => null;

  ItemGroupJson._({
    required this.name,
    required this.type,
    required String? order,
    required dynamic localisedName,
    required this.icon,
  }) : order = order ?? PrototypeJson._defaultOrder,
       localisedName = _unmodifiableLocalisedString(localisedName);

  ItemGroupJson.fromJson(Map json)
    : this._(
        name: json['name'],
        type: json['type'],
        order: json['order'],
        localisedName: json['localised_name'],
        icon: Icon.fromTopLevelJson(json, ExpectedIconSize.itemGroup),
      );
}
