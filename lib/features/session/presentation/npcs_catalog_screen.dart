import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/npc_repository.dart';
import '../../campaign/presentation/campaigns_controller.dart';
import '../../../core/theme/theme.dart';

class NpcsCatalogScreen extends ConsumerStatefulWidget {
  const NpcsCatalogScreen({super.key});

  @override
  ConsumerState<NpcsCatalogScreen> createState() => _NpcsCatalogScreenState();
}

class _NpcsCatalogScreenState extends ConsumerState<NpcsCatalogScreen> {
  final _npcRepo = NpcRepository();
  String? _selectedCampaignId;

  @override
  void initState() {
    super.initState();
    // Pre-selecionar a primeira campanha se existir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final campaigns = ref.read(campaignsControllerProvider).campaigns;
      if (campaigns.isNotEmpty && _selectedCampaignId == null) {
        setState(() {
          _selectedCampaignId = campaigns.first['id'] as String;
        });
      }
    });
  }

  void _onCreateNpc() {
    _showNpcDialog();
  }

  void _onEditNpc(Map<String, dynamic> npc) {
    _showNpcDialog(npcToEdit: npc);
  }

  void _showNpcDialog({Map<String, dynamic>? npcToEdit}) {
    if (_selectedCampaignId == null && npcToEdit == null) return;
    
    final nameCtrl = TextEditingController(text: npcToEdit?['name'] ?? '');
    final descCtrl = TextEditingController(text: npcToEdit?['description'] ?? '');
    final fvCtrl = TextEditingController(text: (npcToEdit?['max_fv'] ?? 10).toString());
    final vigorCtrl = TextEditingController(text: (npcToEdit?['max_vigor'] ?? 10).toString());
    
    final attrs = Map<String, dynamic>.from(npcToEdit?['attributes'] ?? {
      'FORÇA': 10, 'AGILIDADE': 10, 'DESTREZA': 10, 'CONSTITUIÇÃO': 10,
      'INTELIGÊNCIA': 10, 'PERCEPÇÃO': 10, 'VONTADE': 10, 'CARISMA': 10
    });

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: SteampunkTheme.castIron,
          title: Text(npcToEdit == null ? 'CRIAR NPC' : 'EDITAR NPC', style: GoogleFonts.cinzel(color: SteampunkTheme.copper)),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nome')),
                  const SizedBox(height: 8),
                  TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descrição (Opcional)'), maxLines: 3),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: fvCtrl, decoration: const InputDecoration(labelText: 'Força Vital (Máx)'), keyboardType: TextInputType.number)),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: vigorCtrl, decoration: const InputDecoration(labelText: 'Vigor (Máx)'), keyboardType: TextInputType.number)),
                    ],
                  ),
                  const Divider(color: SteampunkTheme.copper, height: 32),
                  Text('ATRIBUTOS (LIVRES)', style: GoogleFonts.cinzel()),
                  ...attrs.keys.map((key) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(key),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, color: SteampunkTheme.copper),
                                onPressed: () => setDialogState(() => attrs[key] = (attrs[key] as int) - 1),
                              ),
                              Text('${attrs[key]}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.add, color: SteampunkTheme.copper),
                                onPressed: () => setDialogState(() => attrs[key] = (attrs[key] as int) + 1),
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;
                if (npcToEdit == null) {
                  await _npcRepo.createNpc(
                    campaignId: _selectedCampaignId!,
                    name: nameCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    maxFv: int.tryParse(fvCtrl.text) ?? 10,
                    maxVigor: int.tryParse(vigorCtrl.text) ?? 10,
                    attributes: attrs,
                    habilidades: [],
                  );
                } else {
                  await _npcRepo.updateNpc(npcToEdit['id'], {
                    'name': nameCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'max_fv': int.tryParse(fvCtrl.text) ?? 10,
                    'max_vigor': int.tryParse(vigorCtrl.text) ?? 10,
                    'attributes': attrs,
                  });
                }
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('SALVAR'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignDropdown() {
    final campaigns = ref.watch(campaignsControllerProvider).campaigns;
    if (campaigns.isEmpty) return const SizedBox();
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: DropdownButtonFormField<String>(
        value: _selectedCampaignId,
        decoration: const InputDecoration(labelText: 'Campanha'),
        items: campaigns.map((c) => DropdownMenuItem<String>(
          value: c['id'] as String,
          child: Text(c['name'] as String, style: GoogleFonts.ebGaramond()),
        )).toList(),
        onChanged: (v) {
          setState(() => _selectedCampaignId = v);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SteampunkTheme.leatherBark,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _selectedCampaignId == null ? null : _onCreateNpc,
        backgroundColor: _selectedCampaignId == null ? Colors.grey : SteampunkTheme.copper,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('NOVO NPC', style: GoogleFonts.cinzel(color: Colors.white, fontSize: 12)),
      ),
      body: Column(
        children: [
          _buildCampaignDropdown(),
          Expanded(
            child: _selectedCampaignId == null
              ? Center(
                  child: Text(
                    'Selecione ou crie uma campanha primeiro.',
                    style: GoogleFonts.ebGaramond(color: Colors.white38, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                )
              : StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _npcRepo.streamNpcs(_selectedCampaignId!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: SteampunkTheme.copper));
                    }
                    final npcs = snapshot.data ?? [];
                    if (npcs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.adb, size: 64, color: Colors.white24),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhum NPC registrado.',
                              style: GoogleFonts.cinzel(fontSize: 16, color: Colors.white38),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      itemCount: npcs.length,
                      itemBuilder: (context, index) {
                        final npc = npcs[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: SteampunkTheme.leatherBark,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.adb, color: SteampunkTheme.copper, size: 32),
                            ),
                            title: Text(npc['name'] ?? '', style: GoogleFonts.cinzel(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              npc['description'] ?? 'Sem descrição',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: SteampunkTheme.bloodRed),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    backgroundColor: SteampunkTheme.castIron,
                                    title: const Text('DELETAR NPC?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('CANCELAR')),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: SteampunkTheme.bloodRed),
                                        onPressed: () => Navigator.pop(c, true),
                                        child: const Text('DELETAR'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await _npcRepo.deleteNpc(npc['id']);
                                }
                              },
                            ),
                            onTap: () => _onEditNpc(npc),
                          ),
                        );
                      },
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
