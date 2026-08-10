import 'package:shared_preferences/shared_preferences.dart';

/// Favoris stockés localement, par identifiant de station.
class FavoritesService {
  static const String _key = 'favorite_stations';

  static Future<Set<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? []).toSet();
  }

  static Future<void> save(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, ids.toList());
  }
}
