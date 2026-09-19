import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/charging_provider.dart';
import '../providers/fuel_provider.dart' show AppError, AppErrorKind;
import '../widgets/charging_station_card.dart';
import '../widgets/error_view.dart';
import '../widgets/search_bar.dart';
import '../theme/app_theme.dart';

class ChargingScreen extends StatefulWidget {
  /// Affiché dans l'onglet d'accueil plutôt qu'en écran autonome :
  /// on masque alors la barre de titre, déjà fournie par l'accueil.
  final bool embedded;

  const ChargingScreen({Key? key, this.embedded = false}) : super(key: key);

  @override
  State<ChargingScreen> createState() => _ChargingScreenState();
}

class _ChargingScreenState extends State<ChargingScreen> {
  bool _booting = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<ChargingProvider>();
      await provider.loadPreferences();
      if (!mounted) return;
      setState(() => _booting = false);
      provider.initializeAndLoad();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_booting) {
      const loader = Center(child: CircularProgressIndicator());
      return widget.embedded ? loader : const Scaffold(body: loader);
    }

    return Consumer<ChargingProvider>(
      builder: (context, provider, child) {
        final body = _buildBody(context, provider);
        if (widget.embedded) return body;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Bornes électriques'),
          ),
          body: body,
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ChargingProvider provider) {
    if (provider.isLoading && provider.stations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Recherche des bornes autour de vous...'),
          ],
        ),
      );
    }

    if (provider.error != null && provider.stations.isEmpty) {
      return ErrorView(
        error: provider.error!,
        onRetry: () => provider.initializeAndLoad(),
        subject: 'des bornes électriques',
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

          SliverToBoxAdapter(child: _buildFilters(provider)),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          if (stations.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: ErrorView(
                error: provider.error ?? const AppError(AppErrorKind.empty),
                onRetry: provider.refresh,
                subject: 'des bornes électriques',
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    ChargingStationCard(
                  station: stations[index],
                  isFavorite: provider.isFavorite(stations[index].id),
                  onToggleFavorite: () =>
                      provider.toggleFavorite(stations[index].id),
                ),
                childCount: stations.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }

  Widget _buildFilters(ChargingProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Distance'),
                  selected: provider.sortBy == 'distance',
                  onSelected: (_) => provider.setSortBy('distance'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Puissance'),
                  selected: provider.sortBy == 'power',
                  onSelected: (_) => provider.setSortBy('power'),
                ),
                const SizedBox(width: 16),
                FilterChip(
                  label: const Text('Rapide ≥ 50 kW'),
                  selected: provider.fastOnly,
                  onSelected: (_) => provider.toggleFastOnly(),
                  selectedColor: AppColors.green.withOpacity(0.25),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Gratuit'),
                  selected: provider.freeOnly,
                  onSelected: (_) => provider.toggleFreeOnly(),
                  selectedColor: AppColors.green.withOpacity(0.25),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Icon(Icons.social_distance,
                    size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                const Text('Rayon: ',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                ...[5.0, 10.0, 20.0, 50.0, 100.0].map((km) {
                  final isSelected = provider.radiusKm == km;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('${km.toInt()} km'),
                      selected: isSelected,
                      onSelected: (_) => provider.setRadius(km),
                      selectedColor: AppColors.green.withOpacity(0.3),
                      labelStyle: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
