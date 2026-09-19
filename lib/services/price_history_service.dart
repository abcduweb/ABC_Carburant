import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/station.dart';

/// Un relevé de prix daté.
class PricePoint {
  final DateTime date;
  final double price;

  const PricePoint(this.date, this.price);

  Map<String, dynamic> toJson() => {
        'd': date.toIso8601String(),
        'p': price,
      };

  factory PricePoint.fromJson(Map<String, dynamic> j) => PricePoint(
        DateTime.parse(j['d'] as String),
        (j['p'] as num).toDouble(),
      );
}

/// Tendance observée sur les derniers relevés.
enum PriceTrend { rising, falling, stable, unknown }

class PriceHistory {
  final List<PricePoint> points;
  const PriceHistory(this.points);

  bool get hasEnoughData => points.length >= 3;

  double? get latest => points.isEmpty ? null : points.last.price;
  double? get lowest => points.isEmpty
      ? null
      : points.map((p) => p.price).reduce((a, b) => a < b ? a : b);
  double? get highest => points.isEmpty
      ? null
      : points.map((p) => p.price).reduce((a, b) => a > b ? a : b);

  /// Écart entre le dernier relevé et le plus ancien conservé.
  double? get change {
    if (points.length < 2) return null;
    return points.last.price - points.first.price;
  }

  /// Tendance sur les 3 derniers relevés. Le seuil de 0,5 centime évite
  /// de qualifier de "hausse" une variation d'arrondi.
  PriceTrend get trend {
    if (!hasEnoughData) return PriceTrend.unknown;
    final recent = points.sublist(points.length - 3);
    final delta = recent.last.price - recent.first.price;
    if (delta.abs() < 0.005) return PriceTrend.stable;
    return delta > 0 ? PriceTrend.rising : PriceTrend.falling;
  }

  /// Vrai si le prix actuel est au plus bas de la période observée.
  bool get isAtLowest {
    if (!hasEnoughData) return false;
    final l = lowest;
    final c = latest;
    return l != null && c != null && (c - l).abs() < 0.005;
  }
}

/// Historique des prix construit localement, à chaque consultation.
///
/// Aucune API ne fournit l'historique des prix des carburants : on le
/// constitue donc soi-même, en mémorisant ce qui est affiché. Les
/// données restent sur l'appareil, rien n'est envoyé.
///
/// Seules les stations FAVORITES sont suivies : suivre toutes les
/// stations rencontrées ferait grossir le stockage sans fin, pour des
/// lieux de passage sans intérêt pour l'utilisateur.
class PriceHistoryService {
  static const String _prefix = 'price_history_';

  /// Nombre de relevés conservés par station et par carburant. 60 points
  /// couvrent environ deux mois à raison d'une consultation par jour.
  static const int _maxPoints = 60;

  /// Deux relevés trop rapprochés n'apportent rien : on n'enregistre
  /// qu'une valeur par tranche de 6 heures.
  static const Duration _minInterval = Duration(hours: 6);

  static String _key(String stationId, String fuelType) =>
      '$_prefix${stationId}_$fuelType';

  static Future<PriceHistory> load(
      String stationId, String fuelType) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key(stationId, fuelType)) ?? [];
    final points = <PricePoint>[];
    for (final s in raw) {
      try {
        points.add(PricePoint.fromJson(json.decode(s)));
      } catch (_) {
        // Entrée illisible (format ancien) : ignorée.
      }
    }
    points.sort((a, b) => a.date.compareTo(b.date));
    return PriceHistory(points);
  }

  /// Enregistre un relevé. Sans effet si un relevé récent existe déjà ou
  /// si le prix n'a pas bougé depuis le dernier.
  static Future<void> record(
    String stationId,
    String fuelType,
    double price,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _key(stationId, fuelType);
    final raw = prefs.getStringList(key) ?? [];

    final points = <PricePoint>[];
    for (final s in raw) {
      try {
        points.add(PricePoint.fromJson(json.decode(s)));
      } catch (_) {}
    }
    points.sort((a, b) => a.date.compareTo(b.date));

    final now = DateTime.now();
    if (points.isNotEmpty) {
      final last = points.last;
      if (now.difference(last.date) < _minInterval) return;
      // Prix inchangé : on met à jour la date du dernier point plutôt
      // que d'accumuler des valeurs identiques.
      if ((last.price - price).abs() < 0.001) {
        points[points.length - 1] = PricePoint(now, price);
        await prefs.setStringList(
            key, points.map((p) => json.encode(p.toJson())).toList());
        return;
      }
    }

    points.add(PricePoint(now, price));
    while (points.length > _maxPoints) {
      points.removeAt(0);
    }

    await prefs.setStringList(
        key, points.map((p) => json.encode(p.toJson())).toList());
  }

  /// Enregistre les prix d'une station, tous carburants confondus.
  static Future<void> recordStation(Station station) async {
    for (final entry in station.prices.entries) {
      await record(station.id, entry.key, entry.value.price);
    }
  }

  /// Supprime l'historique d'une station (au retrait des favoris).
  static Future<void> clearStation(String stationId) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys()
        .where((k) => k.startsWith('$_prefix${stationId}_'))
        .toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
  }

  /// Supprime tout l'historique.
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
  }

  /// Nombre de relevés stockés, pour l'affichage dans les réglages.
  static Future<int> totalPoints() async {
    final prefs = await SharedPreferences.getInstance();
    var total = 0;
    for (final k in prefs.getKeys().where((k) => k.startsWith(_prefix))) {
      total += (prefs.getStringList(k) ?? []).length;
    }
    return total;
  }
}
