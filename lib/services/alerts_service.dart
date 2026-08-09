import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/station.dart';
import 'fuel_api_service.dart';
import 'favorites_service.dart';

/// Une alerte : prévenir quand un carburant passe sous un seuil.
class PriceAlert {
  final String fuelType;
  final double threshold;
  final bool favoritesOnly;

  const PriceAlert({
    required this.fuelType,
    required this.threshold,
    this.favoritesOnly = true,
  });

  Map<String, dynamic> toJson() => {
        'fuelType': fuelType,
        'threshold': threshold,
        'favoritesOnly': favoritesOnly,
      };

  factory PriceAlert.fromJson(Map<String, dynamic> j) => PriceAlert(
        fuelType: j['fuelType'] ?? 'Gazole',
        threshold: (j['threshold'] as num?)?.toDouble() ?? 1.80,
        favoritesOnly: j['favoritesOnly'] ?? true,
      );
}

class AlertsService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _kAlerts = 'price_alerts';
  static const String _kEnabled = 'alerts_enabled';
  static const String _kLastNotified = 'alerts_last_notified';

  // ---------- Initialisation ----------

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  static Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? true;
  }

  // ---------- Persistance ----------

  static Future<List<PriceAlert>> loadAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kAlerts) ?? [];
    return raw.map((s) => PriceAlert.fromJson(json.decode(s))).toList();
  }

  static Future<void> saveAlerts(List<PriceAlert> alerts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _kAlerts, alerts.map((a) => json.encode(a.toJson())).toList());
  }

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kEnabled) ?? false;
  }

  /// Active ou coupe les alertes.
  static Future<void> setEnabled(bool value,
      {double? lat, double? lon, double? radiusKm}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, value);

    if (value && lat != null && lon != null) {
      await prefs.setDouble('alert_lat', lat);
      await prefs.setDouble('alert_lon', lon);
      await prefs.setDouble('alert_radius', radiusKm ?? 20);
    }
  }

  /// Vérification déclenchée à l'ouverture de l'application, au plus une
  /// fois par heure pour ne pas solliciter l'API inutilement.
  static Future<void> checkOnLaunch() async {
    if (!await isEnabled()) return;

    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt('alerts_last_run') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - last < const Duration(hours: 1).inMilliseconds) return;

    await prefs.setInt('alerts_last_run', now);
    await check();
  }

  // ---------- Vérification ----------

  /// Exécutée en arrière-plan comme au premier plan.
  /// Retourne le nombre de notifications émises.
  static Future<int> check() async {
    final alerts = await loadAlerts();
    if (alerts.isEmpty) return 0;

    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('alert_lat');
    final lon = prefs.getDouble('alert_lon');
    if (lat == null || lon == null) return 0;

    final radius = prefs.getDouble('alert_radius') ?? 20;
    final favorites = await FavoritesService.load();

    List<Station> stations;
    try {
      stations = await FuelApiService()
          .getStationsNearby(lat, lon, radiusKm: radius);
    } catch (_) {
      return 0;
    }

    // Évite de renotifier la même station au même prix
    final alreadySent = (prefs.getStringList(_kLastNotified) ?? []).toSet();
    final sentNow = <String>{};
    var count = 0;

    for (final alert in alerts) {
      final candidates = stations.where((s) {
        if (alert.favoritesOnly && !favorites.contains(s.id)) return false;
        final p = s.prices[alert.fuelType];
        return p != null && !p.isStale && p.price <= alert.threshold;
      }).toList()
        ..sort((a, b) => a.prices[alert.fuelType]!.price
            .compareTo(b.prices[alert.fuelType]!.price));

      if (candidates.isEmpty) continue;

      final best = candidates.first;
      final price = best.prices[alert.fuelType]!.price;
      final signature = '${best.id}|${alert.fuelType}|${price.toStringAsFixed(3)}';
      sentNow.add(signature);
      if (alreadySent.contains(signature)) continue;

      await _notify(
        id: signature.hashCode & 0x7FFFFFFF,
        title: '${alert.fuelType} à ${price.toStringAsFixed(3)} €',
        body: '${best.name} — ${best.distance.toStringAsFixed(1)} km'
            '${candidates.length > 1 ? ' (+${candidates.length - 1} autre(s))' : ''}',
      );
      count++;
    }

    await prefs.setStringList(_kLastNotified, sentNow.toList());
    return count;
  }

  static Future<void> _notify({
    required int id,
    required String title,
    required String body,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'price_alerts',
        'Alertes de prix',
        channelDescription: 'Notification quand un carburant passe sous '
            'votre seuil',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(id, title, body, details);
  }
}
