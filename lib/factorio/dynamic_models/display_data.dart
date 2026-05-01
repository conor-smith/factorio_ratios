part of 'dynamic_models.dart';

/// This represents data to be displayed to an end user
/// Represents a tree structure. Every object can have an arbitrary amount of children
/// Any children referencing a parent could result in the UI getting stuck in an infinite loop
///
/// In the value is of type MapEntry`<DisplayData, DisplayData>`,
/// The key and value objects are not permitted to have children of their own
class DisplayData {
  /// Contains type information about value
  final DisplayDataType type;

  final dynamic value;

  final List<DisplayData> children;

  DisplayData.string(String value, [List<DisplayData> children = const []])
    : this._(DisplayDataType.string, value, children);

  DisplayData.number(num value, [List<DisplayData> children = const []])
    : this._(DisplayDataType.number, value, children);

  DisplayData.boolean(bool value, [List<DisplayData> children = const []])
    : this._(DisplayDataType.boolean, value, children);

  DisplayData.icon(HasIcon value, [List<DisplayData> children = const []])
    : this._(DisplayDataType.hasIcon, value, children);

  DisplayData.percent(double value, [List<DisplayData> children = const []])
    : this._(DisplayDataType.percent, value, children);

  DisplayData.keyValuePair(
    DisplayData key,
    DisplayData value, [
    List<DisplayData> children = const [],
  ]) : this._mapEntry(DisplayDataType.keyValueKeyArrow, key, value, children);

  DisplayData.keyValuePairWithValueArrow(
    DisplayData key,
    DisplayData value, [
    List<DisplayData> children = const [],
  ]) : this._mapEntry(DisplayDataType.keyValueValueArrow, key, value, children);

  DisplayData.keyValuePairWithKeyArrow(
    DisplayData key,
    DisplayData value, [
    List<DisplayData> children = const [],
  ]) : this._mapEntry(DisplayDataType.keyValueKeyArrow, key, value, children);

  DisplayData._mapEntry(
    this.type,
    DisplayData key,
    DisplayData value,
    List<DisplayData> children,
  ) : value = MapEntry(key, value),
      children = List.unmodifiable(children) {
    if (key.children.isNotEmpty || value.children.isNotEmpty) {
      throw FactorioException(
        'Key or value displayData object in MapEntry is not permitted to have children',
      );
    }
  }

  DisplayData._(this.type, this.value, List<DisplayData> children)
    : children = List.unmodifiable(children);
}

enum DisplayDataType {
  /// Value is a string
  string,

  /// Value is an int or double
  number,

  /// Value is a boolean
  boolean,

  /// Value is a HasIcon object
  hasIcon,

  /// Value is a number, but should be displayed as a percentage
  /// Eg. a value of 1.6 should be displayed as 160%
  percent,

  /// value is a map entry, with key and value both being DisplayData instances
  /// Data should be displayed simply as key: value
  keyValueNoArrow,

  /// value is a map entry, with key and value both being DisplayData instances
  /// Data should be displayed simply as key -> value
  keyValueValueArrow,

  /// value is a map entry, with key and value both being DisplayData instances
  /// Data should be displayed simply as key <- value
  keyValueKeyArrow,
}
