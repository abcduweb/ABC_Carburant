import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/fuel_provider.dart';
import '../models/station.dart';
import '../services/navigation_service.dart';
import '../utils/date_formatter.dart';
import '../theme/app_theme.dart';

class StationCard extends StatelessWidget {
  final Station station;

  const StationCard({Key? key, required this.station}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    station.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${station.distance.toStringAsFixed(1)} km',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // Prix du carburant selectionne, visible sans deplier
            Consumer<FuelProvider>(
              builder: (context, provider, _) {
                final selected = station.prices[provider.selectedFuelType];
                if (selected == null) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: selected.isStale
                        ? const Color(0xFFEFEFEC)
                        : AppColors.greenLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${selected.price.toStringAsFixed(3)} €',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: selected.isStale
                          ? AppColors.charcoalLight
                          : AppColors.greenDark,
                    ),
                  ),
                );
              },
            ),

            // Favori
            Consumer<FuelProvider>(
              builder: (context, provider, _) {
                final fav = provider.isFavorite(station.id);
                return IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    fav ? Icons.favorite : Icons.favorite_border,
                    color: fav ? Colors.red.shade400 : Colors.grey,
                    size: 22,
                  ),
                  onPressed: () => provider.toggleFavorite(station.id),
                  tooltip: fav ? 'Retirer des favoris' : 'Ajouter aux favoris',
                );
              },
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gain net, detour deduit
                Consumer<FuelProvider>(
                  builder: (context, provider, _) {
                    final sav = provider.savingsFor(station);
                    if (sav == null || sav.gross.abs() < 0.05) {
                      return const SizedBox.shrink();
                    }
                    final positive = sav.isWorthIt;
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: positive
                            ? AppColors.greenLight
                            : const Color(0xFFF3F1EF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                positive
                                    ? Icons.savings_outlined
                                    : Icons.info_outline,
                                size: 18,
                                color: positive
                                    ? AppColors.greenDark
                                    : AppColors.charcoalLight,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  positive
                                      ? 'Vous gagnez ${sav.net.toStringAsFixed(2)} € '
                                          'sur un plein'
                                      : (sav.net <= 0
                                          ? 'Le détour coûte plus qu\'il ne rapporte'
                                          : 'Gain négligeable : '
                                              '${sav.net.toStringAsFixed(2)} €'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: positive
                                        ? AppColors.greenDark
                                        : AppColors.charcoal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${sav.gross.toStringAsFixed(2)} € économisés sur '
                            '${provider.vehicle.tankLitres.toStringAsFixed(0)} L'
                            '${sav.extraKm > 0 ? ' − ${sav.detourCost.toStringAsFixed(2)} € de détour (${sav.extraKm.toStringAsFixed(0)} km A/R)' : ''}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.charcoalLight),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Adresse
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        station.address,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // Prix des carburants
                const Text(
                  'Prix des carburants',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                if (station.prices.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Prix non disponibles',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  Column(
                    children: station.prices.entries.map((entry) {
                      final fuelType = entry.key;
                      final fuelPrice = entry.value;
                      return _buildFuelPriceRow(fuelType, fuelPrice);
                    }).toList(),
                  ),

                const SizedBox(height: 16),

                // Boutons d'action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () =>
                          NavigationService.openGoogleMaps(station),
                      icon: const Icon(Icons.map, size: 18),
                      label: const Text('Maps'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () =>
                          NavigationService.showChoice(context, station),
                      icon: const Icon(Icons.navigation, size: 18),
                      label: const Text('Itinéraire'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuelPriceRow(String fuelType, FuelPrice fuelPrice) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fuelType,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (fuelPrice.isStale) ...[
                    Icon(Icons.schedule,
                        size: 13, color: Colors.orange.shade700),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    'Mis à jour ${DateFormatter.relative(fuelPrice.lastUpdate)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: fuelPrice.isStale
                          ? Colors.orange.shade800
                          : Colors.grey.shade600,
                      fontWeight: fuelPrice.isStale
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: fuelPrice.isStale
                  ? const Color(0xFFEFEFEC)
                  : AppColors.greenLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${fuelPrice.price.toStringAsFixed(3)} €',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
