part of 'data_dump.dart';

class DDSurface extends DDPrototypeWithIcon {
  final Map<String, double>? surfaceProperties;

  DDSurface.fromJson(Map json)
    : surfaceProperties = _parseStringDoubleMap(json['surface_properties']),
      super.fromJson(json, ExpectedIconSize.other);
}
