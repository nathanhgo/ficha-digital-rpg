import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../campaign/presentation/campaigns_controller.dart';
import '../../../core/theme/theme.dart';
import 'characters_provider.dart';

/// Standalone screen for the Player's "Personagens" bottom-nav branch.
class CharactersTabScreen extends ConsumerWidget {
  const CharactersTabScreen({super.key});

  void _onCreateCharacter(BuildContext context, WidgetRef ref) async {
    final authState = ref.read(authControllerProvider);
    final userId = authState.profile?['id'] as String? ?? '';
    if (userId.isEmpty) return;

    // Load available campaigns for the user
    final campaignsState = ref.read(campaignsControllerProvider);
    final campaigns = campaignsState.campaigns;

    String? selectedCampaignId;
    if (campaigns.isEmpty) {
      // Create avulso character (no campaign)
      context.push('/campaigns/character/create/avulso');
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setDialogState) => AlertDialog(
          backgroundColor: SteampunkTheme.castIron,
          title: Text(
            'NOVO PERSONAGEM',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Selecione a campanha do personagem:',
                style: GoogleFonts.ebGaramond(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedCampaignId,
                hint: Text('Nenhuma (Avulso)', style: GoogleFonts.ebGaramond(color: Colors.white54)),
                decoration: const InputDecoration(labelText: 'Campanha'),
                items: [
                  DropdownMenuItem<String>(
                    value: 'avulso',
                    child: Text('Nenhuma (Avulso)', style: GoogleFonts.ebGaramond()),
                  ),
                  ...campaigns.map((c) => DropdownMenuItem<String>(
                    value: c['id'] as String,
                    child: Text(c['name'] as String, style: GoogleFonts.ebGaramond()),
                  )),
                ],
                onChanged: (v) => setDialogState(() => selectedCampaignId = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCELAR', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () {
                final cId = selectedCampaignId ?? 'avulso';
                Navigator.pop(ctx);
                context.push('/campaigns/character/create/$cId');
              },
              child: const Text('AVANÇAR'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final charactersAsync = ref.watch(userCharactersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('MEUS PERSONAGENS', style: GoogleFonts.cinzel(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _onCreateCharacter(context, ref),
        backgroundColor: SteampunkTheme.copper,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('NOVO PERSONAGEM', style: GoogleFonts.cinzel(color: Colors.white, fontSize: 12)),
      ),
      body: Container(
        color: SteampunkTheme.leatherBark,
        child: charactersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: SteampunkTheme.copper)),
          error: (err, stack) => Center(
            child: Text(
              'Erro ao carregar personagens: $err',
              style: GoogleFonts.ebGaramond(color: Colors.white54),
            ),
          ),
          data: (characters) {
            if (characters.isEmpty) {
              return LayoutBuilder(
                builder: (context, constraints) => RefreshIndicator(
                  onRefresh: () => ref.refresh(userCharactersProvider.future),
                  color: SteampunkTheme.copper,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 60),
                            const Icon(Icons.person_outline, size: 64, color: Colors.white24),
                            const SizedBox(height: 16),
                            Text(
                              'Você ainda não possui personagens.',
                              style: GoogleFonts.ebGaramond(fontSize: 16, color: Colors.white38),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Crie um novo usando o botão abaixo.',
                              style: GoogleFonts.ebGaramond(fontSize: 14, color: Colors.white24),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => ref.refresh(userCharactersProvider.future),
              color: SteampunkTheme.copper,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: characters.length,
                itemBuilder: (context, idx) {
                  final char = characters[idx];
                  final id = char['id'] as String;
                  final name = char['name'] ?? 'Sem Nome';
                  final charClass = char['char_class'] ?? 'Sem Classe';
                  final level = char['level'] ?? 0;
                  final xp = char['xp'] ?? 0;
                  final campaignName = char['campaigns']?['name'] ?? 'Ficha Avulsa';
                  final isDead = char['is_dead'] == true;
                  final avatarUrl = char['avatar_url'] as String?;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: isDead ? SteampunkTheme.castIron.withValues(alpha: 0.5) : SteampunkTheme.castIron,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isDead
                            ? Colors.white12
                            : SteampunkTheme.copper.withValues(alpha: 0.3),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor: SteampunkTheme.leatherBark,
                        backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: avatarUrl == null || avatarUrl.isEmpty
                            ? Icon(
                                isDead ? Icons.person_off : Icons.person,
                                color: isDead ? Colors.white24 : SteampunkTheme.copper,
                                size: 28,
                              )
                            : null,
                      ),
                      title: Text(
                        name.toUpperCase(),
                        style: GoogleFonts.cinzel(
                          fontWeight: FontWeight.bold,
                          color: isDead ? Colors.white30 : SteampunkTheme.copper,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nível $level $charClass${isDead ? ' ✝ MORTO' : ''}',
                            style: GoogleFonts.ebGaramond(color: Colors.white60, fontSize: 13),
                          ),
                          Text(
                            'Campanha: $campaignName  •  $xp XP',
                            style: GoogleFonts.ebGaramond(color: Colors.white38, fontSize: 12),
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, color: SteampunkTheme.copper, size: 16),
                      onTap: () => context.push('/campaigns/character/$id'),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
