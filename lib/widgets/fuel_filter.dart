import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FuelFilter extends StatelessWidget {
  final Function(String) onFuelTypeChanged;
  final Function(String) onSortChanged;
  final Function(double) onRadiusChanged;
  final String selectedFuel;
  final String selectedSort;
  final double selectedRadius;

  const FuelFilter({
    Key? key,
    required this.onFuelTypeChanged,
    required this.onSortChanged,
    required this.onRadiusChanged,
    required this.selectedFuel,
    required this.selectedSort,
    required this.selectedRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fuelTypes = ['Gazole', 'E10', 'SP95', 'SP98', 'E85', 'GPLc'];

    return Column(
      children: [
        // Filtres de carburant
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: fuelTypes.map((fuel) {
              final isSelected = selectedFuel == fuel;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(fuel),
                  selected: isSelected,
                  onSelected: (_) {
                    onFuelTypeChanged(fuel);
                  },
                  backgroundColor: Colors.grey.shade200,
                  selectedColor: AppColors.green,
                  labelStyle: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 12),

        // Tri
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const Text('Trier par: ', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Distance'),
                selected: selectedSort == 'distance',
                onSelected: (_) {
                  onSortChanged('distance');
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Prix'),
                selected: selectedSort == 'price',
                onSelected: (_) {
                  onSortChanged('price');
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Gain net'),
                selected: selectedSort == 'savings',
                onSelected: (_) {
                  onSortChanged('savings');
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Rayon de recherche
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const Icon(Icons.social_distance, size: 18, color: Colors.grey),
              const SizedBox(width: 6),
              const Text('Rayon: ',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              ...[5.0, 10.0, 20.0, 50.0, 100.0].map((km) {
                final isSelected = selectedRadius == km;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('${km.toInt()} km'),
                    selected: isSelected,
                    onSelected: (_) => onRadiusChanged(km),
                    selectedColor: AppColors.green,
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
    );
  }
}
