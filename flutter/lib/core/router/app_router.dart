import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/quran/screens/quran_screen.dart';
import '../../features/quran/screens/surah_reader_screen.dart';
import '../../features/duas/screens/duas_screen.dart';
import '../../features/qibla/screens/qibla_screen.dart';
import '../../features/calendar/screens/calendar_screen.dart';
import '../../features/tracker/screens/tracker_screen.dart';
import '../../features/tasbeeh/screens/tasbeeh_screen.dart';
import '../../features/mosques/screens/mosque_list_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../shell/main_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((_) => GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  redirect: (context, state) {
    // Allow guests — login only required for personal features
    return null;
  },
  routes: [
    // ── Shell (bottom nav) ──────────────────────────────────────────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => MainShell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/quran',
            builder: (c, s) => const QuranScreen(),
            routes: [
              GoRoute(
                path: 'surah/:number',
                builder: (c, s) => SurahReaderScreen(
                  surahNumber: int.parse(s.pathParameters['number']!),
                ),
              ),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/qibla', builder: (c, s) => const QiblaScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/mosques',
            builder: (c, s) => const MosqueListScreen(),
            routes: [
              GoRoute(
                path: ':slug',
                builder: (c, s) => MosqueDetailScreen(
                  slug: s.pathParameters['slug']!,
                  name: s.pathParameters['slug']!,
                ),
              ),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/more',
            builder: (c, s) => const SettingsScreen(),
            routes: [
              GoRoute(path: 'tracker',  builder: (c, s) => const TrackerScreen()),
              GoRoute(path: 'tasbeeh',  builder: (c, s) => const TasbeehScreen()),
              GoRoute(path: 'calendar', builder: (c, s) => const CalendarScreen()),
              GoRoute(path: 'duas',     builder: (c, s) => const DuasScreen()),
            ],
          ),
        ]),
      ],
    ),

    // ── Auth screens (no shell) ────────────────────────────────────────
    GoRoute(path: '/auth/login',    builder: (c, s) => const LoginScreen()),
    GoRoute(path: '/auth/register', builder: (c, s) => const RegisterScreen()),
    GoRoute(path: '/auth/forgot',   builder: (c, s) => const ForgotPasswordScreen()),
  ],
));
