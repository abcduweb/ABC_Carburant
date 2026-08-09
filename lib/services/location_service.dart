import 'package:geolocator/geolocator.dart';

/// Cause précise d'un échec de géolocalisation, pour afficher un écran
/// adapté plutôt qu'un message d'erreur brut.
enum LocationFailure {
  serviceDisabled, // GPS coupé sur l'appareil
  denied, // refusée cette fois, redemandable
  deniedForever, // refusée définitivement, il faut passer par les réglages
  timeout, // pas de fix GPS dans le délai imparti
  unknown,
}

class LocationException implements Exception {
  final LocationFailure failure;
  LocationException(this.failure);
}

class LocationService {
  static Future<bool> isLocationServiceEnabled() =>
      Geolocator.isLocationServiceEnabled();

  static Future<LocationPermission> checkPermission() =>
      Geolocator.checkPermission();

  /// Ouvre les réglages système de l'application.
  static Future<bool> openAppSettings() => Geolocator.openAppSettings();

  /// Ouvre les réglages de localisation de l'appareil.
  static Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  /// Position actuelle. Lève une [LocationException] qualifiée en cas d'échec.
  static Future<Position> getCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw LocationException(LocationFailure.serviceDisabled);
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationException(LocationFailure.deniedForever);
    }
    if (permission == LocationPermission.denied) {
      throw LocationException(LocationFailure.denied);
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
    } catch (_) {
      // Dernier recours : la dernière position connue évite un écran vide
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return last;
      throw LocationException(LocationFailure.timeout);
    }
  }

  static double calculateDistance(
          double lat1, double lon1, double lat2, double lon2) =>
      Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
}
