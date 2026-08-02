class CalculationSettings {
  CalculationSettings({required this.fuelEfficiency, required this.fuelPrice}) {
    validate();
  }

  final double fuelEfficiency;
  final int fuelPrice;

  void validate() {
    if (!fuelEfficiency.isFinite ||
        fuelEfficiency < 1.0 ||
        fuelEfficiency > 50.0) {
      throw ArgumentError.value(
        fuelEfficiency,
        'fuelEfficiency',
        'must be finite and between 1.0 and 50.0',
      );
    }
    if (fuelPrice < 100 || fuelPrice > 300) {
      throw ArgumentError.value(
        fuelPrice,
        'fuelPrice',
        'must be between 100 and 300',
      );
    }
  }

  Map<String, Object> toJson() => {
    'fuelEfficiency': fuelEfficiency,
    'fuelPrice': fuelPrice,
  };

  factory CalculationSettings.fromJson(Map<String, Object?> json) {
    final fuelEfficiency = json['fuelEfficiency'];
    final fuelPrice = json['fuelPrice'];
    if (fuelEfficiency is! num || fuelPrice is! int) {
      throw const FormatException('Calculation settings fields are missing');
    }
    return CalculationSettings(
      fuelEfficiency: fuelEfficiency.toDouble(),
      fuelPrice: fuelPrice,
    );
  }
}
