import 'package:intl/intl.dart';

/// Mise en forme des dates de l'API (format ISO 8601) en français lisible.
class DateFormatter {
  /// "il y a 2 h", "hier à 08:00", "5 août à 08:00", "5 août 2025"
  static String relative(String isoDate) {
    final date = _parse(isoDate);
    if (date == null) return '';

    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'à l\'instant';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) {
      return 'il y a ${diff.inHours} h';
    }
    if (diff.inDays == 1) {
      return 'hier à ${DateFormat('HH:mm', 'fr_FR').format(date)}';
    }
    if (diff.inDays < 7) {
      return 'il y a ${diff.inDays} jours';
    }
    if (date.year == now.year) {
      return 'le ${DateFormat('d MMMM', 'fr_FR').format(date)}';
    }
    return 'le ${DateFormat('d MMMM yyyy', 'fr_FR').format(date)}';
  }

  /// "5 août 2026 à 08:00"
  static String full(String isoDate) {
    final date = _parse(isoDate);
    if (date == null) return '';
    return DateFormat("d MMMM yyyy 'à' HH:mm", 'fr_FR').format(date);
  }

  static DateTime? _parse(String isoDate) {
    if (isoDate.trim().isEmpty) return null;
    try {
      // L'API renvoie de l'UTC : on repasse en heure locale
      return DateTime.parse(isoDate).toLocal();
    } catch (_) {
      return null;
    }
  }
}
