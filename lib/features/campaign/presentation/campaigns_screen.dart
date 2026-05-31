import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/campaign_repository.dart';
import '../../notifications/presentation/notification_badge_icon.dart';
import 'campaigns_controller.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/storage_helper.dart';
import 'package:file_picker/file_picker.dart';

class CampaignsScreen extends ConsumerStatefulWidget {
  const CampaignsScreen({super.key});

  @override
  ConsumerState<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends ConsumerState<CampaignsScreen> {

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(campaignsControllerProvider.notifier).loadCampaigns();
    });
  }

  void _onCreateCampaign() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? mapUrl;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: SteampunkTheme.castIron,
          title: Text('CRIAR CAMPANHA', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nome da Campanha'),
                  validator: (v) => v == null || v.isEmpty ? 'Insira um nome' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                if (mapUrl != null && mapUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(mapUrl!, height: 100, width: double.infinity, fit: BoxFit.cover),
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final url = await SupabaseStorageHelper.pickAndUploadFile(fileType: FileType.image);
                    if (url != null) setDialogState(() => mapUrl = url);
                  },
                  icon: const Icon(Icons.map, size: 16),
                  label: Text(mapUrl == null ? 'CARREGAR MAPA (FOTO)' : 'ALTERAR MAPA'),
                ),
              ],
            ),
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCELAR', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final navigator = Navigator.of(ctx);
                  final success = await ref.read(campaignsControllerProvider.notifier)
                      .createCampaign(nameController.text.trim(), descController.text.trim(), mapUrl);
                  if (success && mounted) navigator.pop();
                }
              },
              child: const Text('CRIAR'),
            ),
          ],
        ),
      ),
    );
  }

  void _onJoinCampaign() {
    final codeController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SteampunkTheme.castIron,
        title: Text('ENTRAR EM CAMPANHA', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Insira o ID/Código da campanha fornecido pelo seu Mestre.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: codeController,
                decoration: const InputDecoration(labelText: 'ID da Campanha'),
                validator: (v) => v == null || v.isEmpty ? 'Insira o ID' : null,
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final navigator = Navigator.of(ctx);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final success = await ref
                    .read(campaignsControllerProvider.notifier)
                    .joinCampaign(codeController.text.trim());
                if (success && mounted) {
                  navigator.pop();
                } else if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('ID inválido ou erro ao entrar.'),
                      backgroundColor: SteampunkTheme.bloodRed,
                    ),
                  );
                }
              }
            },
            child: const Text('ENTRAR'),
          ),
        ],
      ),
    );
  }

  void _handleCampaignTap(Map<String, dynamic> campaign) {
    final campaignId = campaign['id'] as String;
    // Both master and player go to the SessionMonitorScreen
    context.push('/campaigns/session/$campaignId');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(campaignsControllerProvider);
    final authState = ref.watch(authControllerProvider);
    final role = authState.profile?['role'] ?? 'player';
    final username = authState.profile?['username'] ?? 'Usuário';

    return Scaffold(
      appBar: AppBar(
        title: Text('CAMPANHAS', style: GoogleFonts.cinzel(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
        actions: [
          NotificationBadgeIcon(userId: authState.profile?['id'] as String? ?? ''),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () async {
              final router = GoRouter.of(context);
              await ref.read(authControllerProvider.notifier).logout();
              router.go('/login');
            },
          ),
        ],
      ),
      body: Container(
        color: SteampunkTheme.leatherBark,
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator(color: SteampunkTheme.copper))
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Bem-vindo de volta, $username',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role == 'master' ? 'Mestre de Jogo' : 'Jogador / Aventureiro',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: SteampunkTheme.copper),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => context.push('/system-info'),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: SteampunkTheme.copper.withValues(alpha: 0.1),
                          border: Border.all(color: SteampunkTheme.copper.withValues(alpha: 0.5)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.menu_book, color: SteampunkTheme.copper, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'SAIBA MAIS SOBRE O SISTEMA',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: SteampunkTheme.copper,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: state.campaigns.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.explore_outlined, size: 64, color: Colors.white24),
                                  const SizedBox(height: 16),
                                  Text(
                                    role == 'master'
                                        ? 'Nenhuma campanha criada ainda.'
                                        : 'Você não está em nenhuma campanha.',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white60),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () =>
                                  ref.read(campaignsControllerProvider.notifier).loadCampaigns(),
                              color: SteampunkTheme.copper,
                              child: ListView.builder(
                                itemCount: state.campaigns.length,
                                itemBuilder: (context, idx) {
                                  final camp = state.campaigns[idx];
                                  final mapUrl = camp['map_url'] as String?;
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () => _handleCampaignTap(camp),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (mapUrl != null && mapUrl.isNotEmpty) ...[
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(6),
                                                child: Image.network(
                                                  mapUrl,
                                                  width: 80,
                                                  height: 80,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                            ],
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    (camp['name'] as String).toUpperCase(),
                                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                          color: SteampunkTheme.copper,
                                                          fontSize: 18,
                                                        ),
                                                  ),
                                                  if (camp['description'] != null && camp['description'].toString().isNotEmpty) ...[
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      camp['description'],
                                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                            fontSize: 13,
                                                            color: Colors.white70,
                                                          ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: SelectableText(
                                                          'Código: ${camp['id']}',
                                                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                                                color: Colors.white30,
                                                                fontSize: 10,
                                                              ),
                                                        ),
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(Icons.copy, size: 16, color: SteampunkTheme.copper),
                                                        onPressed: () {
                                                          Clipboard.setData(ClipboardData(text: camp['id'].toString()));
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(content: Text('Código copiado para a área de transferência!')),
                                                          );
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: role == 'master' ? _onCreateCampaign : _onJoinCampaign,
                      child: Text(role == 'master' ? 'CRIAR NOVA CAMPANHA' : 'ENTRAR EM CAMPANHA VIA CÓDIGO'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
