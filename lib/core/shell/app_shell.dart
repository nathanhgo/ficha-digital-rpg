import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/auth/presentation/auth_controller.dart';

import '../../core/theme/theme.dart';

/// Shell provider to allow child routes to switch bottom nav tabs programmatically
final shellTabProvider = StateProvider<int>((ref) => 0);

class AppShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final role = authState.profile?['role'] ?? 'player';
    final userId = authState.profile?['id'] as String? ?? '';

    final isMaster = role == 'master';

    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.explore),
        label: 'Campanhas',
      ),
      BottomNavigationBarItem(
        icon: Icon(isMaster ? Icons.inventory_2 : Icons.person),
        label: isMaster ? 'Presets' : 'Personagens',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.casino),
        label: 'Rolagem',
      ),
    ];

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (idx) => navigationShell.goBranch(
          idx,
          initialLocation: idx == navigationShell.currentIndex,
        ),
        selectedItemColor: SteampunkTheme.copper,
        unselectedItemColor: Colors.white38,
        backgroundColor: SteampunkTheme.castIron,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.cinzel(fontSize: 10, fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.cinzel(fontSize: 10),
        items: items,
      ),
    );
  }
}

