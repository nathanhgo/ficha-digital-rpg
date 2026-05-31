import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../../core/theme/theme.dart';
import 'notifications_tab.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final userId = authState.profile?['id'] as String? ?? '';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/campaigns');
            }
          },
        ),
        title: Text(
          'NOTIFICAÇÕES',
          style: GoogleFonts.cinzel(fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        color: SteampunkTheme.leatherBark,
        child: userId.isEmpty
            ? const Center(child: CircularProgressIndicator(color: SteampunkTheme.copper))
            : NotificationsTab(userId: userId),
      ),
    );
  }
}
