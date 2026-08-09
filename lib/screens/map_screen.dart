import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/station.dart';
import '../providers/fuel_provider.dart';
import '../services/navigation_service.dart';
import '../theme/app_theme.dart';
import '../widgets/station_card.dart';

/// Carte des stations sur fond OpenStreetMap.
/// Pastille verte = prix le plus bas, rouge = le plus haut, pour le
/// carburant actuellement selectionne.
class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _controller = MapController();
  bool _ready = false;

  void _openStation(Station station) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.charcoalLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: StationCard(station: station),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          NavigationService.showChoice(context, station),
                      icon: const Icon(Icons.navigation),
                      label: const Text('Y aller'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Interpolation vert -> jaune -> rouge selon la position du prix.
  Color _priceColor(double? price, double minPrice, double maxPrice) {
    if (price == null || maxPrice <= minPrice) return AppColors.green;
    final ratio = ((price - minPrice) / (maxPrice - minPrice)).clamp(0.0, 1.0);
    if (ratio < 0.5) {
      return Color.lerp(
          const Color(0xFF4CAF50), const Color(0xFFFFC107), ratio * 2)!;
    }
    return Color.lerp(
        const Color(0xFFFFC107), const Color(0xFFE53935), (ratio - 0.5) * 2)!;
  }

  List<Marker> _buildMarkers(List<Station> stations, String fuelType) {
    final prices = stations
        .map((s) => s.prices[fuelType]?.price)
        .whereType<double>()
        .toList()
      ..sort();
    if (prices.isEmpty) return [];

    final minPrice = prices.first;
    final maxPrice = prices.last;

    return stations.map((station) {
      final price = station.prices[fuelType]?.price;
      final color = _priceColor(price, minPrice, maxPrice);

      return Marker(
        point: LatLng(station.latitude, station.longitude),
        width: 62,
        height: 34,
        child: GestureDetector(
          onTap: () => _openStation(station),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2)),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              price != null ? price.toStringAsFixed(2) : '—',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  void _fitToStations(List<Station> stations) {
    if (!_ready || stations.isEmpty) return;

    var minLat = stations.first.latitude, maxLat = stations.first.latitude;
    var minLon = stations.first.longitude, maxLon = stations.first.longitude;
    for (final s in stations) {
      if (s.latitude < minLat) minLat = s.latitude;
      if (s.latitude > maxLat) maxLat = s.latitude;
      if (s.longitude < minLon) minLon = s.longitude;
      if (s.longitude > maxLon) maxLon = s.longitude;
    }

    _controller.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(LatLng(minLat, minLon), LatLng(maxLat, maxLon)),
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FuelProvider>(
      builder: (context, provider, child) {
        final stations = provider.filteredStations;
        final userLat = provider.currentLat;
        final userLon = provider.currentLon;
        final center = LatLng(userLat ?? 46.6, userLon ?? 2.3);

        return Scaffold(
          appBar: AppBar(
            title: Text(
                'Carte — ${provider.selectedFuelType} · ${provider.radiusKm.toInt()} km'),
            actions: [
              IconButton(
                icon: const Icon(Icons.fit_screen),
                tooltip: 'Ajuster la vue',
                onPressed: () => _fitToStations(stations),
              ),
              IconButton(
                icon: const Icon(Icons.my_location),
                tooltip: 'Ma position',
                onPressed: () {
                  if (userLat != null && userLon != null) {
                    _controller.move(LatLng(userLat, userLon), 13);
                  }
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              FlutterMap(
                mapController: _controller,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 11,
                  minZoom: 4,
                  maxZoom: 18,
                  onMapReady: () {
                    _ready = true;
                    _fitToStations(stations);
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    // La politique d'usage d'OSM impose d'identifier
                    // l'application appelante.
                    userAgentPackageName: 'com.abcduweb.abc_carburant',
                    maxNativeZoom: 19,
                  ),

                  // Position de l'utilisateur
                  if (userLat != null && userLon != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(userLat, userLon),
                          width: 22,
                          height: 22,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blueAccent,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 3),
                              boxShadow: const [
                                BoxShadow(
                                    color: Colors.black26, blurRadius: 4),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                  MarkerLayer(
                    markers: _buildMarkers(stations, provider.selectedFuelType),
                  ),

                  // Attribution OpenStreetMap : obligatoire.
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        'OpenStreetMap contributors',
                        onTap: () => launchUrl(
                          Uri.parse('https://www.openstreetmap.org/copyright'),
                          mode: LaunchMode.externalApplication,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              if (stations.isEmpty)
                const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Aucune station pour ce carburant'),
                    ),
                  ),
                ),

              // Legende
              Positioned(
                left: 12,
                bottom: 12,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.square, color: Color(0xFF4CAF50), size: 16),
                        Text(' moins cher   '),
                        Icon(Icons.square, color: Color(0xFFE53935), size: 16),
                        Text(' plus cher'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
