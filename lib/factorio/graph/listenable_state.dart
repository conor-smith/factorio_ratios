part of '../graph.dart';

mixin ListenableState<T> {
  Function(T state)? callbackOnChange;
  Function(T state)? callbackOnDelete;

  void _updateListeners(T state) {
    if (callbackOnChange != null) {
      callbackOnChange!(state);
    }
  }
}
