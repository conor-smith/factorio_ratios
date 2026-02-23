import 'dart:io';

import 'package:factorio_ratios/factorio/models.dart';
import 'package:flutter/material.dart';

// TODO - Get working with MacOS and Windows
final String _homeDir = Platform.environment['HOME']!;
// TODO - Account for different steam locations
// TODO - Account for path to mods
const String _factorioFilesPath =
    '/.local/share/Steam/steamapps/common/Factorio/data/';
const String _unknownImage = '__core__/graphics/icons/unknown.png';

Widget getIcon(HasIcon hasIcon, double sizeToDisplay) {
  List<Widget> imageWidgets;

  // TODO - account for 'shift'
  // TODO - account for 'renderBackground'
  // TODO - account for 'floating'
  if (hasIcon.icons == null) {
    imageWidgets = [
      Image.file(
        File(_buildFullFilePath(_unknownImage)),
        scale: sizeToDisplay / 64,
      ),
    ];
  } else {
    imageWidgets = hasIcon.icons!.map((iconData) {
      double widgetScale = iconData.scale * (sizeToDisplay / iconData.iconSize);

      return Image.file(
        File(_buildFullFilePath(iconData.icon)),
        scale: widgetScale,
        // color: Color.from(
        //   alpha: iconData.tint.a,
        //   red: iconData.tint.r,
        //   green: iconData.tint.g,
        //   blue: iconData.tint.b,
        // ),
        fit: BoxFit.none,
        alignment: AlignmentGeometry.topLeft,
      );
    }).toList();
  }

  Widget fullImageWidget;
  if (imageWidgets.length == 1) {
    fullImageWidget = imageWidgets.first;
  } else {
    fullImageWidget = Stack(fit: StackFit.passthrough, children: imageWidgets);
  }

  return fullImageWidget;
}

String _buildFullFilePath(String partialPath) {
  int firstSlash = partialPath.indexOf('/');
  return _homeDir +
      _factorioFilesPath +
      partialPath.substring(0, firstSlash).replaceAll('__', '') +
      partialPath.substring(firstSlash);
}
