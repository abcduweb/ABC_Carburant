import 'package:flutter/material.dart';
import '../providers/fuel_provider.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';

/// Écran d'erreur qui propose l'action correspondant réellement au
/// problème, au lieu d'un « Réessayer » qui ne peut rien résoudre.
class ErrorView extends StatelessWidget {
  final AppError error;
  final VoidCallback onRetry;

  const ErrorView({Key? key, required this.error, required this.onRetry})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    late IconData icon;
    late String title;
    late String message;
    String actionLabel = 'Réessayer';
    VoidCallback action = onRetry;

    switch (error.kind) {
      case AppErrorKind.locationServiceDisabled:
        icon = Icons.location_off;
        title = 'Localisation désactivée';
        message = 'Activez la localisation dans les réglages de votre '
            'téléphone pour voir les stations proches.';
        actionLabel = 'Ouvrir les réglages';
        action = () => LocationService.openLocationSettings();
        break;

      case AppErrorKind.locationDenied:
        icon = Icons.not_listed_location;
        title = 'Autorisation refusée';
        message = 'Sans accès à votre position, impossible de calculer les '
            'distances. Vous pouvez aussi chercher par commune.';
        actionLabel = 'Autoriser';
        break;

      case AppErrorKind.locationDeniedForever:
        icon = Icons.block;
        title = 'Autorisation bloquée';
        message = 'L\'accès à la position a été refusé définitivement. '
            'Réactivez-le dans les réglages de l\'application.';
        actionLabel = 'Ouvrir les réglages';
        action = () => LocationService.openAppSettings();
        break;

      case AppErrorKind.locationTimeout:
        icon = Icons.gps_off;
        title = 'Position introuvable';
        message = 'Le signal GPS n\'a pas été capté. Placez-vous près '
            'd\'une fenêtre ou à l\'extérieur, puis réessayez.';
        break;

      case AppErrorKind.network:
        icon = Icons.wifi_off;
        title = 'Pas de connexion';
        message = 'Vérifiez votre connexion internet, puis réessayez.';
        break;

      case AppErrorKind.server:
        icon = Icons.cloud_off;
        title = 'Service indisponible';
        message = 'Le service de données des carburants ne répond pas. '
            'Réessayez dans quelques instants.';
        break;

      case AppErrorKind.empty:
        icon = Icons.search_off;
        title = 'Aucune station trouvée';
        message = 'Essayez d\'élargir le rayon de recherche ou de changer '
            'de carburant.';
        break;

      case AppErrorKind.unknown:
        icon = Icons.error_outline;
        title = 'Une erreur est survenue';
        message = error.detail ?? 'Réessayez dans un instant.';
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppColors.charcoalLight),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 28),
            ElevatedButton(onPressed: action, child: Text(actionLabel)),
            if (action != onRetry) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: onRetry, child: const Text('Réessayer')),
            ],
          ],
        ),
      ),
    );
  }
}
