import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/station.dart';

/// Ouverture d'un itinéraire vers une station dans Google Maps ou Waze.
class NavigationService {
  static Future<bool> _open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> openGoogleMaps(Station s) async {
    // Application native si présente, sinon navigateur
    final app = Uri.parse(
        'google.navigation:q=${s.latitude},${s.longitude}&mode=d');
    if (await canLaunchUrl(app)) {
      if (await _open(app)) return true;
    }
    return _open(Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${s.latitude},${s.longitude}&travelmode=driving'));
  }

  static Future<bool> openWaze(Station s) async {
    final app = Uri.parse('waze://?ll=${s.latitude},${s.longitude}&navigate=yes');
    if (await canLaunchUrl(app)) {
      if (await _open(app)) return true;
    }
    return _open(Uri.parse(
        'https://waze.com/ul?ll=${s.latitude},${s.longitude}&navigate=yes'));
  }

  /// Feuille de choix Google Maps / Waze / appli par défaut.
  static void showChoice(BuildContext context, Station s) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Itinéraire vers ${s.name}',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.map, color: Colors.green),
              title: const Text('Google Maps'),
              onTap: () async {
                Navigator.pop(sheetContext);
                final ok = await openGoogleMaps(s);
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Impossible d\'ouvrir Google Maps')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.navigation, color: Colors.lightBlue),
              title: const Text('Waze'),
              onTap: () async {
                Navigator.pop(sheetContext);
                final ok = await openWaze(s);
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Waze n\'est pas installé')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.open_in_new, color: Colors.grey),
              title: const Text('Autre application'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await _open(Uri.parse(
                    'geo:${s.latitude},${s.longitude}?q=${s.latitude},${s.longitude}(${Uri.encodeComponent(s.name)})'));
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
