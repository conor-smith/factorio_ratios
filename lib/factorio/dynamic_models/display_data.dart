part of 'dynamic_models.dart';

/// This represents data to be displayed to an end user
/// Represents a tree structure. Every object can have an arbitrary amount of children
/// Any children referencing a parent could result in the UI getting stuck in an infinite loop
///
/// In the value is of type MapEntry`<DisplayData, DisplayData>`,
/// The key and value objects are not permitted to have children of their own
///
/// It is assumed that lists of display data are displayed in reverse (highest index first)
class DisplayData {
  /// Contains type information about value
  final DisplayDataType type;

  final dynamic value;

  final List<DisplayData> children;

  DisplayData.netInput(ItemIo itemIo)
    : this.string('Net Input', children: convertToSortedDisplayData(itemIo));

  DisplayData.netOutput(ItemIo itemIo)
    : this.string('Net Output', children: convertToSortedDisplayData(itemIo));

  DisplayData.powerConsumption(
    double value, [
    List<DisplayData> children = const [],
  ]) : this._(
         DisplayDataType.keyValue,
         MapEntry(
           DisplayData.string('Power Consumption'),
           DisplayData.wattage(value),
         ),
         children: children,
       );

  DisplayData.string(String value, {Iterable<DisplayData> children = const []})
    : this._(DisplayDataType.string, value, children: children);

  DisplayData.number(num value, {Iterable<DisplayData> children = const []})
    : this._(DisplayDataType.number, value, children: children);

  DisplayData.boolean(bool value, {Iterable<DisplayData> children = const []})
    : this._(DisplayDataType.boolean, value, children: children);

  DisplayData.icon(HasIcon value, {Iterable<DisplayData> children = const []})
    : this._(DisplayDataType.hasIcon, value, children: children);

  DisplayData.rowAlignedLeft(
    Iterable<DisplayData> row, {
    Iterable<DisplayData> children = const [],
  }) : this._row(DisplayDataType.rowAlignedLeft, row, children);

  DisplayData.rowAlignedCentre(
    Iterable<DisplayData> row, {
    Iterable<DisplayData> children = const [],
  }) : this._row(DisplayDataType.rowAlignedCentre, row, children);

  DisplayData.rowAlignedRight(
    Iterable<DisplayData> row, {
    Iterable<DisplayData> children = const [],
  }) : this._row(DisplayDataType.rowAlignedRight, row, children);

  DisplayData.iconAndString({
    required HasIcon icon,
    required String string,
    Iterable<DisplayData> children = const [],
  }) : this._(DisplayDataType.rowAlignedLeft, [
         icon,
         string,
       ], children: children);

  DisplayData.percent(double value, {Iterable<DisplayData> children = const []})
    : this._(DisplayDataType.percent, value, children: children);

  DisplayData.wattage(double value, {Iterable<DisplayData> children = const []})
    : this._(DisplayDataType.wattage, value, children: children);

  DisplayData.joules(double value, {Iterable<DisplayData> children = const []})
    : this._(DisplayDataType.joules, value, children: children);

  DisplayData.multiplier(
    double value, {
    Iterable<DisplayData> children = const [],
  }) : this._(DisplayDataType.multiplier, value, children: children);

  DisplayData.keyValuePair({
    required DisplayData key,
    required DisplayData value,
    Iterable<DisplayData> children = const [],
  }) : this._mapEntry(DisplayDataType.keyValueLeftArrow, key, value, children);

  DisplayData.keyValuePairRightArrow({
    required DisplayData key,
    required DisplayData value,
    Iterable<DisplayData> children = const [],
  }) : this._mapEntry(DisplayDataType.keyValueRightArrow, key, value, children);

  DisplayData.keyValuePairLeftArrow({
    required DisplayData key,
    required DisplayData value,
    Iterable<DisplayData> children = const [],
  }) : this._mapEntry(DisplayDataType.keyValueLeftArrow, key, value, children);

  DisplayData._mapEntry(
    this.type,
    DisplayData key,
    DisplayData value,
    Iterable<DisplayData> children,
  ) : value = MapEntry(key, value),
      children = List.unmodifiable(children) {
    if (key.children.isNotEmpty || value.children.isNotEmpty) {
      throw FactorioException(
        'Key or value displayData object in MapEntry is not permitted to have children',
      );
    }
  }

  DisplayData._row(
    this.type,
    Iterable<DisplayData> columns,
    Iterable<DisplayData> children,
  ) : value = List.unmodifiable(columns),
      children = List.unmodifiable(children) {
    for (var column in columns) {
      if (column.children.isNotEmpty) {
        throw FactorioException(
          'DisplayData objects in row are not permitted to have children',
        );
      }
    }
  }

  DisplayData._(
    this.type,
    this.value, {
    Iterable<DisplayData> children = const [],
  }) : children = List.unmodifiable(children);

  static Iterable<DisplayData> convertToSortedDisplayData(ItemIo itemIo) {
    var sortedEntries = _sortMapAndReturnEntries(itemIo);

    return sortedEntries.map(
      (entry) => DisplayData._(
        DisplayDataType.keyValueLeftArrow,
        MapEntry(DisplayData.icon(entry.key), DisplayData.number(entry.value)),
      ),
    );
  }

  @override
  String toString() => value.toString();
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

  // Value is of type MapEntry<HasIcon, String>
  hasIconAndString,

  /// Value is a number, but should be displayed as a percentage
  /// Eg. a value of 1.6 should be displayed as 160%
  percent,

  // Value is a number, and is explicitly used as a multiplier
  multiplier,

  /// Value is a number representing wattage, and should be displayed as such
  /// eg. a value of 1,500 should be displayed as 1.5kW
  wattage,

  /// Value is a number representing joules, and should be displayed as such
  /// eg. a value of 1,500 should be displayed as 1.5kJ
  joules,

  /// Value is a list of DisplayData objects to be represented as a row
  /// Columns are to be aligned left
  rowAlignedLeft,

  /// Value is a list of DisplayData objects to be represented as a row
  /// Columns are evenly spaced out
  rowAlignedCentre,

  /// Value is a list of DisplayData objects to be represented as a row
  /// Columns are to be aligned right
  rowAlignedRight,

  /// value is a map entry, with key and value both being DisplayData instances
  /// Data should be displayed simply as key: value
  keyValue,

  /// value is a map entry, with key and value both being DisplayData instances
  /// Data should be displayed simply as key -> value
  keyValueRightArrow,

  /// value is a map entry, with key and value both being DisplayData instances
  /// Data should be displayed simply as key <- value
  keyValueLeftArrow,
}

List<MapEntry<K, V>> _sortMapAndReturnEntries<K extends Comparable, V>(
  Map<K, V> map,
) {
  var entries = map.entries.toList(growable: false);
  entries.sort((entry1, entry2) => entry1.key.compareTo(entry2));

  return entries;
}
