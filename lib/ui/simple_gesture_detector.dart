import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class SimpleGestureDetector extends StatefulWidget {
  final HitTestBehavior behaviour;

  final Function(PointerDownEvent event)? onPrimaryPointerDown;
  final Function(PointerDownEvent event)? onSecondaryPointerDown;
  final Function(PointerCancelEvent event)? onPointerCancel;
  final Function(PointerEvent event)? onPrimaryClick;
  final Function(PointerEvent event)? onSecondaryClick;
  final Function(PointerDownEvent start)? onDragStart;
  final Function(PointerDownEvent start, PointerMoveEvent move)? onDrag;
  final Function(PointerDownEvent start, PointerUpEvent end)? onDragEnd;
  final Function(PointerCancelEvent event)? onDragCancel;

  final Widget? child;

  const SimpleGestureDetector({
    super.key,
    this.behaviour = HitTestBehavior.deferToChild,
    this.onPrimaryPointerDown,
    this.onSecondaryPointerDown,
    this.onPointerCancel,
    this.onPrimaryClick,
    this.onSecondaryClick,
    this.onDragStart,
    this.onDrag,
    this.onDragEnd,
    this.onDragCancel,
    this.child,
  });

  @override
  State<SimpleGestureDetector> createState() => _SimpleGestureDetectorState();
}

class _SimpleGestureDetectorState extends State<SimpleGestureDetector> {
  PointerDownEvent? start;
  bool isDragging = false;

  bool isNotDrag(PointerDownEvent start, PointerMoveEvent event) {
    var gestureTime = event.timeStamp - start.timeStamp;
    var gestureDistance = (event.position - start.position).distance.abs();

    return gestureTime < const Duration(milliseconds: 100) &&
        gestureDistance < 10;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: widget.behaviour,
      onPointerDown: (event) {
        if (event.buttons == kPrimaryButton) {
          start = event;
          isDragging = false;

          widget.onPrimaryPointerDown?.call(event);
        } else if (event.buttons == kSecondaryButton) {
          start = event;
          isDragging = false;

          widget.onSecondaryPointerDown?.call(event);
        }
      },
      onPointerUp: (event) {
        if (start != null) {
          if (isDragging) {
            widget.onDragEnd?.call(start!, event);
          } else {
            if (start!.buttons == kPrimaryButton) {
              widget.onPrimaryClick?.call(start!);
            } else if (start!.buttons == kSecondaryButton) {
              widget.onSecondaryClick?.call(start!);
            }
          }

          start = null;
          isDragging = false;
        }
      },
      onPointerCancel: (event) {
        if (isDragging) {
          widget.onDragCancel?.call(event);
        } else {
          widget.onPointerCancel?.call(event);
        }
        start = null;
        isDragging = false;
      },
      onPointerMove: (event) {
        if (isDragging) {
          widget.onDrag?.call(start!, event);
        } else if (!isDragging &&
            start?.buttons == kPrimaryButton &&
            !isNotDrag(start!, event)) {
          isDragging = true;

          widget.onDragStart?.call(start!);
          widget.onDrag?.call(start!, event);
        }
      },
      child: widget.child,
    );
  }
}
