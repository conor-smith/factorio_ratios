part of 'data_dump.dart';

class ItemSubgroupJson extends PrototypeJson {
  final String group;

  ItemSubgroupJson._({
    required super.name,
    required super.type,
    required super.order,
    required this.group,
  }) : super._(localisedName: null, subgroupName: null);

  ItemSubgroupJson.fromJson(Map json)
    : this._(
        name: json['name'],
        type: json['type'],
        order: json['order'],
        group: json['group'],
      );
}
