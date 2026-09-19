import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/station.dart';

class FuelApiService {
  static const String _host = 'data.economie.gouv.fr';
  static const String _path =
      '/api/explore/v2.1/catalog/datasets/prix-des-carburants-en-france-flux-instantane-v2/records';

  // L'API plafonne 'limit' à 100 (au-delà : InvalidRESTParameterError).
  // Une page ne suffit donc pas dès que le rayon dépasse quelques
  // dizaines de kilomètres : on enchaîne les pages via 'offset'.
  static const int _pageSize = 100;
  static const int _maxPages = 10;

  // Requête générique + gestion d'erreur lisible
  Future<List<Station>> _fetch(
    Map<String, String> params,
    double userLat,
    double userLon, {
    bool paginate = true,
  }) async {
    final all = <Station>[];

    for (var page = 0; page < (paginate ? _maxPages : 1); page++) {
      final Uri uri = Uri.https(_host, _path, {
        ...params,
        'limit': '$_pageSize',
        if (page > 0) 'offset': '${page * _pageSize}',
      });
      final response =
          await http.get(uri).timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        // Une page suivante refusée n'invalide pas ce qui est déjà là
        // (l'API limite offset+limit à 10 000).
        if (page > 0) break;
        final body = response.body.length > 300
            ? response.body.substring(0, 300)
            : response.body;
        throw Exception('HTTP ${response.statusCode} — $body');
      }

      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final List<dynamic> records = jsonResponse['results'] ?? [];
      if (records.isEmpty) break;

      all.addAll(records
          .map((r) =>
              Station.fromJson(r as Map<String, dynamic>, userLat, userLon))
          .where((s) => s.latitude != 0 && s.longitude != 0));

      // Dernière page atteinte
      if (records.length < _pageSize) break;
    }

    all.sort((a, b) => a.distance.compareTo(b.distance));
    return all;
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
        'order_by': "distance(geom, geom'POINT($longitude $latitude)')",
      }, latitude, longitude);
    } catch (e) {
      throw Exception('Erreur lors de la récupération des stations: $e');
    }
  }

  // Repli : les 100 premières stations sans filtre géographique
  Future<List<Station>> getAllStations(double latitude, double longitude) async {
    try {
      return await _fetch({}, latitude, longitude);
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
      }, latitude, longitude);
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }
}
