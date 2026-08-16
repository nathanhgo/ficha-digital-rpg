import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
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

/// Faz o [GoRouter] reavaliar o [redirect] sempre que o estado de auth do
/// Supabase mudar (login/logout, mas também eventos assíncronos que não
/// resultam de uma navegação explícita, como o retorno de um deep link de
/// recuperação de senha ou de login com Google).
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<AuthState> stream) {
    _subscription = stream.listen((authState) {
      if (authState.event == AuthChangeEvent.passwordRecovery) {
        _pendingPasswordRecovery = true;
      }
      notifyListeners();
    });
  }

  bool _pendingPasswordRecovery = false;

  /// Retorna `true` uma única vez após um evento de recuperação de senha,
  /// consumindo a flag para não forçar o redirect repetidamente.
  bool consumePendingPasswordRecovery() {
    final value = _pendingPasswordRecovery;
    _pendingPasswordRecovery = false;
    return value;
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final _authRefreshStream = GoRouterRefreshStream(Supabase.instance.client.auth.onAuthStateChange);

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  refreshListenable: _authRefreshStream,
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isGoingToAuth = state.matchedLocation == '/login' || state.matchedLocation == '/register';
    final isGoingToPasswordFlow =
        state.matchedLocation == '/forgot-password' || state.matchedLocation == '/reset-password';

    // Evento PASSWORD_RECOVERY: independentemente de onde o usuário estiver
    // (ex: acabou de abrir o app pelo link do e-mail), leva para a tela de
    // nova senha.
    if (_authRefreshStream.consumePendingPasswordRecovery()) {
      return '/reset-password';
    }

    if (session == null && !isGoingToAuth && !isGoingToPasswordFlow) {
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
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) => const ResetPasswordScreen(),
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
                    final isReadOnly = state.uri.queryParameters['readOnly'] == 'true';
                    return CharacterSheetScreen(characterId: charId, isReadOnly: isReadOnly);
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
