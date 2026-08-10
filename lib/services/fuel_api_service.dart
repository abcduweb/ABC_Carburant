import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/station.dart';

class FuelApiService {
  static const String _host = 'data.economie.gouv.fr';
  static const String _path =
      '/api/explore/v2.1/catalog/datasets/prix-des-carburants-en-france-flux-instantane-v2/records';

  // Requête générique + gestion d'erreur lisible
  Future<List<Station>> _fetch(
    Map<String, String> params,
    double userLat,
    double userLon,
  ) async {
    final Uri uri = Uri.https(_host, _path, params);
    final response = await http.get(uri).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      final body = response.body.length > 300
          ? response.body.substring(0, 300)
          : response.body;
      throw Exception('HTTP ${response.statusCode} — $body');
    }

    final Map<String, dynamic> jsonResponse = json.decode(response.body);
    final List<dynamic> records = jsonResponse['results'] ?? [];

    final stations = records
        .map((r) => Station.fromJson(r as Map<String, dynamic>, userLat, userLon))
        .where((s) => s.latitude != 0 && s.longitude != 0)
        .toList();

    stations.sort((a, b) => a.distance.compareTo(b.distance));
    return stations;
  }

  // Stations à proximité (rayon en km)
  Future<List<Station>> getStationsNearby(
    double latitude,
    double longitude, {
    double radiusKm = 20,
  }) async {
    try {
      return await _fetch({
        'where':
            "within_distance(geom, geom'POINT($longitude $latitude)', ${radiusKm.toInt()}km)",
        'limit': '100',
        'order_by': "distance(geom, geom'POINT($longitude $latitude)')",
      }, latitude, longitude);
    } catch (e) {
      throw Exception('Erreur lors de la récupération des stations: $e');
    }
  }

  // Repli : les 100 premières stations sans filtre géographique
  Future<List<Station>> getAllStations(double latitude, double longitude) async {
    try {
      return await _fetch({'limit': '100'}, latitude, longitude);
    } catch (e) {
      throw Exception('Erreur lors de la récupération des stations: $e');
    }
  }

  // Recherche par commune ou code postal
  Future<List<Station>> searchByLocation(
    String location,
    double latitude,
    double longitude,
  ) async {
    try {
      final safe = location.replaceAll('"', '');
      return await _fetch({
        'where': 'ville like "$safe" or cp like "$safe"',
        'limit': '100',
      }, latitude, longitude);
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }
}
