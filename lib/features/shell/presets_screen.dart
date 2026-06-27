import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/theme.dart';
import '../inventory/presentation/items_catalog_screen.dart';
import '../session/presentation/npcs_catalog_screen.dart';

class PresetsScreen extends ConsumerStatefulWidget {
  const PresetsScreen({super.key});

  @override
  ConsumerState<PresetsScreen> createState() => _PresetsScreenState();
}

class _PresetsScreenState extends ConsumerState<PresetsScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('PRESETS', style: GoogleFonts.cinzel(fontWeight: FontWeight.bold)),
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            labelColor: SteampunkTheme.copper,
            unselectedLabelColor: Colors.white60,
            indicatorColor: SteampunkTheme.copper,
            tabs: [
              Tab(icon: Icon(Icons.inventory_2), text: 'ITENS'),
              Tab(icon: Icon(Icons.adb), text: 'NPCs / MONSTROS'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ItemsCatalogScreen(isEmbedded: true),
            NpcsCatalogScreen(),
          ],
        ),
      ),
    );
  }
}
