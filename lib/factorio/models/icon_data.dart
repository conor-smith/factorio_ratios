part of '../models.dart';

class IconData {
  final String icon;
  final double iconSize;
  final IconTint tint;
  final Vector shift;
  final double scale;
  final bool floating;

  const IconData._({
    required this.icon,
    required this.iconSize,
    required this.tint,
    required this.shift,
    required this.scale,
    required this.floating,
  });

  factory IconData.fromJson(Map json, double expectedIconSize) {
    double iconSize = json['icon_size']?.toDouble() ?? 64;
    // default scale is 0.5 for icons
    double scale = json['scale'] ?? (expectedIconSize / 2) / iconSize;

    IconTint tint = json['tint'] != null
        ? IconTint.fromJson(json['tint'])
        : IconTint.defaultIconTint;
    Vector shift = json['shift'] != null
        ? Vector.fromJson(json['shift'])
        : Vector.defaultVector;

    return IconData._(
      icon: json['icon'],
      iconSize: iconSize,
      tint: tint,
      shift: shift,
      scale: scale,
      floating: json['floating'] ?? false,
    );
  }

  factory IconData._fromSingleIcon(
    String path,
    double expectedIconSize,
    double iconSize,
  ) => IconData._(
    icon: path,
    iconSize: iconSize,
    tint: IconTint.defaultIconTint,
    shift: Vector.defaultVector,
    scale: (expectedIconSize / 2) / iconSize,
    floating: false,
  );

  factory IconData.unknownIcon(double expectedIconSize) => IconData._(
    icon: '__core__/graphics/icons/unknown.png',
    iconSize: 64,
    tint: IconTint.defaultIconTint,
    shift: Vector.defaultVector,
    scale: (expectedIconSize / 2) / 64,
    floating: false,
  );

  static List<IconData>? fromTopLevelJson(Map json, double expectedIconSize) {
    String? icon = json['icon'];
    List<Map>? iconsJson = (json['icons'] as List?)?.cast();

    if (icon != null) {
      return List.unmodifiable([
        IconData._fromSingleIcon(
          icon,
          expectedIconSize,
          json['icon_size']?.toDouble() ?? 64,
        ),
      ]);
    } else if (iconsJson != null) {
      bool isFirst = true;
      List<IconData> iconDataList = [];

      for (var iconDataJson in iconsJson) {
        iconDataList.add(IconData.fromJson(iconDataJson, expectedIconSize));
        isFirst = false;
      }

      return List.unmodifiable(iconDataList);
    } else {
      return null;
    }
  }
}

class IconTint {
  final double r;
  final double g;
  final double b;
  final double a;

  static const IconTint defaultIconTint = IconTint._(r: 0, g: 0, b: 0, a: 1);

  const IconTint._({
    required this.r,
    required this.g,
    required this.b,
    required this.a,
  });

  factory IconTint.fromJson(dynamic json) {
    if (json is Map) {
      return IconTint._(
        r: json['r']?.toDouble() ?? 0,
        g: json['g']?.toDouble() ?? 0,
        b: json['b']?.toDouble() ?? 0,
        a: json['a']?.toDouble() ?? 1,
      );
    } else {
      List jsonList = json as List;

      double alpha = jsonList.length == 4 ? jsonList[3].toDouble() : 1;

      return IconTint._(
        r: jsonList[0].toDouble(),
        g: jsonList[1].toDouble(),
        b: jsonList[2].toDouble(),
        a: alpha,
      );
    }
  }
}

class Vector {
  final double x;
  final double y;

  static const defaultVector = Vector._(x: 0, y: 0);

  const Vector._({required this.x, required this.y});

  factory Vector.fromJson(dynamic json) {
    if (json is Map) {
      return Vector._(
        x: json['x']?.toDouble() ?? 0,
        y: json['y']?.toDouble() ?? 0,
      );
    } else {
      List jsonList = json as List;

      return Vector._(x: jsonList[0].toDouble(), y: jsonList[1].toDouble());
    }
  }

  @override
  bool operator ==(Object other) {
    return other is Vector && other.x == x && other.y == y;
  }
}
