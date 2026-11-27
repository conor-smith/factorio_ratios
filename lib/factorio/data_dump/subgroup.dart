part of 'data_dump.dart';

class ItemSubgroupJson with PrototypeToString implements PrototypeJson {
  @override
  final String name;
  @override
  final String type;
  @override
  final String order;
  @override
  final dynamic localisedName;

  @override
  String? get subgroupName => null;

  final String group;

  ItemSubgroupJson._({
    required this.name,
    required this.type,
    required String? order,
    required dynamic localisedName,
    required this.group,
  }) : order = order ?? PrototypeJson._defaultOrder,
       localisedName = _unmodifiableLocalisedString(localisedName);

  ItemSubgroupJson.fromJson(Map json)
    : this._(
        name: json['name'],
        type: json['type'],
        order: json['order'],
        localisedName: json['localised_name'],
        group: json['group'],
      );
}
