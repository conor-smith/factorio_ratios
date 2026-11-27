part of 'data_dump.dart';

class SurfaceJson extends PrototypeWithIconJson {
  final Map<String, double>? surfaceProperties;

  SurfaceJson._({
    required super.name,
    required super.type,
    required super.order,
    required super.localisedName,
    required super.subgroupName,
    required super.icon,
    required Map<String, double>? surfaceProperties,
  }) : surfaceProperties = _unmodifiableOrNullMap(surfaceProperties),
       super._();

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
