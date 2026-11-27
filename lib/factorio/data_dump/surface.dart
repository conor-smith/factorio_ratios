part of 'data_dump.dart';

class SurfaceJson extends PrototypeWithIconJson {
  @override
  final String name;
  @override
  final String type;
  @override
  final String order;
  @override
  final String? subgroupName;
  @override
  final dynamic localisedName;
  @override
  final Icon? icon;

  final Map<String, double>? surfaceProperties;

  SurfaceJson._({
    required this.name,
    required this.type,
    required String? order,
    required this.subgroupName,
    required dynamic localisedName,
    required this.icon,
    required Map<String, double>? surfaceProperties,
  }) : order = order ?? PrototypeJson._defaultOrder,
       localisedName = _unmodifiableLocalisedString(localisedName),
       surfaceProperties = _unmodifiableOrNullMap(surfaceProperties);

  SurfaceJson.fromJson(Map json)
    : this._(
        name: json['name'],
        type: json['type'],
        order: json['order'],
        subgroupName: json['subgroup'],
        localisedName: json['localised_name'],
        icon: Icon.fromTopLevelJson(json, ExpectedIconSize.other),
        surfaceProperties: _parseStringDoubleMap(json['surface_properties']),
      );
}
