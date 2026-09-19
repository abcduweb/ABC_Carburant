import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/station.dart';
import '../services/fuel_api_service.dart';
import '../services/location_service.dart';
import '../services/favorites_service.dart';
import '../services/price_history_service.dart';
import '../services/savings_service.dart';

enum AppErrorKind {
  locationServiceDisabled,
  locationDenied,
  locationDeniedForever,
  locationTimeout,
  network,
  server,
  empty,
  unknown,
}

class AppError {
  final AppErrorKind kind;
  final String? detail;
  const AppError(this.kind, [this.detail]);
}

class FuelProvider with ChangeNotifier {
  final FuelApiService _apiService = FuelApiService();

  List<Station> _stations = [];
  bool _isLoading = false;
  AppError? _error;
  double? _currentLat;
  double? _currentLon;
  String _selectedFuelType = 'Gazole';
  String _sortBy = 'distance';
  double _radiusKm = 20;
  bool _favoritesOnly = false;
  Set<String> _favorites = {};
  bool _introSeen = false;
  VehicleSettings _vehicle = const VehicleSettings();

  List<Station> get stations => _stations;
  bool get isLoading => _isLoading;
  AppError? get error => _error;
  double? get currentLat => _currentLat;
  double? get currentLon => _currentLon;
  String get selectedFuelType => _selectedFuelType;
  String get sortBy => _sortBy;
  double get radiusKm => _radiusKm;
  bool get favoritesOnly => _favoritesOnly;
  Set<String> get favorites => _favorites;
  bool get introSeen => _introSeen;
  VehicleSettings get vehicle => _vehicle;

  /// Station de référence : la plus proche vendant le carburant choisi.
  Station? get referenceStation =>
      SavingsCalculator.reference(_stations, _selectedFuelType);

  /// Gain net pour une station, détour déduit.
  Savings? savingsFor(Station station) => SavingsCalculator.compute(
        station: station,
        reference: referenceStation,
        fuelType: _selectedFuelType,
        settings: _vehicle,
      );

  Future<void> setVehicle(VehicleSettings v) async {
    _vehicle = v;
    notifyListeners();
    await v.save();
  }

  bool isFavorite(String id) => _favorites.contains(id);

  List<Station> get filteredStations {
    var filtered = _stations
        .where((s) => s.prices.containsKey(_selectedFuelType))
        .toList();

    if (_favoritesOnly) {
      filtered = filtered.where((s) => _favorites.contains(s.id)).toList();
    }

    if (_sortBy == 'price') {
      filtered.sort((a, b) {
        final pa = a.prices[_selectedFuelType]?.price ?? double.infinity;
        final pb = b.prices[_selectedFuelType]?.price ?? double.infinity;
        return pa.compareTo(pb);
      });
    } else if (_sortBy == 'savings') {
      final ref = SavingsCalculator.reference(_stations, _selectedFuelType);
      double gain(Station s) =>
          SavingsCalculator.compute(
            station: s,
            reference: ref,
            fuelType: _selectedFuelType,
            settings: _vehicle,
          )?.net ??
          double.negativeInfinity;
      filtered.sort((a, b) => gain(b).compareTo(gain(a)));
    } else {
      filtered.sort((a, b) => a.distance.compareTo(b.distance));
    }

    return filtered;
  }

  /// Préférences et favoris relus au démarrage.
  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedFuelType = prefs.getString('fuel_type') ?? 'Gazole';
    _sortBy = prefs.getString('sort_by') ?? 'distance';
    _radiusKm = prefs.getDouble('radius_km') ?? 20;
    _introSeen = prefs.getBool('intro_seen') ?? false;
    _favorites = await FavoritesService.load();
    _vehicle = await VehicleSettings.load();
    notifyListeners();
  }

  Future<void> markIntroSeen() async {
    _introSeen = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('intro_seen', true);
    notifyListeners();
  }

  Future<void> initializeAndLoad() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final position = await LocationService.getCurrentPosition();
      _currentLat = position.latitude;
      _currentLon = position.longitude;
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
      _recordFavoritesHistory();
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
      _recordFavoritesHistory();
    } catch (e) {
      _error = _mapApiError(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> selectFuelType(String fuelType) async {
    _selectedFuelType = fuelType;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fuel_type', fuelType);
  }

  Future<void> setSortBy(String sortBy) async {
    _sortBy = sortBy;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sort_by', sortBy);
  }

  Future<void> setRadius(double km) async {
    if (km == _radiusKm) return;
    _radiusKm = km;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('radius_km', km);
    await loadNearbyStations();
  }

  void toggleFavoritesOnly() {
    _favoritesOnly = !_favoritesOnly;
    notifyListeners();
  }

  /// Mémorise les prix des seules stations favorites. Suivre toutes les
  /// stations rencontrées ferait grossir le stockage sans fin.
  void _recordFavoritesHistory() {
    if (_favorites.isEmpty) return;
    for (final s in _stations) {
      if (_favorites.contains(s.id)) {
        PriceHistoryService.recordStation(s);
      }
    }
  }

  Future<void> toggleFavorite(String stationId) async {
    if (_favorites.contains(stationId)) {
      _favorites.remove(stationId);
      // L'historique n'a plus lieu d'être conservé.
      await PriceHistoryService.clearStation(stationId);
    } else {
      _favorites.add(stationId);
      // Premier relevé immédiat, pour ne pas attendre le prochain
      // rafraîchissement.
      final station = _stations.where((s) => s.id == stationId);
      if (station.isNotEmpty) {
        await PriceHistoryService.recordStation(station.first);
      }
    }
    notifyListeners();
    await FavoritesService.save(_favorites);
  }

  Future<void> refresh() => loadNearbyStations();

  // --- Traduction des exceptions en erreurs affichables ---

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
