import 'package:flutter/gestures.dart';

bool isSimpleClick(PointerEvent start, PointerEvent event) {
  var gestureTime = event.timeStamp - start.timeStamp;
  var gestureDistance = (event.position - start.position).distance.abs();

  return gestureTime < const Duration(milliseconds: 100) &&
      gestureDistance < 10;
}
