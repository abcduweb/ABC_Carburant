import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/alerts_service.dart';
import 'package:provider/provider.dart';
import 'providers/fuel_provider.dart';
import 'providers/charging_provider.dart';
import 'providers/tesla_provider.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  await AlertsService.init();
  runApp(const FuelCompareApp());
}

class FuelCompareApp extends StatelessWidget {
  const FuelCompareApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FuelProvider()),
        ChangeNotifierProvider(create: (_) => ChargingProvider()),
        ChangeNotifierProvider(create: (_) => TeslaProvider()),
      ],
      child: MaterialApp(
        title: 'ABC Carburant',
        theme: AppTheme.light,
        locale: const Locale('fr', 'FR'),
        supportedLocales: const [Locale('fr', 'FR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        debugShowCheckedModeBanner: false,
        home: const HomeScreen(),
      ),
      // © 2026 ABCduWeb - Beauvallon, Drôme-Ardèche, France
    );
  }
}
