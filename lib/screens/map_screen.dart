import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/locatable.dart';
import '../models/station.dart';
import '../models/charging_station.dart';
import '../providers/fuel_provider.dart';
import '../providers/charging_provider.dart';
import '../providers/tesla_provider.dart';
import '../services/navigation_service.dart';
import '../theme/app_theme.dart';
import '../widgets/station_card.dart';
import '../widgets/charging_station_card.dart';
import '../widgets/energy_selector.dart';

/// Carte des points de ravitaillement sur fond OpenStreetMap.
///
/// Couvre les trois énergies, comme la liste : carburants (pastille
/// colorée du vert au rouge selon le prix), bornes électriques et
/// Superchargers Tesla (pastille indiquant la puissance).
class MapScreen extends StatefulWidget {
  /// Énergie affichée. Transmise par l'écran d'accueil pour que la
  /// carte montre la même chose que la liste que l'utilisateur
  /// regardait.
  final EnergyType energy;

  const MapScreen({Key? key, this.energy = EnergyType.thermal})
      : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _controller = MapController();
  bool _ready = false;

  /// Zoom courant. Les noms de stations ne s'affichent qu'au-dela de
  /// _nameZoom : a l'echelle d'une region, une centaine de libelles se
  /// chevaucheraient et masqueraient la carte.
  double _zoom = 11;
  static const double _nameZoom = 12.5;

  bool get _showNames => _zoom >= _nameZoom;

  /// Couches visibles. Les carburants sont toujours actifs au depart :
  /// ils sont deja charges (cout nul) et leur absence surprenait quand
  /// la carte etait ouverte depuis un autre onglet. S'y ajoute l'onglet
  /// d'ou l'on vient. L'utilisateur ajuste ensuite librement.
  late final Set<EnergyType> _actifs = {EnergyType.thermal, widget.energy};

  @override
  void initState() {
    super.initState();
    // Le chargement ne peut pas partir pendant le build : les providers
    // appellent notifyListeners(), ce qui declencherait une erreur de
    // reconstruction en cours de frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _assurerDonnees(widget.energy);
    });
  }

  // ------------------------------------------------------------------
  //  Feuille de détail
  // ------------------------------------------------------------------

  /// Enveloppe commune aux deux types de fiche : poignée, défilement et
  /// bouton « Y aller ». Seul le contenu change.
  void _showSheet(Widget content, Locatable target) {
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
                    child: content,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          NavigationService.showChoice(context, target),
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

  void _openStation(Station station) =>
      _showSheet(StationCard(station: station), station);

  void _openCharging(
    ChargingStation station,
    bool isFavorite,
    VoidCallback onToggleFavorite,
  ) =>
      _showSheet(
        ChargingStationCard(
          station: station,
          isFavorite: isFavorite,
          onToggleFavorite: onToggleFavorite,
        ),
        station,
      );

  // ------------------------------------------------------------------
  //  Couleurs
  // ------------------------------------------------------------------

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

  /// Pour une borne, c'est la puissance qui compte, pas un prix : le
  /// fichier IRVE n'en publie aucun. Le vert signale donc la recharge
  /// la plus rapide, par symétrie avec le carburant le moins cher.
  Color _powerColor(double kw) {
    if (kw >= 150) return const Color(0xFF4CAF50); // ultra-rapide
    if (kw >= 50) return const Color(0xFF9CCC65); // rapide
    if (kw >= 22) return const Color(0xFFFFC107); // accéléré
    return const Color(0xFF9E9E9E); // standard
  }

  // ------------------------------------------------------------------
  //  Marqueurs
  // ------------------------------------------------------------------

  /// Pastille commune : même forme pour les trois énergies, seuls la
  /// couleur et le texte changent.
  Marker _pill({
    required double lat,
    required double lon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    double width = 62,
    String? name,
  }) {
    final withName = name != null && name.trim().isNotEmpty;

    final pastille = Container(
      width: width,
      height: 34,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
              color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );

    return Marker(
      point: LatLng(lat, lon),
      // Le libelle est plus large que la pastille : le marqueur doit
      // l'etre aussi, sinon le texte est rogne.
      width: withName ? 124 : width,
      height: withName ? 54 : 34,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            pastille,
            if (withName) ...[
              const SizedBox(height: 2),
              // Fond blanc semi-opaque : un texte pose directement sur
              // les tuiles OSM devient illisible des que la carte est
              // chargee (routes, zones vertes, batiments).
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.88),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  name.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Marker> _fuelMarkers(List<Station> stations, String fuelType) {
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
      return _pill(
        lat: station.latitude,
        lon: station.longitude,
        label: price != null ? price.toStringAsFixed(2) : '—',
        color: _priceColor(price, minPrice, maxPrice),
        name: _showNames ? station.name : null,
        onTap: () => _openStation(station),
      );
    }).toList();
  }

  List<Marker> _chargingMarkers(
    List<ChargingStation> stations, {
    required bool tesla,
    required bool Function(String) isFavorite,
    required void Function(String) onToggleFavorite,
  }) {
    return stations.map((station) {
      final kw = station.maxPowerKw;
      return _pill(
        lat: station.latitude,
        lon: station.longitude,
        label: kw > 0 ? '${kw.toStringAsFixed(0)} kW' : '—',
        // Les Superchargers affichent tous 150 à 250 kW : une échelle de
        // puissance n'y distinguerait rien. On garde donc le rouge de la
        // marque, qui situe le réseau d'un coup d'œil.
        color: tesla ? const Color(0xFFE31937) : _powerColor(kw),
        width: 66,
        name: _showNames ? station.name : null,
        onTap: () => _openCharging(
          station,
          isFavorite(station.id),
          () => onToggleFavorite(station.id),
        ),
      );
    }).toList();
  }

  // ------------------------------------------------------------------
  //  Cadrage
  // ------------------------------------------------------------------

  void _fitTo(List<Locatable> points) {
    if (!_ready || points.isEmpty) return;

    var minLat = points.first.latitude, maxLat = points.first.latitude;
    var minLon = points.first.longitude, maxLon = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLon) minLon = p.longitude;
      if (p.longitude > maxLon) maxLon = p.longitude;
    }

    _controller.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(LatLng(minLat, minLon), LatLng(maxLat, maxLon)),
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  // ------------------------------------------------------------------
  //  Chargement a la demande
  // ------------------------------------------------------------------

  /// Les providers Bornes et Tesla ne se chargent que lorsque leur
  /// onglet est visite. Depuis la carte, l'utilisateur peut activer une
  /// couche sans etre jamais passe par l'onglet correspondant : on
  /// declenche alors le chargement, en reutilisant la position deja
  /// connue du provider Carburant pour eviter un second appel GPS.
  void _assurerDonnees(EnergyType type) {
    final fuel = context.read<FuelProvider>();
    final lat = fuel.currentLat;
    final lon = fuel.currentLon;

    switch (type) {
      case EnergyType.thermal:
        break; // toujours charge par l'accueil
      case EnergyType.electric:
        final p = context.read<ChargingProvider>();
        if (p.stations.isEmpty && !p.isLoading) {
          p.initializeAndLoad(lat: lat, lon: lon);
        }
        break;
      case EnergyType.tesla:
        final p = context.read<TeslaProvider>();
        if (p.stations.isEmpty && !p.isLoading) {
          p.initializeAndLoad(lat: lat, lon: lon);
        }
        break;
    }
  }

  void _basculer(EnergyType type) {
    setState(() {
      if (_actifs.contains(type)) {
        // Au moins une couche doit rester visible, sinon la carte se
        // vide sans que l'utilisateur comprenne pourquoi.
        if (_actifs.length > 1) _actifs.remove(type);
      } else {
        _actifs.add(type);
        _assurerDonnees(type);
      }
    });
  }

  // ------------------------------------------------------------------
  //  Construction
  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final fuel = context.watch<FuelProvider>();
    final charging = context.watch<ChargingProvider>();
    final tesla = context.watch<TeslaProvider>();

    final points = <Locatable>[];
    final markers = <Marker>[];
    final legend = <_LegendItem>[];

    if (_actifs.contains(EnergyType.thermal)) {
      final l = fuel.filteredStations;
      points.addAll(l);
      markers.addAll(_fuelMarkers(l, fuel.selectedFuelType));
      legend.add(const _LegendItem(Color(0xFF4CAF50), 'moins cher'));
      legend.add(const _LegendItem(Color(0xFFE53935), 'plus cher'));
    }
    if (_actifs.contains(EnergyType.electric)) {
      final l = charging.filteredStations;
      points.addAll(l);
      markers.addAll(_chargingMarkers(
        l,
        tesla: false,
        isFavorite: charging.isFavorite,
        onToggleFavorite: charging.toggleFavorite,
      ));
      legend.add(const _LegendItem(Color(0xFF4CAF50), '150 kW et +'));
      legend.add(const _LegendItem(Color(0xFFFFC107), '22 kW'));
    }
    if (_actifs.contains(EnergyType.tesla)) {
      final l = tesla.filteredStations;
      points.addAll(l);
      markers.addAll(_chargingMarkers(
        l,
        tesla: true,
        isFavorite: tesla.isFavorite,
        onToggleFavorite: tesla.toggleFavorite,
      ));
      legend.add(const _LegendItem(Color(0xFFE31937), 'Tesla'));
    }

    final center = LatLng(fuel.currentLat ?? 46.6, fuel.currentLon ?? 2.3);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte'),
        actions: [
          IconButton(
            icon: const Icon(Icons.fit_screen),
            tooltip: 'Ajuster la vue',
            onPressed: () => _fitTo(points),
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Ma position',
            onPressed: () {
              if (fuel.currentLat != null && fuel.currentLon != null) {
                _controller.move(
                    LatLng(fuel.currentLat!, fuel.currentLon!), 13);
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
                _fitTo(points);
              },
              // Redessine les marqueurs au franchissement du seuil des
              // noms, et uniquement a ce moment-la : un setState a
              // chaque deplacement rendrait la carte saccadee.
              // flutter_map 6.x fournit un MapPosition dont le zoom est
              // nullable, d'ou le repli sur la valeur courante.
              onPositionChanged: (position, _) {
                final avant = _showNames;
                _zoom = position.zoom ?? _zoom;
                if (_showNames != avant && mounted) setState(() {});
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                // La politique d'usage d'OSM impose d'identifier
                // l'application appelante.
                userAgentPackageName: 'com.abcduweb.abc_carburant',
                maxNativeZoom: 19,
              ),

              // Position de l'utilisateur
              if (fuel.currentLat != null && fuel.currentLon != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(fuel.currentLat!, fuel.currentLon!),
                      width: 22,
                      height: 22,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

              MarkerLayer(markers: markers),

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

          // Filtres : une couche par energie, cumulables.
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FiltreChip(
                    type: EnergyType.thermal,
                    actif: _actifs.contains(EnergyType.thermal),
                    nombre: fuel.filteredStations.length,
                    chargement: fuel.isLoading,
                    onTap: () => _basculer(EnergyType.thermal),
                  ),
                  _FiltreChip(
                    type: EnergyType.electric,
                    actif: _actifs.contains(EnergyType.electric),
                    nombre: charging.filteredStations.length,
                    chargement: charging.isLoading,
                    onTap: () => _basculer(EnergyType.electric),
                  ),
                  _FiltreChip(
                    type: EnergyType.tesla,
                    actif: _actifs.contains(EnergyType.tesla),
                    nombre: tesla.filteredStations.length,
                    chargement: tesla.isLoading,
                    onTap: () => _basculer(EnergyType.tesla),
                  ),
                ],
              ),
            ),
          ),

          if (points.isEmpty)
            Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _actifs.length == 1
                        ? 'Aucun point pour ce filtre'
                        : 'Aucun point pour ces filtres',
                  ),
                ),
              ),
            ),

          // Légende
          if (legend.isNotEmpty)
            Positioned(
              left: 12,
              bottom: 12,
              child: Card(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(mainAxisSize: MainAxisSize.min, children: legend),
                      // Sans cette indication, l'utilisateur qui dezoome
                      // voit les noms disparaitre et croit a un bug.
                      if (!_showNames) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Zoomez pour voir les noms',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Bouton de filtre d'une couche : icone, libelle, nombre de points.
class _FiltreChip extends StatelessWidget {
  final EnergyType type;
  final bool actif;
  final int nombre;
  final bool chargement;
  final VoidCallback onTap;

  const _FiltreChip({
    required this.type,
    required this.actif,
    required this.nombre,
    required this.chargement,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: actif ? type.color : Colors.white,
        borderRadius: BorderRadius.circular(18),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (chargement)
                  SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: actif ? Colors.white : type.color,
                    ),
                  )
                else
                  Icon(
                    type.icon,
                    size: 16,
                    color: actif ? Colors.white : type.color,
                  ),
                const SizedBox(width: 6),
                Text(
                  chargement ? type.label : '${type.label} ($nombre)',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: actif ? FontWeight.bold : FontWeight.normal,
                    color: actif ? Colors.white : AppColors.charcoal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Une entrée de légende : carré de couleur et libellé.
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem(this.color, this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.square, color: color, size: 14),
          const SizedBox(width: 3),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
