import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/api/api_client.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/notifications/notification_service.dart';

const _kFirstRunPermissionsRequested = 'first_run_permissions_requested_v1';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  ApiClient.init(baseUrl: const String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://mosque-admin.randrdevelopers.co.za/v2',
  ));

  await NotificationService.init();

  runApp(const ProviderScope(child: CapeNoorApp()));

  // Ask once on first launch so users don't have to discover permissions later.
  _requestFirstRunPermissions();
}

Future<void> _requestFirstRunPermissions() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final alreadyAsked = prefs.getBool(_kFirstRunPermissionsRequested) ?? false;
    if (alreadyAsked) return;

    await NotificationService.requestPermission();

    final locationPermission = await Geolocator.checkPermission();
    if (locationPermission == LocationPermission.denied ||
        locationPermission == LocationPermission.deniedForever ||
        locationPermission == LocationPermission.unableToDetermine) {
      await Geolocator.requestPermission();
    }

    await prefs.setBool(_kFirstRunPermissionsRequested, true);
  } catch (_) {
    // Ignore startup permission errors and continue app boot.
  }
}

class CapeNoorApp extends ConsumerWidget {
  const CapeNoorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Cape Noor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
