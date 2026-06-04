import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/campaign/presentation/campaigns_screen.dart';
import '../../features/character/presentation/character_sheet_screen.dart';
import '../../features/character/presentation/character_create_screen.dart';
import '../../features/session/presentation/session_monitor_screen.dart';
import '../../features/public_documents/presentation/documents_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/dice/presentation/dice_screen.dart';
import '../../features/system_info/presentation/system_info_screen.dart';
import '../shell/app_shell.dart';
import '../shell/role_based_tab_screen.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isGoingToAuth = state.matchedLocation == '/login' || state.matchedLocation == '/register';

    if (session == null && !isGoingToAuth) {
      return '/login';
    }
    if (session != null && isGoingToAuth) {
      return '/campaigns';
    }
    return null;
  },
  routes: [
    // ── Root redirect ─────────────────────────────────────────────────────
    GoRoute(
      path: '/',
      redirect: (context, state) => '/campaigns',
    ),
    // ── Public routes (no shell) ──────────────────────────────────────────
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),

    // ── Authenticated shell (BottomNav persists) ──────────────────────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(navigationShell: shell),
      branches: [
        // Branch 0: Campanhas
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/campaigns',
              builder: (context, state) => const CampaignsScreen(),
              routes: [
                GoRoute(
                  path: 'session/:campaignId',
                  builder: (context, state) {
                    final campaignId = state.pathParameters['campaignId'] ?? '';
                    return SessionMonitorScreen(campaignId: campaignId);
                  },
                ),
                GoRoute(
                  path: 'documents',
                  builder: (context, state) {
                    final campaignId = state.uri.queryParameters['campaignId'] ?? '';
                    return DocumentsScreen(campaignId: campaignId);
                  },
                ),
                GoRoute(
                  path: 'character/:id',
                  builder: (context, state) {
                    final charId = state.pathParameters['id'] ?? '';
                    return CharacterSheetScreen(characterId: charId);
                  },
                ),
                GoRoute(
                  path: 'character/create/:campaignId',
                  builder: (context, state) {
                    final campaignId = state.pathParameters['campaignId'] ?? '';
                    return CharacterCreateScreen(campaignId: campaignId);
                  },
                ),
              ],
            ),
          ],
        ),

        // Branch 1: Personagens (player) / Itens (master)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/characters-or-items',
              builder: (context, state) => const RoleBasedTabScreen(),
            ),
          ],
        ),

        // Branch 2: Rolagem (Dice)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dice',
              builder: (context, state) => const DiceScreen(),
            ),
          ],
        ),
      ],
    ),

    // ── Root routes that overlay the shell ──────────────────────────
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/system-info',
      builder: (context, state) => const SystemInfoScreen(),
    ),
  ],
);
