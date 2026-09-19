import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/fuel_provider.dart';
import '../models/charging_station.dart';
import '../services/navigation_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_formatter.dart';

class ChargingStationCard extends StatelessWidget {
  final ChargingStation station;
  /// État et action du favori, fournis par l'écran appelant plutôt que
  /// lus directement d'un provider précis — ChargingScreen et TeslaScreen
  /// utilisent chacun leur propre provider, mais partagent cette carte.
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  const ChargingStationCard({
    Key? key,
    required this.station,
    required this.isFavorite,
    required this.onToggleFavorite,
  }) : super(key: key);

  Color _powerColor() {
    if (station.maxPowerKw >= 150) return const Color(0xFF7B1FA2); // violet
    if (station.maxPowerKw >= 50) return const Color(0xFFE53935); // rouge
    if (station.maxPowerKw >= 22) return const Color(0xFFFB8C00); // orange
    return AppColors.charcoalLight;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${station.distance.toStringAsFixed(1)} km · '
                    '${station.pointCount} point${station.pointCount > 1 ? 's' : ''}',
                    style:
                        TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _powerColor().withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${station.maxPowerKw.toStringAsFixed(0)} kW',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: _powerColor()),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red.shade400 : Colors.grey,
                size: 22,
              ),
              onPressed: onToggleFavorite,
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (station.address.isNotEmpty)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.place_outlined,
                          size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(child: Text(station.address)),
                    ],
                  ),
                const SizedBox(height: 10),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip(station.powerCategory, _powerColor()),
                    if (station.free) _chip('Gratuit', AppColors.green),
                    if (station.wheelchairAccess)
                      _chip('Accès PMR', AppColors.charcoal),
                    ...station.connectorTypes
                        .map((c) => _chip(c, AppColors.charcoalLight)),
                  ],
                ),

                // Coût aux 100 km : permet de comparer directement cette
                // recharge au prix d'un carburant. Le fichier IRVE ne
                // publie aucun tarif, on utilise donc celui renseigné
                // par l'utilisateur dans les réglages.
                Consumer<FuelProvider>(
                  builder: (context, provider, _) {
                    if (station.free) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text(
                          'Recharge gratuite : 0,00 € / 100 km',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.greenDark,
                          ),
                        ),
                      );
                    }
                    final v = provider.vehicle;
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'Environ ${v.electricCostPer100km.toStringAsFixed(2)} €'
                        ' / 100 km (à ${v.kwhPrice.toStringAsFixed(2)} €/kWh)',
                        style: const TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: AppColors.charcoalLight,
                        ),
                      ),
                    );
                  },
                ),

                if (station.operatorName.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Opérateur : ${station.operatorName}',
                      style: const TextStyle(fontSize: 13)),
                ],
                if (station.accessCondition.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Accès : ${station.accessCondition}',
                      style: const TextStyle(fontSize: 13)),
                ],
                if (station.hours.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Horaires : ${station.hours}',
                      style: const TextStyle(fontSize: 13)),
                ],
                if (station.lastUpdate.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Mis à jour ${DateFormatter.relative(station.lastUpdate)}',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],

                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            NavigationService.openGoogleMaps(station),
                        icon: const Icon(Icons.map, size: 18),
                        label: const Text('Maps'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            NavigationService.showChoice(context, station),
                        icon: const Icon(Icons.navigation, size: 18),
                        label: const Text('Itinéraire'),
                      ),
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

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11.5, color: color, fontWeight: FontWeight.w600)),
      );
}
