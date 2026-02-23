import 'dart:io';

import 'package:flutter/material.dart';

// TODO - Get working with MacOS and Windows
final String _homeDir = Platform.environment['HOME']!;
// TODO - Account for different steam locations
// TODO - Account for path to mods
const String _factorioFilesPath =
    '/.local/share/Steam/steamapps/common/Factorio/data/';

final Map<_PathAndSize, Widget> _pathToImage = {};

Widget getIconWidget(String? path, double size) {
  path ??= '__core__/graphics/icons/unknown.png';

  return _pathToImage.putIfAbsent(_PathAndSize(path, size), () {
    int firstSlash = path!.indexOf('/');
    String iconPath =
        _homeDir +
        _factorioFilesPath +
        path.substring(0, firstSlash).replaceAll('__', '') +
        path.substring(firstSlash);

    // TODO - Account for larger images
    return ClipRRect(
      child: Image.file(
        File(iconPath),
        height: size,
        width: size,
        fit: BoxFit.none,
        alignment: Alignment.topLeft,
      ),
    );
  });
}

class _PathAndSize {
  final String path;
  final double size;

  _PathAndSize(this.path, this.size);

  @override
  bool operator ==(Object other) {
    if (other is _PathAndSize) {
      return other.path == path && other.size == size;
    } else {
      return false;
    }
  }

  @override
  int get hashCode => path.hashCode + size.ceil();
}
