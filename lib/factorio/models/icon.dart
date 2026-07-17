part of 'models.dart';

class Icon {
  final List<IconData> icons;
  final double size;

  @override
  final int hashCode;

  Icon._(Iterable<IconData> icons, this.size)
    : icons = List.unmodifiable(icons),
      hashCode =
          icons.fold(0, (sum, iconData) => sum + iconData.hashCode) +
          size.hashCode;

  factory Icon.withQuality(Icon icon, int quality) {
    // TODO
    return icon;
  }

  Icon.unknownIcon(ExpectedIconSize expectedSize)
    : this._([
        IconData._(
          icon: '__core__/graphics/icons/unknown.png',
          iconSize: ExpectedIconSize.other.size,
          tint: IconTint.defaultIconTint,
          shift: Vector.defaultVector,
          scale: (expectedSize.size / 2) / ExpectedIconSize.other.size,
          floating: false,
        ),
      ], ExpectedIconSize.other.size);

  static Icon? fromTopLevelJson(Map json, ExpectedIconSize expectedSize) {
    String? icon = json['icon'];
    List<Map>? iconsJson = (json['icons'] as List?)?.cast();

    if (icon != null) {
      return Icon._([
        IconData._fromSingleIcon(
          icon,
          expectedSize,
          json['icon_size']?.toDouble() ?? expectedSize.size,
        ),
      ], expectedSize.size);
    } else if (iconsJson != null) {
      return Icon._(
        iconsJson.map(
          (iconDataJson) => IconData.fromJson(iconDataJson, expectedSize),
        ),
        expectedSize.size,
      );
    } else {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      super == other || (other is Icon && compareLists(other.icons, icons));
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
           iconSize.hashCode +
           tint.hashCode +
           shift.hashCode +
           scale.hashCode +
           floating.hashCode;

  factory IconData.fromJson(Map json, ExpectedIconSize expectedSize) {
    double iconSize =
        json['icon_size']?.toDouble() ?? ExpectedIconSize.other.size;
    // default scale is 0.5 for most icons
    double scale = json['scale'] ?? (expectedSize.size / 2) / iconSize;

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
    ExpectedIconSize expectedSize,
    double iconSize,
  ) => IconData._(
    icon: path,
    iconSize: iconSize,
    tint: IconTint.defaultIconTint,
    shift: Vector.defaultVector,
    scale: (expectedSize.size / 2) / iconSize,
    floating: false,
  );

  factory IconData.unknownIcon(ExpectedIconSize expectedSize) => IconData._(
    icon: '__core__/graphics/icons/unknown.png',
    iconSize: ExpectedIconSize.other.size,
    tint: IconTint.defaultIconTint,
    shift: Vector.defaultVector,
    scale: (expectedSize.size / 2) / ExpectedIconSize.other.size,
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
  static const defaultIconTint = IconTint._(1, 1, 1, 1);

  final double r;
  final double g;
  final double b;
  final double a;

  const IconTint._(this.r, this.g, this.b, this.a);

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
  bool operator ==(Object other) =>
      super == other ||
      (other is IconTint &&
          r == other.r &&
          g == other.g &&
          b == other.b &&
          a == other.a);

  @override
  int get hashCode =>
      r.hashCode +
      (g * 100).hashCode +
      (b * 10000).hashCode +
      (a * 1000000).hashCode;
}

class Vector {
  static const defaultVector = Vector._(x: 0, y: 0);

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

  @override
  bool operator ==(Object other) =>
      super == other || (other is Vector && x == other.x && y == other.y);

  @override
  int get hashCode => x.hashCode + (y * 500).hashCode;
}

enum ExpectedIconSize {
  starmapIcon(512),
  technology(256),
  achievement(128),
  itemGroup(128),
  smallIcon(32),
  other(64);

  final double size;

  const ExpectedIconSize(this.size);
}
