part of 'models.dart';

class Icon {
  final List<IconData> icons;

  @override
  final int hashCode;

  Icon._(Iterable<IconData> icons)
    : icons = List.unmodifiable(icons),
      hashCode = icons
          .map((iconData) => iconData.hashCode)
          .reduce((code1, code2) => code1 + code2);

  factory Icon.withQuality(Icon icon, int quality) {
    // TODO
    return icon;
  }

  static Icon? fromTopLevelJson(Map json, double expectedIconSize) {
    String? icon = json['icon'];
    List<Map>? iconsJson = (json['icons'] as List?)?.cast();

    if (icon != null) {
      return Icon._([
        IconData._fromSingleIcon(
          icon,
          expectedIconSize,
          json['icon_size']?.toDouble() ?? 64,
        ),
      ]);
    } else if (iconsJson != null) {
      return Icon._(
        iconsJson.map(
          (iconDataJson) => IconData.fromJson(iconDataJson, expectedIconSize),
        ),
      );
    } else {
      return null;
    }
  }

  @override
  bool operator ==(Object other) {
    if (super == other) {
      return true;
    }

    if (other is Icon && other.icons.length == icons.length) {
      for (var i = 0; i < icons.length; i++) {
        if (icons[i] != other.icons[i]) {
          return false;
        }
      }
      return true;
    }

    return false;
  }
}

class IconData {
  final String icon;
  final double iconSize;
  final IconTint tint;
  final Vector shift;
  final double scale;
  final bool floating;

  @override
  final int hashCode;

  IconData._({
    required this.icon,
    required this.iconSize,
    required this.tint,
    required this.shift,
    required this.scale,
    required this.floating,
  }) : hashCode =
           icon.hashCode +
           iconSize.floor() +
           tint.hashCode +
           shift.hashCode +
           scale.floor() +
           floating.hashCode;

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

  @override
  bool operator ==(Object other) =>
      super == other ||
      (other is IconData &&
          icon == other.icon &&
          iconSize == other.iconSize &&
          tint == other.tint &&
          shift == other.shift &&
          scale == other.scale &&
          floating == other.floating);
}

class IconTint {
  static const defaultIconTint = IconTint._empty();

  final double r;
  final double g;
  final double b;
  final double a;

  @override
  final int hashCode;

  IconTint._(this.r, this.g, this.b, this.a)
    : hashCode =
          (r * 100).floor() +
          (g * 100).floor() * 100 +
          (b * 100).floor() * 10000 +
          (a * 100).floor() * 1000000;

  const IconTint._empty() : r = 1, g = 1, b = 1, a = 1, hashCode = 99999999;

  factory IconTint.fromJson(dynamic json) {
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

    return IconTint._(r, g, b, a);
  }

  @override
  bool operator ==(Object other) {
    return super == other ||
        (other is IconTint &&
            r == other.r &&
            g == other.g &&
            b == other.b &&
            a == other.a);
  }
}

class Vector {
  static const defaultVector = Vector._empty();

  final double x;
  final double y;

  @override
  final int hashCode;

  Vector._({required this.x, required this.y})
    : hashCode = x.floor() + y.floor() * 100000;

  const Vector._empty() : x = 0, y = 0, hashCode = 0;

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
  bool operator ==(Object other) =>
      super == other || (other is Vector && x == other.x && y == other.y);
}
