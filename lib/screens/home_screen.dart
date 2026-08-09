import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/fuel_provider.dart';
import '../widgets/station_card.dart';
import '../widgets/fuel_filter.dart';
import '../widgets/search_bar.dart';
import '../widgets/error_view.dart';
import 'about_screen.dart';
import 'map_screen.dart';
import 'location_intro_screen.dart';
import 'trip_screen.dart';
import 'settings_screen.dart';
import '../services/alerts_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _booting = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<FuelProvider>();
      await provider.loadPreferences();
      if (!mounted) return;
      setState(() => _booting = false);
      // La demande systeme n'arrive qu'apres l'ecran d'explication
      if (provider.introSeen) {
        provider.initializeAndLoad();
        AlertsService.checkOnLaunch();
      }
    });
  }

  Future<void> _acceptIntro() async {
    final provider = context.read<FuelProvider>();
    await provider.markIntroSeen();
    provider.initializeAndLoad();
  }

  @override
  Widget build(BuildContext context) {
    if (_booting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Consumer<FuelProvider>(
      builder: (context, provider, child) {
        if (!provider.introSeen) {
          return LocationIntroScreen(onAccept: _acceptIntro);
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('ABC Carburant'),
            actions: [
              IconButton(
                icon: Icon(provider.favoritesOnly
                    ? Icons.favorite
                    : Icons.favorite_border),
                onPressed: provider.toggleFavoritesOnly,
                tooltip: 'Favoris',
              ),
              IconButton(
                icon: const Icon(Icons.route_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TripScreen()),
                ),
                tooltip: 'Sur mon trajet',
              ),
              IconButton(
                icon: const Icon(Icons.map_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MapScreen()),
                ),
                tooltip: 'Carte',
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'settings') {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()));
                  } else {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AboutScreen()));
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'settings',
                    child: ListTile(
                      leading: Icon(Icons.tune),
                      title: Text('Réglages'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'about',
                    child: ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('À propos'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: _buildBody(context, provider),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, FuelProvider provider) {
    if (provider.isLoading && provider.stations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Recherche des stations autour de vous...'),
          ],
        ),
      );
    }

    // Une erreur bloquante n'occupe l'ecran que s'il n'y a rien a montrer
    if (provider.error != null && provider.stations.isEmpty) {
      return ErrorView(
        error: provider.error!,
        onRetry: () => provider.initializeAndLoad(),
      );
    }

    final stations = provider.filteredStations;

    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: StationSearchBar(
                onSearch: (query) {
                  if (query.isNotEmpty) {
                    provider.searchByLocation(query);
                  } else {
                    provider.loadNearbyStations();
                  }
                },
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FuelFilter(
                onFuelTypeChanged: provider.selectFuelType,
                onSortChanged: provider.setSortBy,
                onRadiusChanged: provider.setRadius,
                selectedFuel: provider.selectedFuelType,
                selectedSort: provider.sortBy,
                selectedRadius: provider.radiusKm,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          if (stations.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: ErrorView(
                error: provider.favoritesOnly
                    ? const AppError(AppErrorKind.empty)
                    : (provider.error ?? const AppError(AppErrorKind.empty)),
                onRetry: provider.refresh,
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: StationCard(station: stations[index]),
                ),
                childCount: stations.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}
