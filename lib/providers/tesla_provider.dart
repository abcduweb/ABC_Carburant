import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/charging_station.dart';
import '../services/charging_api_service.dart';
import '../services/location_service.dart';
import 'fuel_provider.dart' show AppError, AppErrorKind;

/// Superchargers Tesla — même source que les bornes électriques (ODRÉ /
/// fichier IRVE), filtrée sur l'opérateur ou l'aménageur "Tesla". Les
/// stations Tesla ouvertes au public sont légalement déclarées dans ce
/// fichier au même titre que les autres réseaux, donc pas besoin d'une
/// source de données séparée.
class TeslaProvider with ChangeNotifier {
  final ChargingApiService _apiService = ChargingApiService();

  List<ChargingStation> _stations = [];
  bool _isLoading = false;
  AppError? _error;
  double? _currentLat;
  double? _currentLon;
  double _radiusKm = 50; // reseau plus clairsemé qu'un réseau généraliste
  String _sortBy = 'distance'; // 'distance' ou 'power'
  Set<String> _favorites = {};

  List<ChargingStation> get stations => _stations;
  bool get isLoading => _isLoading;
  AppError? get error => _error;
  double? get currentLat => _currentLat;
  double? get currentLon => _currentLon;
  double get radiusKm => _radiusKm;
  String get sortBy => _sortBy;

  bool isFavorite(String id) => _favorites.contains(id);

  List<ChargingStation> get filteredStations {
    final filtered = _stations.toList();
    if (_sortBy == 'power') {
      filtered.sort((a, b) => b.maxPowerKw.compareTo(a.maxPowerKw));
    } else {
      filtered.sort((a, b) => a.distance.compareTo(b.distance));
    }
    return filtered;
  }

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _radiusKm = prefs.getDouble('tesla_radius_km') ?? 50;
    _sortBy = prefs.getString('tesla_sort_by') ?? 'distance';
    final favs = prefs.getStringList('tesla_favorites') ?? [];
    _favorites = favs.toSet();
    notifyListeners();
  }

  Future<void> initializeAndLoad({double? lat, double? lon}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (lat != null && lon != null) {
        _currentLat = lat;
        _currentLon = lon;
      } else {
        final position = await LocationService.getCurrentPosition();
        _currentLat = position.latitude;
        _currentLon = position.longitude;
      }
      await loadNearbyStations();
    } on LocationException catch (e) {
      _error = _mapLocationFailure(e.failure);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = AppError(AppErrorKind.unknown, e.toString());
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadNearbyStations({double? radiusKm}) async {
    if (_currentLat == null || _currentLon == null) {
      return initializeAndLoad();
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 'tesla' est appliqué par le serveur : sans lui, les lignes
      // ramenées sont dominées par les autres opérateurs et presque
      // aucune station Tesla ne survit au filtrage local.
      // Le filtre isTesla reste appliqué ensuite pour écarter les
      // éventuelles correspondances textuelles fortuites.
      final all = await _apiService.getStationsNearby(
        _currentLat!,
        _currentLon!,
        radiusKm: radiusKm ?? _radiusKm,
        query: 'tesla',
      );
      _stations = all.where((s) => s.isTesla).toList();
      if (_stations.isEmpty) _error = const AppError(AppErrorKind.empty);
    } catch (e) {
      _error = _mapApiError(e);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setRadius(double km) async {
    if (km == _radiusKm) return;
    _radiusKm = km;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tesla_radius_km', km);
    await loadNearbyStations();
  }

  Future<void> setSortBy(String sortBy) async {
    _sortBy = sortBy;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tesla_sort_by', sortBy);
  }

  Future<void> toggleFavorite(String stationId) async {
    if (_favorites.contains(stationId)) {
      _favorites.remove(stationId);
    } else {
      _favorites.add(stationId);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('tesla_favorites', _favorites.toList());
  }

  Future<void> refresh() => loadNearbyStations();

  AppError _mapLocationFailure(LocationFailure f) {
    switch (f) {
      case LocationFailure.serviceDisabled:
        return const AppError(AppErrorKind.locationServiceDisabled);
      case LocationFailure.denied:
        return const AppError(AppErrorKind.locationDenied);
      case LocationFailure.deniedForever:
        return const AppError(AppErrorKind.locationDeniedForever);
      case LocationFailure.timeout:
        return const AppError(AppErrorKind.locationTimeout);
      case LocationFailure.unknown:
        return const AppError(AppErrorKind.unknown);
    }
  }

  AppError _mapApiError(Object e) {
    if (e is SocketException) return const AppError(AppErrorKind.network);
    if (e is TimeoutException) return const AppError(AppErrorKind.network);
    final msg = e.toString();
    if (msg.contains('SocketException') ||
        msg.contains('Failed host lookup') ||
        msg.contains('TimeoutException')) {
      return const AppError(AppErrorKind.network);
    }
    if (msg.contains('HTTP 5') || msg.contains('surchargé')) {
      return const AppError(AppErrorKind.server);
    }
    return AppError(AppErrorKind.unknown, msg);
  }
}
