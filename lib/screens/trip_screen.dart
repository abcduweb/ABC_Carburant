import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/station.dart';
import '../providers/fuel_provider.dart';
import '../services/navigation_service.dart';
import '../services/routing_service.dart';
import '../theme/app_theme.dart';
import '../widgets/station_card.dart';

/// Recherche des stations le long d'un itinéraire A -> B.
class TripScreen extends StatefulWidget {
  const TripScreen({Key? key}) : super(key: key);

  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> {
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();

  PlaceSuggestion? _from;
  PlaceSuggestion? _to;
  TripRoute? _route;
  List<Station> _stations = [];
  bool _loading = false;
  String? _error;
  bool _showMap = true;

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  /// Convertit le texte saisi en coordonnées.
  /// Renvoie true si un lieu a été retenu.
  Future<bool> _resolve(bool isFrom) async {
    final ctrl = isFrom ? _fromCtrl : _toCtrl;
    if (ctrl.text.trim().length < 3) {
      setState(() => _error = isFrom
          ? 'Indiquez un point de départ'
          : 'Indiquez une adresse d\'arrivée');
      return false;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    List<PlaceSuggestion> results = [];
    try {
      results = await RoutingService.search(ctrl.text);
    } catch (_) {}
    if (!mounted) return false;
    setState(() => _loading = false);

    if (results.isEmpty) {
      setState(() => _error =
          'Adresse introuvable : « ${ctrl.text} ». Essayez avec la commune '
          'seule, ou vérifiez l\'orthographe.');
      return false;
    }

    // Un seul résultat : on le retient sans faire choisir l'utilisateur
    if (results.length == 1) {
      final only = results.first;
      setState(() {
        _error = null;
        if (isFrom) {
          _from = only;
          _fromCtrl.text = only.label.split(',').first;
        } else {
          _to = only;
          _toCtrl.text = only.label.split(',').first;
        }
      });
      return true;
    }

    final chosen = await showModalBottomSheet<PlaceSuggestion>(
      context: context,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: results
              .map((p) => ListTile(
                    leading: const Icon(Icons.place_outlined),
                    title: Text(p.label, style: const TextStyle(fontSize: 14)),
                    onTap: () => Navigator.pop(context, p),
                  ))
              .toList(),
        ),
      ),
    );

    if (chosen == null) return false;
    setState(() {
      _error = null;
      if (isFrom) {
        _from = chosen;
        _fromCtrl.text = chosen.label.split(',').first;
      } else {
        _to = chosen;
        _toCtrl.text = chosen.label.split(',').first;
      }
    });
    return true;
  }

  Future<void> _useCurrentPosition() async {
    final provider = context.read<FuelProvider>();
    final lat = provider.currentLat;
    final lon = provider.currentLon;
    if (lat == null || lon == null) {
      setState(() => _error = 'Position actuelle indisponible');
      return;
    }
    setState(() {
      _from = PlaceSuggestion('Ma position', lat, lon);
      _fromCtrl.text = 'Ma position';
      _error = null;
    });
  }

  Future<void> _computeTrip() async {
    // Géocodage automatique : l'utilisateur ne doit pas avoir à valider
    // chaque champ au clavier avant de lancer la recherche.
    if (_from == null && !await _resolve(true)) return;
    if (_to == null && !await _resolve(false)) return;
    if (_from == null || _to == null) return;

    setState(() {
      _loading = true;
      _error = null;
      _stations = [];
    });

    try {
      final route = await RoutingService.route(
        GeoPoint(_from!.lat, _from!.lon),
        GeoPoint(_to!.lat, _to!.lon),
      );
      final stations = await RoutingService.stationsAlongRoute(route);
      if (!mounted) return;
      setState(() {
        _route = route;
        _stations = stations;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FuelProvider>();
    final fuel = provider.selectedFuelType;

    final onRoute = _stations
        .where((s) => s.prices.containsKey(fuel))
        .toList();
    final cheapest = onRoute.isEmpty
        ? null
        : (onRoute.toList()
              ..sort((a, b) =>
                  a.prices[fuel]!.price.compareTo(b.prices[fuel]!.price)))
            .first;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sur mon trajet'),
        actions: [
          if (_route != null)
            IconButton(
              icon: Icon(_showMap ? Icons.list : Icons.map_outlined),
              tooltip: _showMap ? 'Voir la liste' : 'Voir la carte',
              onPressed: () => setState(() => _showMap = !_showMap),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildForm(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_error!,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
            ),
          if (_loading) const LinearProgressIndicator(),
          if (_route != null) _buildSummary(onRoute.length, cheapest, fuel),
          Expanded(
            child: _route == null
                ? _buildPlaceholder()
                : (_showMap
                    ? _buildMap(onRoute, fuel, cheapest)
                    : _buildList(onRoute, cheapest)),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _fromCtrl,
                  decoration: InputDecoration(
                    labelText: 'Départ',
                    prefixIcon: const Icon(Icons.trip_origin, size: 20),
                    isDense: true,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.my_location, size: 20),
                      tooltip: 'Ma position',
                      onPressed: _useCurrentPosition,
                    ),
                  ),
                  onChanged: (v) {
                    if (_from != null && v != _fromCtrl.text) _from = null;
                  },
                  onSubmitted: (_) => _resolve(true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _toCtrl,
            decoration: InputDecoration(
              labelText: 'Arrivée',
              prefixIcon: const Icon(Icons.place, size: 20),
              isDense: true,
              suffixIcon: IconButton(
                icon: const Icon(Icons.search, size: 20),
                tooltip: 'Vérifier l\'adresse',
                onPressed: () => _resolve(false),
              ),
            ),
            onChanged: (_) => _to = null,
            onSubmitted: (_) => _resolve(false),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _computeTrip,
              icon: const Icon(Icons.route),
              label: const Text('Chercher sur le trajet'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(int count, Station? cheapest, String fuel) {
    return Container(
      width: double.infinity,
      color: AppColors.greenLight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_route!.distanceKm.toStringAsFixed(0)} km · '
            '${_route!.duration.inHours} h ${_route!.duration.inMinutes % 60} min · '
            '$count station(s)',
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: AppColors.charcoal),
          ),
          if (cheapest != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Moins cher : ${cheapest.prices[fuel]!.price.toStringAsFixed(3)} € '
                'à ${cheapest.name}',
                style: const TextStyle(fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.route_outlined, size: 64, color: AppColors.charcoalLight),
            SizedBox(height: 16),
            Text(
              'Indiquez un départ et une arrivée pour voir les stations '
              'situées le long de votre trajet.',
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Station> stations, Station? cheapest) {
    if (stations.isEmpty) {
      return const Center(child: Text('Aucune station sur ce trajet'));
    }
    return ListView.builder(
      itemCount: stations.length,
      itemBuilder: (context, i) {
        final s = stations[i];
        return Stack(
          children: [
            StationCard(station: s),
            if (identical(s, cheapest))
              Positioned(
                left: 20,
                top: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('MOINS CHER',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMap(List<Station> stations, String fuel, Station? cheapest) {
    final line = _route!.geometry
        .map((p) => LatLng(p.lat, p.lon))
        .toList();

    return FlutterMap(
      options: MapOptions(
        initialCameraFit: CameraFit.coordinates(
          coordinates: line,
          padding: const EdgeInsets.all(40),
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.abcduweb.abc_carburant',
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: line,
              strokeWidth: 5,
              color: AppColors.green.withOpacity(0.8),
            ),
          ],
        ),
        MarkerLayer(
          markers: stations.map((s) {
            final isBest = identical(s, cheapest);
            return Marker(
              point: LatLng(s.latitude, s.longitude),
              width: 62,
              height: 32,
              child: GestureDetector(
                onTap: () => _openStation(s),
                child: Container(
                  decoration: BoxDecoration(
                    color: isBest ? AppColors.green : AppColors.charcoal,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    s.prices[fuel]!.price.toStringAsFixed(2),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        RichAttributionWidget(
          attributions: [
            const TextSourceAttribution('OpenStreetMap contributors'),
          ],
        ),
      ],
    );
  }

  void _openStation(Station station) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StationCard(station: station),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      NavigationService.showChoice(context, station),
                  icon: const Icon(Icons.navigation),
                  label: const Text('Y aller'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
