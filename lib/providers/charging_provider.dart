import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/charging_station.dart';
import '../services/charging_api_service.dart';
import '../services/location_service.dart';
import 'fuel_provider.dart' show AppError, AppErrorKind;

class ChargingProvider with ChangeNotifier {
  final ChargingApiService _apiService = ChargingApiService();

  List<ChargingStation> _stations = [];
  bool _isLoading = false;
  AppError? _error;
  double? _currentLat;
  double? _currentLon;
  double _radiusKm = 20;
  String _sortBy = 'distance'; // 'distance' ou 'power'
  bool _freeOnly = false;
  bool _fastOnly = false; // >= 50 kW
  Set<String> _favorites = {};

  List<ChargingStation> get stations => _stations;
  bool get isLoading => _isLoading;
  AppError? get error => _error;
  double? get currentLat => _currentLat;
  double? get currentLon => _currentLon;
  double get radiusKm => _radiusKm;
  String get sortBy => _sortBy;
  bool get freeOnly => _freeOnly;
  bool get fastOnly => _fastOnly;

  bool isFavorite(String id) => _favorites.contains(id);

  List<ChargingStation> get filteredStations {
    var filtered = _stations.toList();

    if (_freeOnly) filtered = filtered.where((s) => s.free).toList();
    if (_fastOnly) {
      filtered = filtered.where((s) => s.maxPowerKw >= 50).toList();
    }

    if (_sortBy == 'power') {
      filtered.sort((a, b) => b.maxPowerKw.compareTo(a.maxPowerKw));
    } else {
      filtered.sort((a, b) => a.distance.compareTo(b.distance));
    }
    return filtered;
  }

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _radiusKm = prefs.getDouble('charging_radius_km') ?? 20;
    _sortBy = prefs.getString('charging_sort_by') ?? 'distance';
    _freeOnly = prefs.getBool('charging_free_only') ?? false;
    _fastOnly = prefs.getBool('charging_fast_only') ?? false;
    final favs = prefs.getStringList('charging_favorites') ?? [];
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
      _stations = await _apiService.getStationsNearby(
        _currentLat!,
        _currentLon!,
        radiusKm: radiusKm ?? _radiusKm,
      );
      if (_stations.isEmpty) _error = const AppError(AppErrorKind.empty);
    } catch (e) {
      _error = _mapApiError(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> searchByLocation(String location) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _stations = await _apiService.searchByLocation(
        location,
        _currentLat ?? 46.6,
        _currentLon ?? 2.3,
      );
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
    await prefs.setDouble('charging_radius_km', km);
    await loadNearbyStations();
  }

  Future<void> setSortBy(String sortBy) async {
    _sortBy = sortBy;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('charging_sort_by', sortBy);
  }

  Future<void> toggleFreeOnly() async {
    _freeOnly = !_freeOnly;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('charging_free_only', _freeOnly);
  }

  Future<void> toggleFastOnly() async {
    _fastOnly = !_fastOnly;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('charging_fast_only', _fastOnly);
  }

  Future<void> toggleFavorite(String stationId) async {
    if (_favorites.contains(stationId)) {
      _favorites.remove(stationId);
    } else {
      _favorites.add(stationId);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('charging_favorites', _favorites.toList());
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
    if (msg.contains('HTTP 5') || msg.contains('HTTP 4')) {
      return const AppError(AppErrorKind.server);
    }
    return AppError(AppErrorKind.unknown, msg);
  }
}
