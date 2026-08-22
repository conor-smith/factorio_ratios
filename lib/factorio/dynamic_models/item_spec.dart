part of 'dynamic_models.dart';

class _SolidItemInputSpecImpl extends DelegatingSolidItem
    implements SolidItemInputSpec {
  @override
  final SolidItem internal;

  @override
  final Quality? qualityMin;
  @override
  final Quality? qualityMax;

  @override
  final Icon? icon;

  _SolidItemInputSpecImpl._(this.internal, this.qualityMin, this.qualityMax)
    : icon = internal.icon?.withQuality(qualityMin);

  factory _SolidItemInputSpecImpl.allQualities(SolidItem item) {
    if (item is DelegatingSolidItem) {
      item = item.internal;
    }

    return _SolidItemInputSpecImpl._(item, null, null);
  }

  factory _SolidItemInputSpecImpl(
    SolidItem internal, {
    Quality? qualityMin,
    Quality? qualityMax,
  }) {
    if (internal is DelegatingSolidItem) {
      internal = internal.internal;
    }

    qualityMin ??= internal.factorioDb.defaultQuality;
    qualityMax ??= internal.factorioDb.defaultQuality;

    return _SolidItemInputSpecImpl._(internal, qualityMin, qualityMax);
  }

  @override
  bool accepts(Item item) =>
      item is SolidItemOutputSpec &&
      item.internal == internal &&
      (qualityMin == null ||
          (qualityMin!.chainCompare(item.quality).lessThanOrEqual &&
              qualityMax!.chainCompare(item.quality).greaterThanOrEqual));

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }

  @override
  bool operator ==(Object other) =>
      super == other ||
      other is _SolidItemInputSpecImpl &&
          internal == other.internal &&
          qualityMin == other.qualityMin &&
          qualityMax == other.qualityMax;

  @override
  int get hashCode =>
      internal.hashCode + qualityMin.hashCode + (qualityMax.hashCode * 10);
}

class _FluidItemInputSpecImpl extends DelegatingFluidItem
    implements FluidItemInputSpec {
  @override
  final FluidItem internal;

  @override
  final double minimumTemperature;
  @override
  final double maximumTemperature;

  _FluidItemInputSpecImpl._(
    this.internal,
    this.minimumTemperature,
    this.maximumTemperature,
  );

  factory _FluidItemInputSpecImpl(
    FluidItem internal, {
    double? minimumTemperature,
    double? maximumTemperature,
  }) {
    if (internal is DelegatingFluidItem) {
      internal = internal.internal;
    }

    minimumTemperature ??= internal.defaultTemperature;
    maximumTemperature ??= internal.defaultTemperature;

    return _FluidItemInputSpecImpl._(
      internal,
      minimumTemperature,
      maximumTemperature,
    );
  }

  @override
  bool accepts(Item item) =>
      item is FluidItemOutputSpec &&
      item.internal == internal &&
      item.temperature >= minimumTemperature &&
      item.temperature <= maximumTemperature;

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }

  @override
  bool operator ==(Object other) =>
      super == other ||
      other is _FluidItemInputSpecImpl &&
          internal == other.internal &&
          minimumTemperature == other.minimumTemperature &&
          maximumTemperature == other.maximumTemperature;

  @override
  int get hashCode =>
      internal.hashCode +
      minimumTemperature.hashCode +
      (maximumTemperature.hashCode * 38);
}

class _SolidItemOutputSpecImpl extends DelegatingSolidItem
    with QualityPrototype
    implements SolidItemOutputSpec {
  @override
  final SolidItem internal;

  @override
  final Quality quality;

  _SolidItemOutputSpecImpl._(this.internal, this.quality);

  factory _SolidItemOutputSpecImpl(SolidItem item, {Quality? quality}) {
    if (item is DelegatingSolidItem) {
      item = item.internal;
    }

    quality ??= item.factorioDb.defaultQuality;

    return _SolidItemOutputSpecImpl._(item, quality);
  }

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }

  @override
  bool operator ==(Object other) =>
      super == other ||
      (other is _SolidItemOutputSpecImpl &&
          internal == other.internal &&
          quality == other.quality);

  @override
  int get hashCode => internal.hashCode + quality.hashCode;
}

class _FluidItemOutputSpecImpl extends DelegatingFluidItem
    implements FluidItemOutputSpec {
  @override
  final FluidItem internal;
  @override
  final double temperature;

  @override
  final String name;

  @override
  final int hashCode;

  factory _FluidItemOutputSpecImpl(FluidItem item, {double? temperature}) {
    if (item is DelegatingFluidItem) {
      item = item.internal;
    }

    temperature ??= item.defaultTemperature;
    return _FluidItemOutputSpecImpl._(item, temperature);
  }

  _FluidItemOutputSpecImpl._(this.internal, this.temperature)
    : name = '${internal.name}: T$temperature',
      hashCode = internal.hashCode + temperature.hashCode;

  // Ensure that fluids of different temperature are sorted
  @override
  int compareTo(Prototype other) {
    if (other is FluidItemOutputSpec && internal == other.internal) {
      return temperature.compareTo(other.temperature);
    } else {
      return super.compareTo(other);
    }
  }

  @override
  bool operator ==(Object other) =>
      super == other ||
      (other is _FluidItemOutputSpecImpl &&
          internal == other.internal &&
          temperature == other.temperature);

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}
