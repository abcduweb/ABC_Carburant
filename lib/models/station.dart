import 'dart:math';
import 'locatable.dart';

class Station implements Locatable {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double distance;
  final Map<String, FuelPrice> prices;

  Station({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distance,
    required this.prices,
  });

  // Colonnes du dataset -> libellés affichés dans l'UI
  static const Map<String, String> _fuelColumns = {
    'gazole': 'Gazole',
    'sp95': 'SP95',
    'sp98': 'SP98',
    'e10': 'E10',
    'e85': 'E85',
    'gplc': 'GPLc',
  };

  factory Station.fromJson(
      Map<String, dynamic> json, double userLat, double userLon) {
    final coords = _extractCoords(json);
    final lat = coords[0];
    final lon = coords[1];

    final Map<String, FuelPrice> prices = {};
    _fuelColumns.forEach((column, label) {
      final raw = json['${column}_prix'];
      final value = _toDouble(raw);
      if (value != null && value > 0) {
        prices[label] = FuelPrice(
          type: label,
          price: value,
          lastUpdate: (json['${column}_maj'] ?? '').toString(),
        );
      }
    });

    final ville = (json['ville'] ?? '').toString();
    final adresse = (json['adresse'] ?? '').toString();
    final cp = (json['cp'] ?? '').toString();

    return Station(
      id: (json['id'] ?? '').toString(),
      name: ville.isNotEmpty ? ville : 'Station',
      address: [adresse, '$cp $ville'.trim()]
          .where((s) => s.trim().isNotEmpty)
          .join(', '),
      latitude: lat,
      longitude: lon,
      distance: _calculateDistance(userLat, userLon, lat, lon),
      prices: prices,
    );
  }

  // Le champ géo peut arriver sous plusieurs formes selon l'export
  static List<double> _extractCoords(Map<String, dynamic> json) {
    for (final key in ['geom', 'geo_point', 'geo_point_2d']) {
      final g = json[key];
      if (g is Map) {
        final lat = _toDouble(g['lat']);
        final lon = _toDouble(g['lon'] ?? g['long']);
        if (lat != null && lon != null) return [lat, lon];
      }
      if (g is List && g.length == 2) {
        final lat = _toDouble(g[0]);
        final lon = _toDouble(g[1]);
        if (lat != null && lon != null) return [lat, lon];
      }
    }

    // Repli : champs séparés, parfois en PTV_GEODECIMAL (x100000)
    var lat = _toDouble(json['latitude']);
    var lon = _toDouble(json['longitude']);
    if (lat != null && lon != null) {
      if (lat.abs() > 90) lat = lat / 100000;
      if (lon.abs() > 180) lon = lon / 100000;
      return [lat, lon];
    }

    return [0, 0];
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '.'));
  }

  // Formule de haversine
  static double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double r = 6371; // rayon terrestre en km
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * asin(min(1.0, sqrt(a)));
  }

  static double _toRad(double deg) => deg * pi / 180;
}

class FuelPrice {
  final String type;
  final double price;
  final String lastUpdate;

  FuelPrice({
    required this.type,
    required this.price,
    required this.lastUpdate,
  });

  /// Age du releve, ou null si la date est illisible.
  Duration? get age {
    if (lastUpdate.trim().isEmpty) return null;
    try {
      return DateTime.now().difference(DateTime.parse(lastUpdate).toLocal());
    } catch (_) {
      return null;
    }
  }

  /// Un relevé de plus de 5 jours n'est plus fiable : les stations
  /// remontent leurs prix a chaque changement, pas a intervalle fixe.
  bool get isStale {
    final a = age;
    return a != null && a.inDays >= 5;
  }
}
