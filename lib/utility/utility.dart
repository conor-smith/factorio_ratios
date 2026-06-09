Set<T>? unmodifableSetOrNull<T>(Iterable<T>? iterable) =>
    iterable != null ? Set.unmodifiable(iterable) : null;
List<T>? unmodifiableListOrNull<T>(Iterable<T>? iterable) =>
    iterable != null ? List.unmodifiable(iterable) : null;
Map<K, V>? unmodifiableMapOrNull<K, V>(Map<K, V>? map) =>
    map != null ? Map.unmodifiable(map) : null;
