import 'dart:math';
import 'locatable.dart';

/// Une station de recharge = un ou plusieurs points de charge (pdc).
/// Le fichier source IRVE contient une ligne par point de charge ; on les
/// regroupe ici par id_station_itinerance pour afficher une carte par lieu
/// physique plutôt qu'une carte par prise.
class ChargingStation implements Locatable {
  final String id; // id_station_itinerance
  final String name;
  final String address;
  final String operatorName;
  final String amenageurName; // aménageur déclaré, distinct de l'opérateur
  final double latitude;
  final double longitude;
  final double distance;

  final int pointCount; // nombre de points de charge sur le site
  final double maxPowerKw; // puissance la plus élevée disponible sur site
  final Set<String> connectorTypes; // ex: {'Combo CCS', 'Type 2', 'CHAdeMO'}
  final bool free;
  final bool cardPayment;
  final String accessCondition; // ex: "Accès libre", "Réservé aux abonnés"
  final bool wheelchairAccess;
  final String hours;
  final String lastUpdate;

  ChargingStation({
    required this.id,
    required this.name,
    required this.address,
    required this.operatorName,
    required this.amenageurName,
    required this.latitude,
    required this.longitude,
    required this.distance,
    required this.pointCount,
    required this.maxPowerKw,
    required this.connectorTypes,
    required this.free,
    required this.cardPayment,
    required this.accessCondition,
    required this.wheelchairAccess,
    required this.hours,
    required this.lastUpdate,
  });

  /// Nom d'affichage. Le champ nom_station est saisi librement par
  /// l'opérateur et contient parfois une commune erronée : une station
  /// située 217 Avenue de Provence à Valence est ainsi déclarée
  /// "Valenciennes, France". On privilégie donc consolidated_commune,
  /// recalculée à partir des coordonnées, et on ne retient nom_station
  /// que s'il apporte une précision (nom de lieu, d'enseigne...).
  static String _buildName(Map<String, dynamic> r) {
    final commune = (r['consolidated_commune'] ?? '').toString().trim();
    final station = (r['nom_station'] ?? '').toString().trim();
    final enseigne = (r['nom_enseigne'] ?? '').toString().trim();

    if (commune.isEmpty) {
      return station.isNotEmpty
          ? station
          : (enseigne.isNotEmpty ? enseigne : 'Station');
    }
    if (station.isEmpty) return commune;

    // On retire le suffixe ", France" puis on compare le libellé à la
    // commune, sans accents ni ponctuation.
    // ", France" apparaît aussi en milieu de libellé
    // ("Valence, France - Chemin de la Sonacotral") : on le retire dans
    // tous les cas, y compris ceux où le libellé brut est conservé.
    final label = station
        .replaceAll(RegExp(r',\s*France\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bFrance\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s*[-–—]\s*$'), '')
        .replaceAll(RegExp(r'^[\s,\-–—]+|[\s,\-–—]+$'), '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();

    final normLabel = _normalize(label);
    final normCommune = _normalize(commune);

    // Le libellé nomme la même commune : il n'apporte rien de plus. On
    // ajoute alors la voie, sinon deux stations de la même commune
    // s'affichent avec un libellé strictement identique.
    if (normLabel == normCommune) return _withStreet(commune, r);

    // Le libellé contient déjà la commune (ex. "Aire de Portes-Lès-
    // Valence Ouest") : il se suffit à lui-même, pas de préfixe.
    if (normLabel.contains(normCommune)) return label;

    // Le libellé désigne une autre commune et rien d'autre : il est
    // probablement erroné (cas "Valenciennes, France" à Valence).
    final motsUtiles = RegExp(
        r'(aire|chemin|rue|avenue|route|parking|centre|zone|place|nord|sud|est|ouest)',
        caseSensitive: false);
    if (!label.contains(RegExp(r'[0-9]')) &&
        !motsUtiles.hasMatch(label) &&
        label.split(RegExp(r'[\s,\-]+')).length <= 2) {
      return _withStreet(commune, r);
    }

    // Sinon, le libellé est un complément utile (voie, enseigne...).
    return '$commune — $label';
  }

  /// Complète le nom d'une commune par la voie, pour distinguer deux
  /// stations situées dans la même ville.
  static String _withStreet(String commune, Map<String, dynamic> r) {
    final adresse = (r['adresse_station'] ?? '').toString().trim();
    if (adresse.isEmpty) return commune;

    // On retire le numéro et le code postal + commune éventuellement
    // présents dans l'adresse, pour ne garder que le nom de la voie.
    var voie = adresse
        .replaceAll(RegExp(r'^\s*\d+\s*(bis|ter)?[,\s]*',
            caseSensitive: false), '')
        .replaceAll(RegExp(r'\b\d{5}\b.*$'), '')
        .replaceAll(RegExp(r'[,;]\s*$'), '')
        .trim();

    if (voie.isEmpty || _normalize(voie) == _normalize(commune)) {
      return commune;
    }
    return '$commune — $voie';
  }

  /// Minuscule sans accents ni ponctuation, pour comparer des noms de
  /// lieux écrits différemment ("Etoile-sur-Rhone" / "Étoile-sur-Rhône").
  static String _normalize(String v) {
    const accents = 'àâäáãåçéèêëíìîïñóòôöõúùûüýÿ';
    const plains  = 'aaaaaaceeeeiiiinooooouuuuyy';
    var out = v.toLowerCase();
    for (var i = 0; i < accents.length; i++) {
      out = out.replaceAll(accents[i], plains[i]);
    }
    return out.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  /// Vrai si la station appartient au réseau Tesla Supercharger. On
  /// vérifie plusieurs champs (opérateur, aménageur, nom de la station)
  /// car selon les déclarations, "Tesla" peut apparaître dans l'un ou
  /// l'autre.
  /// S'appuie sur l'opérateur et l'aménageur (valeurs normalisées dans
  /// le fichier : "Tesla" ou "TESLA France SARL"), et non sur le nom
  /// affiché, qui est recomposé à partir de la commune.
  bool get isTesla {
    final haystack = '$operatorName $amenageurName'.toLowerCase();
    return haystack.contains('tesla');
  }

  /// Catégorie d'usage courant, dérivée de la puissance maximale.
  String get powerCategory {
    if (maxPowerKw >= 150) return 'Ultra-rapide';
    if (maxPowerKw >= 50) return 'Rapide';
    if (maxPowerKw >= 22) return 'Accéléré';
    return 'Standard';
  }

  /// Regroupe des lignes brutes (une par point de charge) en stations.
  static List<ChargingStation> fromRecords(
    List<Map<String, dynamic>> records,
    double userLat,
    double userLon,
  ) {
    final Map<String, List<Map<String, dynamic>>> byStation = {};

    for (final r in records) {
      final stationId = (r['id_station_itinerance'] ??
              r['id_station_local'] ??
              r['nom_station'] ??
              '')
          .toString();
      if (stationId.isEmpty) continue;

      // La clé inclut les coordonnées arrondies (~100 m), et pas
      // seulement l'identifiant : dans ce fichier, plusieurs stations
      // géographiquement distinctes partagent parfois le même
      // id_station_itinerance (défaut de qualité connu de l'IRVE).
      // Regrouper sur l'identifiant seul fusionnait par exemple la
      // station de Valenciennes avec une station de Valence, en
      // retenant les coordonnées de la première ligne rencontrée.
      final coords = _parseCoords(r);
      if (coords == null) continue;
      final key = '$stationId@'
          '${coords[0].toStringAsFixed(3)},${coords[1].toStringAsFixed(3)}';

      byStation.putIfAbsent(key, () => []).add(r);
    }

    // Le fichier consolidé agrège plusieurs sources : un même point de
    // charge peut y figurer en double (id_pdc_itinerance identique). On
    // dédoublonne avant de compter, sinon une station affiche plus de
    // bornes qu'elle n'en possède réellement.
    byStation.updateAll((key, rows) {
      final seen = <String>{};
      final unique = <Map<String, dynamic>>[];
      for (final r in rows) {
        final pdcId = (r['id_pdc_itinerance'] ?? r['id_pdc_local'] ?? '')
            .toString();
        if (pdcId.isNotEmpty && !seen.add(pdcId)) continue;
        unique.add(r);
      }
      return unique;
    });

    final stations = <ChargingStation>[];
    byStation.forEach((key, rows) {
      final first = rows.first;
      final coords = _parseCoords(first);
      if (coords == null) return;

      final id = key.split('@').first;

      final connectors = <String>{};
      double maxPower = 0;
      var anyFree = false;
      var anyCard = false;
      for (final r in rows) {
        final p = _toDouble(r['puissance_nominale']);
        if (p != null && p > maxPower) maxPower = p;
        if (_toBool(r['prise_type_2']) == true) connectors.add('Type 2');
        if (_toBool(r['prise_type_combo_ccs']) == true) {
          connectors.add('Combo CCS');
        }
        if (_toBool(r['prise_type_chademo']) == true) {
          connectors.add('CHAdeMO');
        }
        if (_toBool(r['prise_type_ef']) == true) connectors.add('Prise E/F');
        if (_toBool(r['prise_type_autre']) == true) connectors.add('Autre');
        if (_toBool(r['gratuit']) == true) anyFree = true;
        if (_toBool(r['paiement_cb']) == true) anyCard = true;
      }

      // nbre_pdc est censé donner le nombre de points de charge de la
      // station, mais certains opérateurs (Tesla notamment) déclarent 1
      // sur chaque ligne alors que chaque ligne EST un point de charge.
      // On prend donc la valeur la plus grande entre le nombre déclaré
      // et le nombre de lignes réellement regroupées.
      final declaredCount = int.tryParse('${first['nbre_pdc'] ?? ''}') ?? 0;
      final pointCount =
          declaredCount > rows.length ? declaredCount : rows.length;

      stations.add(ChargingStation(
        id: id,
        name: _buildName(first),
        address: (first['adresse_station'] ?? '').toString(),
        operatorName:
            (first['nom_operateur'] ?? first['nom_amenageur'] ?? '')
                .toString(),
        amenageurName: (first['nom_amenageur'] ?? '').toString(),
        latitude: coords[0],
        longitude: coords[1],
        distance: _distanceKm(userLat, userLon, coords[0], coords[1]),
        pointCount: pointCount,
        maxPowerKw: maxPower,
        connectorTypes: connectors,
        free: anyFree,
        cardPayment: anyCard,
        accessCondition: (first['condition_acces'] ?? '').toString(),
        // Champ descriptif ("Accessible mais non réservé PMR",
        // "Non accessible"...), pas un booléen : on teste le sens du
        // texte plutôt que d'en attendre true/false.
        wheelchairAccess: _pmrAccessible(first['accessibilite_pmr']),
        hours: (first['horaires'] ?? '').toString(),
        lastUpdate: (first['date_maj'] ?? '').toString(),
      ));
    });

    stations.sort((a, b) => a.distance.compareTo(b.distance));
    return stations;
  }

  /// Extraction des coordonnées.
  ///
  /// ATTENTION : ce jeu de données stocke sa géométrie avec latitude et
  /// longitude INVERSÉES par rapport au standard GeoJSON. Vérifié sur les
  /// données réelles : pour La Roche-sur-Yon,
  ///   coordonneesxy        = [-1.4312283, 46.6902177]  (lon, lat) OK
  ///   geometry.coordinates = [46.6902177, -1.4312283]  (lat, lon) inversé
  /// On privilégie donc consolidated_latitude / consolidated_longitude,
  /// dont les noms lèvent toute ambiguïté, et on n'utilise jamais le champ
  /// geometry.
  static List<double>? _parseCoords(Map<String, dynamic> r) {
    final cLat = _toDouble(r['consolidated_latitude']);
    final cLon = _toDouble(r['consolidated_longitude']);
    if (cLat != null && cLon != null && cLat != 0 && cLon != 0) {
      return [cLat, cLon];
    }

    final raw = r['coordonneesxy'] ?? r['coordonneesXY'];
    if (raw is String) {
      final cleaned = raw.replaceAll('[', '').replaceAll(']', '');
      final parts = cleaned.split(',');
      if (parts.length == 2) {
        final lon = double.tryParse(parts[0].trim());
        final lat = double.tryParse(parts[1].trim());
        if (lat != null && lon != null) return [lat, lon];
      }
    }
    if (raw is List && raw.length == 2) {
      final lon = _toDouble(raw[0]);
      final lat = _toDouble(raw[1]);
      if (lat != null && lon != null) return [lat, lon];
    }

    for (final key in ['geo_point_2d', 'geo_point']) {
      final g = r[key];
      if (g is Map) {
        final lat = _toDouble(g['lat']);
        final lon = _toDouble(g['lon'] ?? g['long']);
        if (lat != null && lon != null) return [lat, lon];
      }
    }
    return null;
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '.'));
  }

  /// Le champ accessibilite_pmr du schéma IRVE est un libellé, par ex.
  /// "Accessible mais non réservé PMR" ou "Non accessible". On considère
  /// la station accessible si le texte contient "accessible" sans être
  /// nié par "non accessible".
  static bool _pmrAccessible(dynamic v) {
    if (v == null) return false;
    final s = v.toString().toLowerCase();
    if (s.contains('non accessible')) return false;
    return s.contains('accessible');
  }

  static bool? _toBool(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    final s = v.toString().trim().toLowerCase();
    return s == 'true' || s == 'oui' || s == '1';
  }

  static double _distanceKm(
      double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * asin(min(1.0, sqrt(a)));
  }

  static double _rad(double deg) => deg * pi / 180;
}
