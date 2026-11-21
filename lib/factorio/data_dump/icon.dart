part of 'data_dump.dart';

class Icon {
  final List<IconData> icons;
  final double size;

  Icon._(Iterable<IconData> icons, this.size)
    : icons = List.unmodifiableOf(icons);

  static Icon? fromTopLevelJson(Map json, double expectedSize) {
    String? icon = json['icon'];
    List<Map>? iconsJson = (json['icons'] as List?)?.cast();

    if (icon != null) {
      return Icon._([
        IconData._fromSingleIcon(
          icon,
          expectedSize,
          json['icon_size']?.toDouble(),
        ),
      ], expectedSize);
    } else if (iconsJson != null) {
      return Icon._(
        iconsJson.map(
          (iconDataJson) => IconData.fromJson(iconDataJson, expectedSize),
        ),
        expectedSize,
      );
    } else {
      return null;
    }
  }
}

class IconData {
  final String icon;
  final double iconSize;
  final Colour tint;
  final Vector shift;
  final double scale;
  final bool floating;

  IconData._({
    required this.icon,
    required double expectedIconSize,
    required double? iconSize,
    Colour? tint,
    Vector? shift,
    double? scale,
    bool? floating,
  }) : iconSize = iconSize ?? ExpectedIconSize.other,
       tint = tint ?? const Colour._(r: 1, g: 1, b: 1, a: 1),
       shift = shift ?? const Vector._(x: 0, y: 0),
       scale =
           scale ??
           (expectedIconSize / 2) / (iconSize ?? ExpectedIconSize.other),
       floating = floating ?? false;

  factory IconData.fromJson(Map json, double expectedSize) {
    var tintJson = json['tint'];
    Colour? tint = tintJson != null ? Colour.fromJson(tintJson) : null;

    var shiftJson = json['shift'];
    Vector? shift = shiftJson != null ? Vector.fromJson(shiftJson) : null;

    return IconData._(
      icon: json['icon'],
      iconSize: json['icon_size'],
      expectedIconSize: expectedSize,
      tint: tint,
      shift: shift,
      scale: json['scale'],
      floating: json['floating'],
    );
  }

  factory IconData._fromSingleIcon(
    String path,
    double expectedSize,
    double iconSize,
  ) => IconData._(
    icon: path,
    iconSize: iconSize,
    expectedIconSize: expectedSize,
  );
}

class Colour {
  final double r;
  final double g;
  final double b;
  final double a;

  const Colour._({
    required this.r,
    required this.g,
    required this.b,
    required this.a,
  });

  factory Colour.fromJson(dynamic json) {
    double r, g, b, a;

    if (json is Map) {
      r = json['r']?.toDouble() ?? 0;
      g = json['g']?.toDouble() ?? 0;
      b = json['b']?.toDouble() ?? 0;
      a = json['a']?.toDouble() ?? 1;
    } else {
      List jsonList = json as List;
      r = jsonList[0].toDouble();
      g = jsonList[1].toDouble();
      b = jsonList[2].toDouble();
      a = jsonList.length == 4 ? jsonList[3].toDouble() : 1;
    }

    if (r > 1 || g > 1 || b > 1 || a > 1) {
      r /= 255;
      g /= 255;
      b /= 255;
      a /= 255;
    }

    return Colour._(r: r, g: g, b: b, a: a);
  }
}

class Vector {
  final double x;
  final double y;

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
}

abstract final class ExpectedIconSize {
  static const double starMapIcon = 512;
  static const double technology = 256;
  static const double achievement = 128;
  static const double itemGroup = 128;
  static const double other = 64;
  static const double smallIcon = 32;
}
