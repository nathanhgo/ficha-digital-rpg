import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/inventory/presentation/items_catalog_screen.dart';
import '../../features/character/presentation/characters_tab_screen.dart';

class RoleBasedTabScreen extends ConsumerWidget {
  const RoleBasedTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final role = authState.profile?['role'] ?? 'player';

    if (role == 'master') {
      return const ItemsCatalogScreen();
    } else {
      return const CharactersTabScreen();
    }
  }
}
