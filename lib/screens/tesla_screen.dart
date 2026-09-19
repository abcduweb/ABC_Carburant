import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tesla_provider.dart';
import '../providers/fuel_provider.dart' show AppError, AppErrorKind;
import '../widgets/charging_station_card.dart';
import '../widgets/error_view.dart';
import '../widgets/search_bar.dart';
import '../theme/app_theme.dart';

class TeslaScreen extends StatefulWidget {
  /// Affiché dans l'onglet d'accueil plutôt qu'en écran autonome :
  /// on masque alors la barre de titre, déjà fournie par l'accueil.
  final bool embedded;

  const TeslaScreen({Key? key, this.embedded = false}) : super(key: key);

  @override
  State<TeslaScreen> createState() => _TeslaScreenState();
}

class _TeslaScreenState extends State<TeslaScreen> {
  bool _booting = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<TeslaProvider>();
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

    return Consumer<TeslaProvider>(
      builder: (context, provider, child) {
        final body = _buildBody(context, provider);
        if (widget.embedded) return body;
        return Scaffold(
          appBar: AppBar(title: const Text('Superchargers Tesla')),
          body: body,
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, TeslaProvider provider) {
    if (provider.isLoading && provider.stations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Recherche des Superchargers autour de vous...'),
          ],
        ),
      );
    }

    if (provider.error != null && provider.stations.isEmpty) {
      return Column(
        children: [
          _sourceNotice(),
          Expanded(
            child: ErrorView(
              error: provider.error!,
              onRetry: () => provider.initializeAndLoad(),
              subject: 'des Superchargers Tesla',
            ),
          ),
        ],
      );
    }

    final stations = provider.filteredStations;

    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _sourceNotice()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: StationSearchBar(
                onSearch: (query) {
                  if (query.isEmpty) provider.loadNearbyStations();
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
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
                        ...[20.0, 50.0, 100.0, 200.0].map((km) {
                          final isSelected = provider.radiusKm == km;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text('${km.toInt()} km'),
                              selected: isSelected,
                              onSelected: (_) => provider.setRadius(km),
                              selectedColor: AppColors.green.withOpacity(0.3),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          if (stations.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: ErrorView(
                error: provider.error ?? const AppError(AppErrorKind.empty),
                onRetry: provider.refresh,
                subject: 'des Superchargers Tesla',
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => ChargingStationCard(
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

  Widget _sourceNotice() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDE8E8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE31937).withOpacity(0.3)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: Color(0xFFE31937)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Stations du réseau Tesla Supercharger ouvertes au public, '
              'identifiées dans le fichier national des bornes de recharge '
              '(IRVE). Application indépendante, sans lien avec Tesla.',
              style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF7A1220)),
            ),
          ),
        ],
      ),
    );
  }
}
