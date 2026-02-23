part of '../models.dart';

class IconData {
  final String? icon;
  final double iconSize;
  final IconTint tint;
  final Vector shift;
  final double scale;
  final bool drawBackground;
  final bool floating;

  IconData._({
    required this.icon,
    required this.iconSize,
    required this.tint,
    required this.shift,
    required this.scale,
    required this.drawBackground,
    required this.floating,
  });

  factory IconData.fromJson(Map json, double expectedIconSize, bool isFirst) {
    double iconSize = json['icon_size']?.toDouble() ?? 64;
    double scale = (expectedIconSize / 2) / iconSize;

    return IconData._(
      icon: json['icon'],
      iconSize: iconSize,
      tint: IconTint.fromJson(json['tint'] ?? const {}),
      shift: Vector.fromJson(json['shift'] ?? const {}),
      scale: scale,
      drawBackground: json['draw_background'] ?? isFirst,
      floating: json['floating'] ?? false,
    );
  }

  static List<IconData>? fromTopLevelJson(Map json, double expectedIconSize) {
    String? icon = json['icon'];
    List<Map>? iconsJson = (json['icons'] as List?)?.cast();

    if (icon != null) {
      return List.unmodifiable([
        IconData.fromJson(
          {'icon': icon, 'icon_size': json['icon_size'] ?? 64},
          expectedIconSize,
          true,
        ),
      ]);
    } else if (iconsJson != null) {
      bool isFirst = true;
      List<IconData> iconDataList = [];

      for (var iconDataJson in iconsJson) {
        iconDataList.add(
          IconData.fromJson(iconDataJson, expectedIconSize, isFirst),
        );
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

  IconTint._({
    required this.r,
    required this.g,
    required this.b,
    required this.a,
  });

  factory IconTint.fromJson(Map json) {
    return IconTint._(
      r: json['r']?.toDouble() ?? 0,
      g: json['g']?.toDouble() ?? 0,
      b: json['b']?.toDouble() ?? 0,
      a: json['a']?.toDouble() ?? 1,
    );
  }
}

class Vector {
  final double x;
  final double y;

  Vector._({required this.x, required this.y});

  factory Vector.fromJson(Map json) {
    return Vector._(
      x: json['x']?.toDouble() ?? 0,
      y: json['y']?.toDouble() ?? 0,
    );
  }
}
