import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/station.dart';
import 'fuel_api_service.dart';

class GeoPoint {
  final double lat;
  final double lon;
  const GeoPoint(this.lat, this.lon);
}

class PlaceSuggestion {
  final String label;
  final double lat;
  final double lon;
  const PlaceSuggestion(this.label, this.lat, this.lon);
}

class TripRoute {
  final List<GeoPoint> geometry;
  final double distanceKm;
  final Duration duration;
  const TripRoute(this.geometry, this.distanceKm, this.duration);
}

/// Géocodage (Nominatim) et calcul d'itinéraire (OSRM).
/// Deux services publics, sans clé, soumis à une politique d'usage
/// raisonnable : un appel par recherche, jamais en boucle.
class RoutingService {
  static const String _userAgent = 'ABCCarburant/1.0 (contact@abcduweb.fr)';

  /// Convertit un nom de lieu en coordonnées.
  static Future<List<PlaceSuggestion>> search(String query) async {
    if (query.trim().length < 3) return [];

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'format': 'json',
      'countrycodes': 'fr',
      'limit': '5',
    });

    final res = await http.get(uri, headers: {'User-Agent': _userAgent})
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) return [];

    final List<dynamic> data = json.decode(res.body);
    return data
        .map((e) => PlaceSuggestion(
              (e['display_name'] ?? '').toString(),
              double.tryParse(e['lat'].toString()) ?? 0,
              double.tryParse(e['lon'].toString()) ?? 0,
            ))
        .where((p) => p.lat != 0)
        .toList();
  }

  /// Itinéraire routier entre deux points.
  static Future<TripRoute> route(GeoPoint from, GeoPoint to) async {
    final uri = Uri.https(
      'router.project-osrm.org',
      '/route/v1/driving/${from.lon},${from.lat};${to.lon},${to.lat}',
      {'overview': 'full', 'geometries': 'geojson'},
    );

    final res = await http.get(uri, headers: {'User-Agent': _userAgent})
        .timeout(const Duration(seconds: 25));
    if (res.statusCode != 200) {
      throw Exception('Itinéraire indisponible (HTTP ${res.statusCode})');
    }

    final data = json.decode(res.body);
    final routes = data['routes'] as List?;
    if (routes == null || routes.isEmpty) {
      throw Exception('Aucun itinéraire trouvé entre ces deux points');
    }

    final r = routes.first;
    final coords = (r['geometry']['coordinates'] as List)
        .map((c) => GeoPoint(
              (c[1] as num).toDouble(),
              (c[0] as num).toDouble(),
            ))
        .toList();

    return TripRoute(
      coords,
      (r['distance'] as num).toDouble() / 1000,
      Duration(seconds: (r['duration'] as num).round()),
    );
  }

  /// Points d'échantillonnage régulièrement espacés le long du tracé.
  /// Limiter leur nombre est indispensable : chacun coûte une requête API.
  static List<GeoPoint> sample(TripRoute route, {int maxPoints = 10}) {
    final pts = route.geometry;
    if (pts.length <= maxPoints) return pts;

    final step = pts.length / maxPoints;
    return List.generate(
        maxPoints, (i) => pts[(i * step).floor().clamp(0, pts.length - 1)]);
  }

  /// Stations situées le long du trajet, dédoublonnées.
  /// [corridorKm] correspond à l'écart maximal accepté par rapport à la route.
  static Future<List<Station>> stationsAlongRoute(
    TripRoute route, {
    double corridorKm = 6,
    int maxPoints = 10,
  }) async {
    final api = FuelApiService();
    final points = sample(route, maxPoints: maxPoints);
    final Map<String, Station> unique = {};

    for (final p in points) {
      try {
        final batch =
            await api.getStationsNearby(p.lat, p.lon, radiusKm: corridorKm);
        for (final s in batch) {
          unique[s.id] = s;
        }
      } catch (_) {
        // Un point qui échoue ne doit pas faire tomber tout le trajet
      }
    }

    // Distance mesurée depuis le départ, pour un ordre logique de traversée
    final start = route.geometry.first;
    final list = unique.values.toList()
      ..sort((a, b) => _haversine(start.lat, start.lon, a.latitude, a.longitude)
          .compareTo(
              _haversine(start.lat, start.lon, b.latitude, b.longitude)));

    return list;
  }

  static double _haversine(
      double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return r * 2 * asin(min(1.0, sqrt(a)));
  }
}
