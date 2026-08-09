import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Écran affiché avant la demande de permission système.
/// Google Play exige une explication préalable, et sans contexte la
/// majorité des utilisateurs refusent la boîte de dialogue.
class LocationIntroScreen extends StatelessWidget {
  final VoidCallback onAccept;

  const LocationIntroScreen({Key? key, required this.onAccept})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: AppColors.greenLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.near_me,
                    size: 56, color: AppColors.green),
              ),
              const SizedBox(height: 32),
              const Text(
                'Trouver les stations autour de vous',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'ABC Carburant a besoin de votre position pour afficher '
                'les stations les plus proches et calculer les distances.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 28),
              const _Point(
                icon: Icons.lock_outline,
                text: 'Votre position reste sur votre téléphone. '
                    'Elle n\'est ni envoyée ni stockée nulle part.',
              ),
              const _Point(
                icon: Icons.search,
                text: 'Vous pouvez aussi chercher par commune ou code postal, '
                    'sans activer la localisation.',
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onAccept,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text('Continuer'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Point({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
