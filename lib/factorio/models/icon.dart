part of 'models.dart';

class Icon {
  final List<IconData> icons;
  final double size;

  @override
  late final int hashCode =
      createHashFromOrderedIterable(icons) + size.hashCode;

  final Map<double, Icon> _cachedSizedIcons;

  static final Map<double, Icon> _cachedUnknownIcons = {};

  Icon._(
    Iterable<IconData> icons,
    this.size, [
    Map<double, Icon>? cachedIconsMap,
  ]) : icons = List.unmodifiable(icons),
       _cachedSizedIcons = cachedIconsMap ?? {} {
    _cachedSizedIcons[size] = this;
  }

  factory Icon.unknownIcon(double expectedSize) =>
      _cachedUnknownIcons[expectedSize] ??
      Icon._(
        [
          IconData._(
            icon: '__core__/graphics/icons/unknown.png',
            iconSize: ExpectedIconSize.other,
            tint: Colour.defaultIconTint,
            shift: Vector.defaultVector,
            scale: (expectedSize / 2) / ExpectedIconSize.other,
            floating: false,
          ),
        ],
        ExpectedIconSize.other,
        _cachedUnknownIcons,
      );

  static Icon? fromTopLevelJson(Map json, double expectedSize) {
    String? icon = json['icon'];
    List<Map>? iconsJson = (json['icons'] as List?)?.cast();

    if (icon != null) {
      return Icon._([
        IconData._fromSingleIcon(
          icon,
          expectedSize,
          json['icon_size']?.toDouble() ?? expectedSize,
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

  Icon withQuality(Quality quality) {
    // TODO
    return this;
  }

  Icon resize(double newSize) {
    var resized = _cachedSizedIcons[newSize];

    if (resized == null) {
      var multiplier = newSize / size;

      resized = Icon._(
        icons.map(
          (iconData) => IconData._(
            icon: iconData.icon,
            iconSize: iconData.iconSize * multiplier,
            tint: iconData.tint,
            shift: iconData.shift * multiplier,
            scale: iconData.scale * multiplier,
            floating: iconData.floating,
          ),
        ),
        newSize,
        _cachedSizedIcons,
      );
    }

    return resized;
  }

  @override
  bool operator ==(Object other) =>
      super == other || (other is Icon && other.hashCode == hashCode);
}

class IconData {
  final String icon;
  final double iconSize;
  final Colour tint;
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

  factory IconData.fromJson(Map json, double expectedSize) {
    double iconSize = json['icon_size']?.toDouble() ?? ExpectedIconSize.other;
    // default scale is 0.5 for most icons
    double scale = json['scale'] ?? (expectedSize / 2) / iconSize;

    Colour tint = json['tint'] != null
        ? Colour.fromJson(json['tint'])
        : Colour.defaultIconTint;
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
    double expectedSize,
    double iconSize,
  ) => IconData._(
    icon: path,
    iconSize: iconSize,
    tint: Colour.defaultIconTint,
    shift: Vector.defaultVector,
    scale: (expectedSize / 2) / iconSize,
    floating: false,
  );

  factory IconData.unknownIcon(double expectedSize) => IconData._(
    icon: '__core__/graphics/icons/unknown.png',
    iconSize: ExpectedIconSize.other,
    tint: Colour.defaultIconTint,
    shift: Vector.defaultVector,
    scale: (expectedSize / 2) / ExpectedIconSize.other,
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

  Vector operator *(num other) => Vector._(x: x * other, y: y * other);

  @override
  bool operator ==(Object other) =>
      super == other || (other is Vector && x == other.x && y == other.y);

  @override
  int get hashCode => x.hashCode + (y * 500).hashCode;
}

abstract final class ExpectedIconSize {
  static const double starMapIcon = 512;
  static const double technology = 256;
  static const double achievement = 128;
  static const double itemGroup = 128;
  static const double other = 64;
  static const double smallIcon = 32;
}
