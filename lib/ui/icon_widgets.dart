import 'dart:io';

import 'package:factorio_ratios/factorio/models.dart';
import 'package:flutter/material.dart' hide IconData;

// TODO - Get working with MacOS and Windows
final String _homeDir = Platform.environment['HOME']!;
// TODO - Account for different steam locations
// TODO - Account for path to mods
const String _factorioFilesPath =
    '/.local/share/Steam/steamapps/common/Factorio/data/';

class FactorioIconWidget extends StatelessWidget {
  final HasIcon icon;
  final double size;

  const FactorioIconWidget({super.key, required this.icon, required this.size});

  @override
  Widget build(BuildContext context) {
    double scaleMultiplier = size / (icon.expectedIconSize * icon.defaultScale);

    List<IconData> icons =
        icon.icons ?? [IconData.unknownIcon(icon.expectedIconSize)];

    List<Widget> iconWidgets = icons
        .map(
          (iconData) =>
              _createWidgetFromIconData(iconData, scaleMultiplier, size),
        )
        .toList();

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.none,
      child: Stack(clipBehavior: Clip.none, children: iconWidgets),
    );
  }
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
