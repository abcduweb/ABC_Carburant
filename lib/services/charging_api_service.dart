import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/charging_station.dart';

/// Bornes de recharge électrique — Open Data Réseaux Énergies (ODRÉ),
/// consolidation nationale du fichier IRVE (schéma officiel Etalab).
/// Portail public, sans clé, même famille d'API que data.economie.gouv.fr.
///
/// PARTICULARITÉ DE CE JEU DE DONNÉES (vérifiée sur les données réelles) :
/// la géométrie est stockée avec latitude et longitude INVERSÉES par
/// rapport au standard GeoJSON. Pour La Roche-sur-Yon :
///   coordonneesxy        = [-1.4312283, 46.6902177]  (lon, lat) correct
///   geometry.coordinates = [46.6902177, -1.4312283]  (lat, lon) inversé
///
/// Conséquences :
///  - on ignore complètement le champ geometry, et on lit les
///    coordonnées via consolidated_latitude / consolidated_longitude ;
///  - le filtre serveur geofilter.distance interroge le champ géo
///    inversé : on lui passe donc volontairement les coordonnées dans
///    l'ordre inverse. Si cette requête ne renvoie rien (comportement du
///    portail susceptible de changer), on bascule sur une pagination
///    simple avec filtrage par distance côté client.
class ChargingApiService {
  static const String _host = 'odre.opendatasoft.com';
  static const String _path = '/api/records/1.0/search/';
  static const String _dataset = 'bornes-irve';

  static const int _pageSize = 200;
  static const int _maxPages = 15;

  Future<Map<String, dynamic>> _get(Map<String, String> params) async {
    final uri = Uri.https(_host, _path, {'dataset': _dataset, ...params});
    final response = await http.get(uri).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      final body = response.body.length > 300
          ? response.body.substring(0, 300)
          : response.body;
      throw Exception('HTTP ${response.statusCode} — $body');
    }

    final decoded = json.decode(response.body);
    if (decoded is! Map<String, dynamic> || !decoded.containsKey('nhits')) {
      final body = response.body.length > 300
          ? response.body.substring(0, 300)
          : response.body;
      throw Exception('Réponse inattendue de l\'API bornes : $body');
    }
    return decoded;
  }

  /// Aplatit la réponse : on ne garde que 'fields'. Le champ 'geometry'
  /// est volontairement ignoré (latitude/longitude inversées, voir
  /// commentaire de classe) — les coordonnées fiables sont dans
  /// consolidated_latitude / consolidated_longitude.
  List<Map<String, dynamic>> _flatten(Map<String, dynamic> json_) {
    final records = (json_['records'] as List?) ?? [];
    return records
        .map((r) => Map<String, dynamic>.from(
            (r as Map<String, dynamic>)['fields'] as Map<String, dynamic>? ??
                {}))
        .toList();
  }

  /// [query] : recherche plein texte appliquée par le serveur (ex.
  /// 'tesla'). Sans elle, le quota de lignes ramenées est consommé par
  /// tous les opérateurs confondus, et un réseau minoritaire n'apparaît
  /// quasiment jamais dans le lot.
  Future<List<ChargingStation>> getStationsNearby(
    double latitude,
    double longitude, {
    double radiusKm = 20,
    String? query,
  }) async {
    try {
      final radiusM = (radiusKm * 1000).toInt();

      // 1) Filtre serveur, coordonnées volontairement inversées pour
      //    compenser l'inversion du champ géographique du jeu de données.
      //    Chaque ligne renvoyée est un POINT DE CHARGE, pas une station :
      //    une seule page ne couvre qu'une poignée de stations (celles de
      //    Valence totalisent déjà plus de 100 points). On pagine donc
      //    jusqu'à couvrir l'ensemble du rayon demandé.
      try {
        final raw = <Map<String, dynamic>>[];
        for (var page = 0; page < _maxPages; page++) {
          final json_ = await _get({
            'geofilter.distance': '$longitude,$latitude,$radiusM',
            'rows': '$_pageSize',
            'start': '${page * _pageSize}',
            if (query != null) 'q': query,
          });
          final batch = _flatten(json_);
          raw.addAll(batch);

          final nhits = (json_['nhits'] as num?)?.toInt() ?? 0;
          if (batch.isEmpty || raw.length >= nhits) break;
        }

        if (raw.isNotEmpty) {
          final stations =
              ChargingStation.fromRecords(raw, latitude, longitude);
          final nearby = stations
              .where((s) => s.distance <= radiusKm)
              .toList()
            ..sort((a, b) => a.distance.compareTo(b.distance));
          if (nearby.isNotEmpty) return nearby;
        }
      } catch (_) {
        // Filtre serveur indisponible : on passe au repli ci-dessous.
      }

      // 2) Repli : pagination simple ('rows' et 'start' uniquement), puis
      //    filtrage par distance entièrement côté client.
      final allRaw = <Map<String, dynamic>>[];
      for (var page = 0; page < _maxPages; page++) {
        final json_ = await _get({
          'rows': '$_pageSize',
          'start': '${page * _pageSize}',
          if (query != null) 'q': query,
        });
        final batch = _flatten(json_);
        allRaw.addAll(batch);

        final nhits = (json_['nhits'] as num?)?.toInt() ?? 0;
        if (allRaw.length >= nhits) break;
        if (batch.isEmpty) break;
      }

      final all = ChargingStation.fromRecords(allRaw, latitude, longitude);
      final nearby = all.where((s) => s.distance <= radiusKm).toList()
        ..sort((a, b) => a.distance.compareTo(b.distance));
      return nearby;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des bornes: $e');
    }
  }

  Future<List<ChargingStation>> searchByLocation(
    String location,
    double latitude,
    double longitude,
  ) async {
    try {
      final json_ = await _get({'q': location, 'rows': '200'});
      return ChargingStation.fromRecords(
          _flatten(json_), latitude, longitude);
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }
}
