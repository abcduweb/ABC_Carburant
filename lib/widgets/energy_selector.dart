import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Type d'énergie affiché. Remplace la navigation par menu : les trois
/// catégories deviennent un choix visible en permanence, ce qui est
/// l'argument différenciant de l'application (thermique et électrique
/// réunis, quelle que soit la motorisation).
enum EnergyType { thermal, electric, tesla }

extension EnergyTypeLabel on EnergyType {
  String get label {
    switch (this) {
      case EnergyType.thermal:
        return 'Carburant';
      case EnergyType.electric:
        return 'Électrique';
      case EnergyType.tesla:
        return 'Tesla';
    }
  }

  IconData get icon {
    switch (this) {
      case EnergyType.thermal:
        return Icons.local_gas_station;
      case EnergyType.electric:
        return Icons.ev_station;
      case EnergyType.tesla:
        return Icons.bolt;
    }
  }

  Color get color {
    switch (this) {
      case EnergyType.thermal:
        return AppColors.green;
      case EnergyType.electric:
        return const Color(0xFF7B1FA2);
      case EnergyType.tesla:
        return const Color(0xFFE31937);
    }
  }
}

class EnergySelector extends StatelessWidget {
  final EnergyType selected;
  final ValueChanged<EnergyType> onChanged;

  const EnergySelector({
    Key? key,
    required this.selected,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: EnergyType.values.map((type) {
          final isSelected = type == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(type),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: isSelected
                      ? const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          )
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      type.icon,
                      size: 20,
                      color: isSelected
                          ? type.color
                          : AppColors.charcoalLight,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      type.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? type.color
                            : AppColors.charcoalLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
