import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart' as intl_data;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;

import 'app.dart';
import 'core/config/feature_flags.dart';
import 'core/constants/app_constants.dart';
import 'core/services/notification_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize IANA timezone database for nextOccurrence() helper.
  tz_data.initializeTimeZones();

  // Locale data para DateFormat en español (formateo de "EEE d MMM").
  await intl_data.initializeDateFormatting('es');

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize FCM + local notifications (canal, permisos, handlers).
  await NotificationService.instance.init();

  // Initialize Remote Config (feature flags). Defaults aplican aunque haya
  // fallo de red en el primer fetch.
  final featureFlags = await FeatureFlags.initialize();

  // Initialize Hive
  await Hive.initFlutter();
  await Hive.openBox<String>(AppConstants.polylineCacheBox);
  await Hive.openBox(AppConstants.userPrefsBox);

  // Configure Mapbox
  final mapboxToken = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
  if (mapboxToken.isNotEmpty) {
    MapboxOptions.setAccessToken(mapboxToken);
  }

  runApp(ProviderScope(
    overrides: [
      featureFlagsProvider.overrideWithValue(featureFlags),
    ],
    child: const App(),
  ));
}
