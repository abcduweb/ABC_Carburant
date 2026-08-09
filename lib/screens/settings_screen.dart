import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/fuel_provider.dart';
import '../services/alerts_service.dart';
import '../services/savings_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _tankCtrl;
  late TextEditingController _consoCtrl;

  bool _alertsEnabled = false;
  List<PriceAlert> _alerts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final v = context.read<FuelProvider>().vehicle;
    _tankCtrl = TextEditingController(text: v.tankLitres.toStringAsFixed(0));
    _consoCtrl = TextEditingController(text: v.consumption.toStringAsFixed(1));
    _load();
  }

  Future<void> _load() async {
    final enabled = await AlertsService.isEnabled();
    final alerts = await AlertsService.loadAlerts();
    if (!mounted) return;
    setState(() {
      _alertsEnabled = enabled;
      _alerts = alerts;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _tankCtrl.dispose();
    _consoCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveVehicle() async {
    final tank = double.tryParse(_tankCtrl.text.replaceAll(',', '.'));
    final conso = double.tryParse(_consoCtrl.text.replaceAll(',', '.'));
    if (tank == null || conso == null || tank <= 0 || conso <= 0) return;
    await context.read<FuelProvider>().setVehicle(
          VehicleSettings(tankLitres: tank, consumption: conso),
        );
  }

  Future<void> _toggleAlerts(bool value) async {
    if (value) {
      final ok = await AlertsService.requestPermission();
      if (!ok) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Notifications refusées dans les réglages')),
          );
        }
        return;
      }
    }

    final provider = context.read<FuelProvider>();
    await AlertsService.setEnabled(
      value,
      lat: provider.currentLat,
      lon: provider.currentLon,
      radiusKm: provider.radiusKm,
    );
    setState(() => _alertsEnabled = value);
  }

  Future<void> _addAlert() async {
    final provider = context.read<FuelProvider>();
    var fuel = provider.selectedFuelType;
    var threshold = 1.80;
    var favOnly = true;

    final created = await showDialog<PriceAlert>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Nouvelle alerte'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: fuel,
                decoration: const InputDecoration(labelText: 'Carburant'),
                items: const ['Gazole', 'E10', 'SP95', 'SP98', 'E85', 'GPLc']
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (v) => setLocal(() => fuel = v ?? fuel),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: threshold.toStringAsFixed(2),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Me prévenir en dessous de',
                  suffixText: '€/L',
                ),
                onChanged: (v) =>
                    threshold = double.tryParse(v.replaceAll(',', '.')) ??
                        threshold,
              ),
              const SizedBox(height: 8),
              StatefulBuilder(
                builder: (c, s2) => SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Favoris uniquement',
                      style: TextStyle(fontSize: 14)),
                  value: favOnly,
                  onChanged: (v) => s2(() => setLocal(() => favOnly = v)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () => Navigator.pop(
                ctx,
                PriceAlert(
                    fuelType: fuel,
                    threshold: threshold,
                    favoritesOnly: favOnly),
              ),
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );

    if (created == null) return;
    final updated = [..._alerts, created];
    await AlertsService.saveAlerts(updated);
    setState(() => _alerts = updated);
    if (!_alertsEnabled) await _toggleAlerts(true);
  }

  Future<void> _removeAlert(int index) async {
    final updated = [..._alerts]..removeAt(index);
    await AlertsService.saveAlerts(updated);
    setState(() => _alerts = updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const _SectionTitle('Mon véhicule'),
                const Text(
                  'Sert à calculer votre gain réel : l\'économie sur le plein, '
                  'moins le carburant dépensé pour le détour.',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tankCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Réservoir',
                          suffixText: 'L',
                          isDense: true,
                        ),
                        onChanged: (_) => _saveVehicle(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _consoCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Consommation',
                          suffixText: 'L/100',
                          isDense: true,
                        ),
                        onChanged: (_) => _saveVehicle(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                const _SectionTitle('Alertes de prix'),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Activer les alertes'),
                  subtitle: const Text(
                    'Vérification environ toutes les 6 h, quand le téléphone '
                    'est connecté.',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _alertsEnabled,
                  onChanged: _toggleAlerts,
                ),

                if (_alerts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('Aucune alerte configurée.',
                        style: TextStyle(color: Colors.grey)),
                  )
                else
                  ..._alerts.asMap().entries.map(
                        (e) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.notifications_active,
                                color: AppColors.green),
                            title: Text(
                              '${e.value.fuelType} sous '
                              '${e.value.threshold.toStringAsFixed(2)} €',
                            ),
                            subtitle: Text(
                              e.value.favoritesOnly
                                  ? 'Stations favorites'
                                  : 'Toutes les stations du rayon',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _removeAlert(e.key),
                            ),
                          ),
                        ),
                      ),

                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _addAlert,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter une alerte'),
                ),

                const SizedBox(height: 12),
                Text(
                  'Android limite les tâches de fond pour préserver la '
                  'batterie : le délai réel entre deux vérifications peut '
                  'dépasser 6 h, surtout si l\'économiseur de batterie est '
                  'actif pour cette application.',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade600, height: 1.4),
                ),

                const SizedBox(height: 24),
                Center(
                  child: TextButton.icon(
                    onPressed: () async {
                      final n = await AlertsService.check();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(n == 0
                              ? 'Aucun prix sous vos seuils actuellement'
                              : '$n alerte(s) envoyée(s)'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Tester maintenant'),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.charcoal,
          ),
        ),
      );
}
