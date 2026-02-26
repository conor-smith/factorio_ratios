import 'dart:io';

import 'package:factorio_ratios/factorio/models.dart';
import 'package:flutter/material.dart' hide IconData;

// TODO - Get working with MacOS and Windows
final String _homeDir = Platform.environment['HOME']!;
// TODO - Account for different steam locations
// TODO - Account for path to mods
const String _factorioFilesPath =
    '/.local/share/Steam/steamapps/common/Factorio/data/';

final Map<_IconAndSize, FactorioIconWidget> _iconWidgetMap = {};

class FactorioIconWidget extends StatelessWidget {
  final HasIcon icon;
  final double size;
  final Widget _widget;

  factory FactorioIconWidget({required HasIcon hasIcon, required double size}) {
    return _iconWidgetMap.putIfAbsent(_IconAndSize(hasIcon, size), () {
      double scaleMultiplier =
          size / (hasIcon.expectedIconSize * hasIcon.defaultScale);

      List<IconData> icons =
          hasIcon.icons ?? [IconData.unknownIcon(hasIcon.expectedIconSize)];

      Widget finalWidget = Container(
        width: size,
        height: size,
        clipBehavior: Clip.none,
        child: Stack(
          clipBehavior: Clip.none,
          children: icons
              .map(
                (iconData) =>
                    _createWidgetFromIconData(iconData, scaleMultiplier, size),
              )
              .toList(),
        ),
      );

      return FactorioIconWidget._(
        icon: hasIcon,
        size: size,
        widget: finalWidget,
      );
    });
  }

  const FactorioIconWidget._({
    required this.icon,
    required this.size,
    required Widget widget,
  }) : _widget = widget;

  @override
  Widget build(BuildContext context) => _widget;
}

String _buildFullFilePath(String partialPath) {
  int firstSlash = partialPath.indexOf('/');
  return _homeDir +
      _factorioFilesPath +
      partialPath.substring(0, firstSlash).replaceAll('__', '') +
      partialPath.substring(firstSlash);
}

Widget _createWidgetFromIconData(
  IconData iconData,
  double scaleMultiplier,
  double size,
) {
  double finalScale = iconData.scale * scaleMultiplier;
  double finalSize = finalScale * iconData.iconSize;
  finalSize = finalSize > size && iconData.floating ? finalSize : size;

  Widget imageWidget = Image.file(
    File(_buildFullFilePath(iconData.icon)),
    scale: finalScale,
    fit: BoxFit.none,
    opacity: iconData.tint.a == 1
        ? null
        : AlwaysStoppedAnimation(iconData.tint.a),
  );

  double offsetX = (finalSize - size + iconData.shift.x) * finalScale;
  double offsetY = (finalSize - size + iconData.shift.y) * finalScale;

  return Positioned(
    top: -offsetX,
    left: -offsetY,
    height: finalSize,
    width: finalSize,
    child: ClipRect(
      clipper: _CustomRectClipper(
        Rect.fromPoints(
          Offset(offsetX, offsetY),
          Offset(offsetX + finalSize, offsetY + finalSize),
        ),
      ),
      child: imageWidget,
    ),
  );
}

class _IconAndSize {
  final HasIcon hasIcon;
  final double size;

  _IconAndSize(this.hasIcon, this.size);

  @override
  bool operator ==(Object other) =>
      other is _IconAndSize && other.hasIcon == hasIcon && other.size == size;

  @override
  int get hashCode => hasIcon.hashCode + size.ceil();
}

class _CustomRectClipper extends CustomClipper<Rect> {
  final Rect rect;

  _CustomRectClipper(this.rect);

  @override
  Rect getClip(Size size) {
    return rect;
  }

  @override
  bool shouldReclip(covariant _CustomRectClipper oldClipper) {
    return true;
  }
}
