import 'package:flutter/material.dart';
import '../services/price_history_service.dart';
import '../theme/app_theme.dart';

/// Affiche la tendance d'un prix et une courbe compacte.
/// Dessinée avec CustomPainter : pas de dépendance graphique ajoutée.
class PriceHistoryView extends StatelessWidget {
  final PriceHistory history;
  final String fuelType;

  const PriceHistoryView({
    Key? key,
    required this.history,
    required this.fuelType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!history.hasEnoughData) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F1EF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.timeline, size: 18, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Historique en cours de constitution '
                '(${history.points.length} relevé'
                '${history.points.length > 1 ? 's' : ''}). Revenez dans '
                'quelques jours.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ),
          ],
        ),
      );
    }

    final trend = history.trend;
    late IconData icon;
    late Color color;
    late String label;

    switch (trend) {
      case PriceTrend.rising:
        icon = Icons.trending_up;
        color = const Color(0xFFE53935);
        label = 'En hausse';
        break;
      case PriceTrend.falling:
        icon = Icons.trending_down;
        color = AppColors.greenDark;
        label = 'En baisse';
        break;
      case PriceTrend.stable:
        icon = Icons.trending_flat;
        color = AppColors.charcoalLight;
        label = 'Stable';
        break;
      case PriceTrend.unknown:
        icon = Icons.timeline;
        color = AppColors.charcoalLight;
        label = '';
        break;
    }

    final change = history.change;
    final lowest = history.lowest;
    final highest = history.highest;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F1EF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13, color: color),
              ),
              if (change != null && trend != PriceTrend.stable) ...[
                const SizedBox(width: 6),
                Text(
                  '${change > 0 ? '+' : ''}${(change * 100).toStringAsFixed(1)} ct',
                  style: TextStyle(fontSize: 12, color: color),
                ),
              ],
              const Spacer(),
              if (history.isAtLowest)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Au plus bas',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.greenDark),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 46,
            child: CustomPaint(
              size: const Size(double.infinity, 46),
              painter: _SparklinePainter(history.points, color),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Sur ${history.points.length} relevés : '
            'de ${lowest!.toStringAsFixed(3)} € '
            'à ${highest!.toStringAsFixed(3)} €',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<PricePoint> points;
  final Color color;

  _SparklinePainter(this.points, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final prices = points.map((p) => p.price).toList();
    var min = prices.reduce((a, b) => a < b ? a : b);
    var max = prices.reduce((a, b) => a > b ? a : b);
    // Évite une division par zéro quand tous les prix sont identiques.
    if ((max - min).abs() < 0.0001) {
      min -= 0.01;
      max += 0.01;
    }

    final dx = size.width / (points.length - 1);
    final path = Path();
    final fill = Path();

    for (var i = 0; i < points.length; i++) {
      final x = i * dx;
      final y = size.height -
          ((prices[i] - min) / (max - min)) * (size.height - 6) -
          3;
      if (i == 0) {
        path.moveTo(x, y);
        fill.moveTo(x, size.height);
        fill.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fill.lineTo(x, y);
      }
    }
    fill.lineTo(size.width, size.height);
    fill.close();

    canvas.drawPath(
        fill, Paint()..color = color.withOpacity(0.12)..style = PaintingStyle.fill);
    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round);

    // Point final mis en évidence
    final lastX = (points.length - 1) * dx;
    final lastY = size.height -
        ((prices.last - min) / (max - min)) * (size.height - 6) -
        3;
    canvas.drawCircle(Offset(lastX, lastY), 3.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.points.length != points.length || old.color != color;
}
