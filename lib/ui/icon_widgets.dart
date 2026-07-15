import 'dart:io';

import 'package:factorio_ratios/factorio/models/models.dart';
import 'package:flutter/material.dart' hide IconData, Icon;

// TODO - Get working with MacOS and Windows
final String _homeDir = Platform.environment['HOME']!;
// TODO - Account for different steam locations
// TODO - Account for path to mods
const String _factorioFilesPath =
    '/.local/share/Steam/steamapps/common/Factorio/data/';

class FactorioIconWidget extends StatelessWidget {
  final Icon icon;
  final double expectedIconSize;
  final double defaultScale;
  final double size;

  final List<Widget> iconWidgets;

  FactorioIconWidget({
    super.key,
    required this.icon,
    required this.expectedIconSize,
    required this.defaultScale,
    required this.size,
  }) : iconWidgets = icon.icons
           .map(
             (iconData) => _createWidgetFromIconData(
               iconData,
               size / (expectedIconSize * defaultScale),
               size,
             ),
           )
           .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.none,
      child: Stack(clipBehavior: Clip.none, children: iconWidgets),
    );
  }
}

class IconWidgetCache {
  final Map<Icon, FactorioIconWidget> _cachedWidgets = {};

  FactorioIconWidget get(PrototypeWithIcon prototype) {
    var icon =
        prototype.icon ??
        Icon.unknownIcon(prototype.expectedIconSize * prototype.defaultScale);

    return _cachedWidgets.putIfAbsent(
      icon,
      () => FactorioIconWidget(
        icon: icon,
        expectedIconSize: prototype.expectedIconSize,
        defaultScale: prototype.defaultScale,
        size: prototype.expectedIconSize,
      ),
    );
  }
}

class _CustomRectClipper extends CustomClipper<Rect> {
  final Rect rect;

  _CustomRectClipper(this.rect);

  @override
  Rect getClip(Size size) {
    return rect;
  }

  @override
  bool shouldReclip(covariant _CustomRectClipper oldClipper) => false;
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
    color: Color.from(
      alpha: 1,
      red: iconData.tint.r,
      green: iconData.tint.g,
      blue: iconData.tint.b,
    ),
    opacity: AlwaysStoppedAnimation(iconData.tint.a),
    colorBlendMode: BlendMode.modulate,
  );

  double offsetX = (finalSize - size + iconData.shift.x) * finalScale;
  double offsetY = (finalSize - size + iconData.shift.y) * finalScale;

  return Positioned(
    top: -offsetX,
    left: -offsetY,
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

String _buildFullFilePath(String partialPath) {
  int firstSlash = partialPath.indexOf('/');
  return _homeDir +
      _factorioFilesPath +
      partialPath.substring(0, firstSlash).replaceAll('__', '') +
      partialPath.substring(firstSlash);
}
