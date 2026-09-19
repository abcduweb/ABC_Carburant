import 'package:shared_preferences/shared_preferences.dart';
import '../models/station.dart';

/// Caractéristiques du véhicule, utilisées pour chiffrer le gain réel.
class VehicleSettings {
  final double tankLitres; // volume d'un plein
  final double consumption; // L / 100 km (thermique)
  final double kwhConsumption; // kWh / 100 km (electrique)
  /// Tarif de recharge en EUR/kWh. Le fichier IRVE ne publie pas les
  /// prix : seul l'utilisateur peut renseigner son tarif habituel.
  final double kwhPrice;

  const VehicleSettings({
    this.tankLitres = 50,
    this.consumption = 6.5,
    this.kwhConsumption = 17,
    this.kwhPrice = 0.40,
  });

  static const String _kTank = 'tank_litres';
  static const String _kConso = 'consumption';
  static const String _kKwh = 'kwh_consumption';
  static const String _kKwhPrice = 'kwh_price';

  static Future<VehicleSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return VehicleSettings(
      tankLitres: prefs.getDouble(_kTank) ?? 50,
      consumption: prefs.getDouble(_kConso) ?? 6.5,
      kwhConsumption: prefs.getDouble(_kKwh) ?? 17,
      kwhPrice: prefs.getDouble(_kKwhPrice) ?? 0.40,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kTank, tankLitres);
    await prefs.setDouble(_kConso, consumption);
    await prefs.setDouble(_kKwh, kwhConsumption);
    await prefs.setDouble(_kKwhPrice, kwhPrice);
  }

  VehicleSettings copyWith({
    double? tankLitres,
    double? consumption,
    double? kwhConsumption,
    double? kwhPrice,
  }) =>
      VehicleSettings(
        tankLitres: tankLitres ?? this.tankLitres,
        consumption: consumption ?? this.consumption,
        kwhConsumption: kwhConsumption ?? this.kwhConsumption,
        kwhPrice: kwhPrice ?? this.kwhPrice,
      );

  /// Coût aux 100 km pour un prix au litre donné.
  double costPer100km(double pricePerLitre) => pricePerLitre * consumption;

  /// Coût aux 100 km pour un prix au kWh donné.
  double costPer100kmElectric(double pricePerKwh) =>
      pricePerKwh * kwhConsumption;

  /// Coût aux 100 km en électrique, au tarif renseigné par
  /// l'utilisateur.
  double get electricCostPer100km => kwhPrice * kwhConsumption;
}

/// Résultat du calcul pour une station donnée.
class Savings {
  final double gross; // économie brute sur le plein
  final double detourCost; // carburant consommé par le détour
  final double net; // gain réellement empoché
  final double extraKm; // kilomètres supplémentaires, aller-retour

  const Savings({
    required this.gross,
    required this.detourCost,
    required this.net,
    required this.extraKm,
  });

  bool get isWorthIt => net > 0.20; // en dessous, le gain n'est pas significatif
}

/// Compare chaque station à celle que l'automobiliste prendrait par défaut :
/// la plus proche qui vend le carburant voulu.
///
/// Le détour est compté aller-retour, ce qui est le cas d'usage réel
/// (on revient sur son trajet après le plein).
class SavingsCalculator {
  static Station? reference(List<Station> stations, String fuelType) {
    final eligible = stations
        .where((s) => s.prices.containsKey(fuelType))
        .toList()
      ..sort((a, b) => a.distance.compareTo(b.distance));
    return eligible.isEmpty ? null : eligible.first;
  }

  static Savings? compute({
    required Station station,
    required Station? reference,
    required String fuelType,
    required VehicleSettings settings,
  }) {
    if (reference == null) return null;

    final price = station.prices[fuelType]?.price;
    final refPrice = reference.prices[fuelType]?.price;
    if (price == null || refPrice == null) return null;

    final gross = (refPrice - price) * settings.tankLitres;

    final extraKm = (station.distance - reference.distance) * 2;
    // Le carburant du détour est payé au prix de la station visée
    final detourCost =
        extraKm <= 0 ? 0.0 : (extraKm * settings.consumption / 100) * price;

    return Savings(
      gross: gross,
      detourCost: detourCost,
      net: gross - detourCost,
      extraKm: extraKm < 0 ? 0 : extraKm,
    );
  }
}
