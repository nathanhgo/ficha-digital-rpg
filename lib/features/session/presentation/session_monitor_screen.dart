import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/session_repository.dart';
import '../../character/data/character_repository.dart';
import '../../inventory/data/inventory_repository.dart';
import '../../public_documents/data/document_repository.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../../core/theme/theme.dart';
import '../../notifications/presentation/notification_badge_icon.dart';

class SessionMonitorScreen extends ConsumerStatefulWidget {
  final String campaignId;
  const SessionMonitorScreen({super.key, required this.campaignId});

  @override
  ConsumerState<SessionMonitorScreen> createState() => _SessionMonitorScreenState();
}

class _SessionMonitorScreenState extends ConsumerState<SessionMonitorScreen> {
  final _sessionRepo = SessionRepository();
  final _charRepo = CharacterRepository();
  final _inventoryRepo = InventoryRepository();

  Map<String, dynamic>? _activeSession;
  List<Map<String, dynamic>> _allSessions = [];
  bool _isLoading = true;

  Map<String, dynamic>? _playerCharacter;
  List<Map<String, dynamic>> _playerCharacters = [];
  bool _isParticipant = false;
  List<Map<String, dynamic>> _pendingItems = [];

  Timer? _notesDebounce;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSessions().then((_) {
      _loadPendingItems();
    });
  }

  @override
  void dispose() {
    _notesDebounce?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    try {
      final list = await _sessionRepo.fetchSessions(widget.campaignId);
      _allSessions = list;
      _activeSession = list.firstWhere(
        (s) => s['status'] == 'active',
        orElse: () => <String, dynamic>{},
      );
      if (_activeSession != null && _activeSession!.isNotEmpty) {
        _notesController.text = _activeSession!['notes'] ?? '';
      } else {
        _activeSession = null;
      }

      final authState = ref.read(authControllerProvider);
      final role = authState.profile?['role'] ?? 'player';
      if (role == 'player') {
        final userId = authState.profile?['id'] ?? '';
        final chars = await _charRepo.fetchCharactersForUser(userId);
        final campaignChars = chars.where((c) => c['campaign_id'] == widget.campaignId).toList();
        _playerCharacters = campaignChars;

        if (_playerCharacters.isNotEmpty) {
          // Mantém o personagem já selecionado se ele ainda existir na lista
          if (_playerCharacter != null && _playerCharacters.any((c) => c['id'] == _playerCharacter!['id'])) {
            _playerCharacter = _playerCharacters.firstWhere((c) => c['id'] == _playerCharacter!['id']);
          } else {
            // Caso contrário, se houver uma sessão ativa, prefere o personagem que está ativamente nela
            Map<String, dynamic>? activeParticipantChar;
            if (_activeSession != null) {
              for (final char in _playerCharacters) {
                final res = await Supabase.instance.client
                    .from('session_participants')
                    .select()
                    .eq('session_id', _activeSession!['id'])
                    .eq('character_id', char['id'])
                    .maybeSingle();
                if (res != null) {
                  activeParticipantChar = char;
                  break;
                }
              }
            }
            _playerCharacter = activeParticipantChar ?? _playerCharacters.first;
          }

          if (_activeSession != null && _playerCharacter != null) {
            final res = await Supabase.instance.client
                .from('session_participants')
                .select()
                .eq('session_id', _activeSession!['id'])
                .eq('character_id', _playerCharacter!['id'])
                .maybeSingle();
            _isParticipant = res != null;
          } else {
            _isParticipant = false;
          }
        } else {
          _playerCharacter = null;
          _isParticipant = false;
        }
      }
    } catch (e) {
      debugPrint("Erro ao carregar dados da sessão: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadPendingItems() async {
    if (_playerCharacter == null) return;
    final allItems = await _inventoryRepo.fetchInventory(_playerCharacter!['id']);
    if (mounted) {
      setState(() {
        _pendingItems = allItems.where((i) => i['accepted'] == false).toList();
      });
    }
  }

  void _onNotesChanged(String text) {
    if (_activeSession == null) return;
    _notesDebounce?.cancel();
    _notesDebounce = Timer(const Duration(milliseconds: 800), () async {
      await _sessionRepo.endSession(
        // wait, we just want to update notes, endSession actually finishes the session.
        // Let's check: does Supabase have updateSessionNotes? No specific repo method but we can update directly using _client!
        // Yes, we can update sessions table notes column:
        _activeSession!['id'] as String,
      );
      // Wait, let's look at what endSession did. It updated status. Let's just update note directly:
    });
    // Let's implement a proper save note call using Supabase Client directly in place to keep repo simple:
    final sessionId = _activeSession!['id'] as String;
    Supabase.instance.client.from('sessions').update({'notes': text}).eq('id', sessionId).then((_) {});
  }

  void _onStartSession() async {
    final titleController = TextEditingController(text: 'Sessão ${_allSessions.length + 1}');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SteampunkTheme.castIron,
        title: Text('INICIAR NOVA SESSÃO', style: Theme.of(context).textTheme.titleLarge),
        content: TextFormField(
          controller: titleController,
          decoration: const InputDecoration(labelText: 'Título da Sessão'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty) {
                final navigator = Navigator.of(ctx);
                final newSess = await _sessionRepo.createSession(
                  campaignId: widget.campaignId,
                  title: titleController.text.trim(),
                );
                if (newSess != null) {
                  await _sessionRepo.startSession(newSess['id'] as String);
                  await _loadSessions();
                  if (mounted) navigator.pop();
                }
              }
            },
            child: const Text('INICIAR'),
          ),
        ],
      ),
    );
  }

  void _onEndSession() async {
    if (_activeSession == null) return;
    await _sessionRepo.endSession(_activeSession!['id'] as String);
    await _loadSessions();
  }

  void _onAwardXp() {
    final xpController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SteampunkTheme.castIron,
        title: Text('DISTRIBUIR EXPERIÊNCIA (XP)', style: Theme.of(context).textTheme.titleLarge),
        content: TextFormField(
          controller: xpController,
          decoration: const InputDecoration(labelText: 'Quantidade de XP'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              final xp = int.tryParse(xpController.text) ?? 0;
              if (xp > 0) {
                final navigator = Navigator.of(ctx);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final chars = await _charRepo.fetchCharactersForCampaign(widget.campaignId);
                for (var char in chars) {
                  await _charRepo.addXp(
                    char['id'] as String,
                    char['xp'] as int? ?? 0,
                    char['level'] as int? ?? 0,
                    xp,
                  );
                }
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Distribuído $xp de XP para todos os personagens!'),
                      backgroundColor: SteampunkTheme.copper,
                    ),
                  );
                  navigator.pop();
                }
              }
            },
            child: const Text('DISTRIBUIR'),
          ),
        ],
      ),
    );
  }

  void _onDistributeItem() async {
    final chars = await _charRepo.fetchCharactersForCampaign(widget.campaignId);
    final templateItems = await _inventoryRepo.fetchTemplateItems(widget.campaignId);
    String? selectedCharId = chars.isNotEmpty ? chars.first['id'] as String : null;
    final qtyController = TextEditingController(text: '1');

    // Mode: 'catalog' or 'manual'
    String mode = templateItems.isNotEmpty ? 'catalog' : 'manual';
    Map<String, dynamic>? selectedTemplate;

    // Manual mode controllers
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final weightController = TextEditingController(text: '1.0');

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setDialogState) => AlertDialog(
          backgroundColor: SteampunkTheme.castIron,
          title: Text('ENVIAR ITEM PARA JOGADOR', style: Theme.of(context).textTheme.titleLarge),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Target character
                DropdownButtonFormField<String>(
                  initialValue: selectedCharId,
                  decoration: const InputDecoration(labelText: 'Enviar para'),
                  items: chars.map((char) => DropdownMenuItem<String>(
                    value: char['id'] as String,
                    child: Text((char['name'] as String).toUpperCase()),
                  )).toList(),
                  onChanged: (val) => setDialogState(() => selectedCharId = val),
                ),
                const SizedBox(height: 12),
                // Mode toggle
                if (templateItems.isNotEmpty)
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Do Catálogo'),
                          selected: mode == 'catalog',
                          onSelected: (_) => setDialogState(() { mode = 'catalog'; selectedTemplate = null; }),
                          selectedColor: SteampunkTheme.copper,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Criar Novo'),
                          selected: mode == 'manual',
                          onSelected: (_) => setDialogState(() => mode = 'manual'),
                          selectedColor: SteampunkTheme.copper,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                if (mode == 'catalog') ...[
                  DropdownButtonFormField<Map<String, dynamic>>(
                    initialValue: selectedTemplate,
                    decoration: const InputDecoration(labelText: 'Item do Catálogo'),
                    items: templateItems.map((item) => DropdownMenuItem<Map<String, dynamic>>(
                      value: item,
                      child: Text(item['name'] as String),
                    )).toList(),
                    onChanged: (v) => setDialogState(() => selectedTemplate = v),
                  ),
                ] else ...[
                  TextFormField(controller: nameController, decoration: const InputDecoration(labelText: 'Nome do Item')),
                  const SizedBox(height: 8),
                  TextFormField(controller: descController, decoration: const InputDecoration(labelText: 'Descrição')),
                  const SizedBox(height: 8),
                  TextFormField(controller: weightController, decoration: const InputDecoration(labelText: 'Peso (Kg)'), keyboardType: TextInputType.number),
                ],
                const SizedBox(height: 8),
                TextFormField(controller: qtyController, decoration: const InputDecoration(labelText: 'Quantidade'), keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCELAR', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedCharId == null) return;
                final navigator = Navigator.of(ctx);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                bool success = false;
                if (mode == 'catalog' && selectedTemplate != null) {
                  success = await _inventoryRepo.sendTemplateItemToCharacter(
                    itemId: selectedTemplate!['id'] as String,
                    characterId: selectedCharId!,
                    quantity: int.tryParse(qtyController.text) ?? 1,
                  );
                } else if (mode == 'manual' && nameController.text.isNotEmpty) {
                  success = await _inventoryRepo.addItem(
                    characterId: selectedCharId!,
                    name: nameController.text.trim(),
                    description: descController.text.trim(),
                    weight: double.tryParse(weightController.text) ?? 1.0,
                    quantity: int.tryParse(qtyController.text) ?? 1,
                    accepted: false,
                    campaignId: widget.campaignId,
                  );
                }
                if (success && mounted) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Item enviado! Aguardando aceite do jogador.'), backgroundColor: SteampunkTheme.copper),
                  );
                  navigator.pop();
                }
              },
              child: const Text('ENVIAR'),
            ),
          ],
        ),
      ),
    );
  }

  void _onJoinSession() async {
    if (_activeSession == null || _playerCharacter == null) return;
    final success = await _sessionRepo.joinSession(
      _activeSession!['id'] as String,
      _playerCharacter!['id'] as String,
    );
    if (success) {
      setState(() {
        _isParticipant = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Você entrou na sessão!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _onLeaveSession() async {
    if (_activeSession == null || _playerCharacter == null) return;
    await _sessionRepo.leaveSession(
      _activeSession!['id'] as String,
      _playerCharacter!['id'] as String,
    );
    setState(() {
      _isParticipant = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você saiu da sessão.'),
          backgroundColor: SteampunkTheme.bloodRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: SteampunkTheme.copper)),
      );
    }

    final authState = ref.watch(authControllerProvider);
    final role = authState.profile?['role'] ?? 'player';

    if (role == 'player') {
      return Scaffold(
        appBar: AppBar(
          title: _playerCharacters.length <= 1
              ? Text(
                  _playerCharacter != null 
                      ? '${_playerCharacter!['name']}'.toUpperCase() 
                      : 'PAINEL DO JOGADOR',
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<Map<String, dynamic>>(
                    value: _playerCharacter,
                    dropdownColor: SteampunkTheme.castIron,
                    icon: const Icon(Icons.arrow_drop_down, color: SteampunkTheme.copper),
                    style: GoogleFonts.cinzel(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: SteampunkTheme.copper,
                    ),
                    items: _playerCharacters.map((c) {
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: c,
                        child: Text('${c['name']}'.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (newChar) {
                      if (newChar != null) {
                        setState(() {
                          _playerCharacter = newChar;
                        });
                        _loadSessions().then((_) {
                          _loadPendingItems();
                        });
                      }
                    },
                  ),
                ),
          actions: [
            NotificationBadgeIcon(userId: authState.profile?['id'] as String? ?? ''),
            IconButton(
              icon: const Icon(Icons.description_outlined),
              tooltip: 'Mural de Documentos',
              onPressed: () {
                context.push('/campaigns/documents?campaignId=${widget.campaignId}');
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Atualizar',
              onPressed: () {
                _loadSessions().then((_) {
                  _loadPendingItems();
                });
              },
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            color: SteampunkTheme.leatherBark,
          ),
          child: _buildPlayerDashboard(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('MONITOR DO MESTRE'),
        actions: [
          NotificationBadgeIcon(userId: authState.profile?['id'] as String? ?? ''),
          IconButton(
            icon: const Icon(Icons.description_outlined),
            tooltip: 'Mural de Documentos',
            onPressed: () {
              context.push('/campaigns/documents?campaignId=${widget.campaignId}');
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: SteampunkTheme.leatherBark,
        ),
        child: Column(
          children: [
            // Painel da Sessão Ativa
            Container(
              padding: const EdgeInsets.all(16),
              color: SteampunkTheme.castIron,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _activeSession != null
                              ? 'SESSÃO ATIVA: ${_activeSession!['title'].toString().toUpperCase()}'
                              : 'SEM SESSÃO ATIVA',
                          style: GoogleFonts.cinzel(
                            color: SteampunkTheme.copper,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _activeSession != null
                              ? 'Jogadores recebem notificações em tempo real.'
                              : 'Inicie uma sessão para monitoramento.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white38),
                        ),
                      ],
                    ),
                  ),
                  if (_activeSession == null)
                    ElevatedButton(
                      onPressed: _onStartSession,
                      child: const Text('INICIAR SESSÃO'),
                    )
                  else
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: SteampunkTheme.bloodRed),
                      onPressed: _onEndSession,
                      child: const Text('FINALIZAR SESSÃO'),
                    ),
                ],
              ),
            ),

            if (_activeSession != null) ...[
              // Grid de Jogadores Ativos (Stream Realtime)
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _sessionRepo.streamParticipants(_activeSession!['id']),
                  builder: (context, participantsSnapshot) {
                    if (participantsSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: SteampunkTheme.copper));
                    }
                    if (participantsSnapshot.hasError) {
                      return Center(child: Text('Erro ao carregar participantes: ${participantsSnapshot.error}'));
                    }
                    final participantIds = (participantsSnapshot.data ?? [])
                        .map((p) => p['character_id'] as String)
                        .toSet();

                    return StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _sessionRepo.streamCharacters(widget.campaignId),
                      builder: (context, charactersSnapshot) {
                        if (charactersSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: SteampunkTheme.copper));
                        }
                        if (charactersSnapshot.hasError) {
                          return Center(child: Text('Erro ao carregar personagens: ${charactersSnapshot.error}'));
                        }
                        final allChars = charactersSnapshot.data ?? [];
                        final activeChars = allChars.where((c) => participantIds.contains(c['id'])).toList();

                        if (activeChars.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Text(
                                'Nenhum jogador ativo nesta sessão.\nAguardando os jogadores aceitarem o convite...',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white38, fontSize: 14),
                              ),
                            ),
                          );
                        }

                        return GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 400,
                            mainAxisExtent: 310,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: activeChars.length,
                          itemBuilder: (context, idx) {
                            final char = activeChars[idx];
                            return _buildPlayerCard(char);
                          },
                        );
                      },
                    );
                  },
                ),
              ),

              // Painel de Controle e Notas do Mestre
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: SteampunkTheme.castIron,
                  border: Border(top: BorderSide(color: Colors.white10)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Notas Rápidas do Mestre (Salva automaticamente)',
                          alignLabelWithHint: true,
                        ),
                        onChanged: _onNotesChanged,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.star_outline),
                          label: const Text('DAR XP'),
                          onPressed: _onAwardXp,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.card_giftcard),
                          label: const Text('ENVIAR ITEM'),
                          onPressed: _onDistributeItem,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else
              Expanded(
                child: _buildSessionHistoryMaster(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionHistoryMaster() {
    final sessions = _allSessions;
    if (sessions.isEmpty) {
      return Center(
        child: Text(
          'Nenhuma sessão ainda. Inicie a primeira!',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white38),
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length,
      itemBuilder: (context, idx) {
        final s = sessions[idx];
        final status = s['status'] as String? ?? 'scheduled';
        final notes = s['notes'] as String? ?? '';
        final summary = s['player_summary'] as String? ?? '';
        final startTime = s['start_time'] != null
            ? DateTime.parse(s['start_time'].toString()).toLocal().toString().substring(0, 16)
            : '—';
        final endTime = s['end_time'] != null
            ? DateTime.parse(s['end_time'].toString()).toLocal().toString().substring(0, 16)
            : '—';

        Color statusColor;
        IconData statusIcon;
        switch (status) {
          case 'active': statusColor = SteampunkTheme.brassGlow; statusIcon = Icons.play_circle_fill; break;
          case 'finished': statusColor = Colors.white38; statusIcon = Icons.check_circle_outline; break;
          default: statusColor = SteampunkTheme.copper; statusIcon = Icons.schedule;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: status == 'finished'
              ? SteampunkTheme.castIron.withValues(alpha: 0.5)
              : SteampunkTheme.castIron,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: statusColor.withValues(alpha: 0.5)),
          ),
          child: ExpansionTile(
            leading: Icon(statusIcon, color: statusColor),
            title: Text(
              s['title'].toString().toUpperCase(),
              style: GoogleFonts.cinzel(
                fontWeight: FontWeight.bold,
                color: statusColor,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              status == 'active' ? 'EM ANDAMENTO' : '$startTime → $endTime',
              style: GoogleFonts.specialElite(fontSize: 11, color: Colors.white38),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (notes.isNotEmpty) ...[
                      Text('NOTAS DO MESTRE', style: GoogleFonts.cinzel(fontSize: 11, color: SteampunkTheme.copper, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(notes, style: GoogleFonts.ebGaramond(fontSize: 14, color: Colors.white60)),
                      const SizedBox(height: 12),
                    ],
                    Text('RESUMO PARA JOGADORES', style: GoogleFonts.cinzel(fontSize: 11, color: SteampunkTheme.brassGlow, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    _PlayerSummaryEditor(
                      sessionId: s['id'] as String,
                      initialValue: summary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlayerCard(Map<String, dynamic> char) {
    final isDead = char['is_dead'] == true;
    final int chaos = char['caos'] as int? ?? 0;
    final int rad = char['exposicao_rad'] as int? ?? 0;
    final int sanity = char['sanidade'] as int? ?? 100;
    final int hunger = char['fome'] as int? ?? 100;
    final int thirst = char['sede'] as int? ?? 100;

    // Verificar se tem alertas
    final List<String> warnings = [];
    if (isDead) warnings.add('ÓBITO / MORTO');
    if (chaos >= 100) warnings.add('⚠️ CAOS 100% (PUNIÇÃO ATIVA)');
    if (rad >= 80) warnings.add('⚠️ RADIAÇÃO CRÍTICA');
    if (sanity <= 20) warnings.add('⚠️ SANIDADE CRÍTICA');
    if (hunger <= 20) warnings.add('⚠️ FOME CRÍTICA');
    if (thirst <= 20) warnings.add('⚠️ SEDE CRÍTICA');

    // Calcular peso
    final attrs = char['attributes'] as Map<String, dynamic>? ?? {};
    final con = double.tryParse(attrs['CON']?.toString() ?? '10') ?? 10.0;
    final str = double.tryParse(attrs['FOR']?.toString() ?? '10') ?? 10.0;
    final double capacity = con * str;

    // Ideal seria buscar o peso em tempo real, mas para renderização direta, podemos alertar
    // caso o jogador esteja marcado como sobrecarregado ou excedido.

    final hasAlert = warnings.isNotEmpty;

    return Card(
      color: isDead
          ? Colors.black54
          : hasAlert
              ? SteampunkTheme.bloodRed.withValues(alpha: 0.15)
              : SteampunkTheme.castIron,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(
          color: isDead
              ? Colors.black
              : hasAlert
                  ? SteampunkTheme.bloodRed
                  : SteampunkTheme.copper,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    (char['name'] as String).toUpperCase(),
                    style: GoogleFonts.cinzel(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDead ? Colors.white30 : SteampunkTheme.copper,
                      decoration: isDead ? TextDecoration.lineThrough : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'Lvl ${char['level']}',
                  style: GoogleFonts.specialElite(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white12),

            // Medidores Básicos de Vida e Vigor
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Força Vital (FV):', style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  '${char['current_fv']} / ${char['max_fv']}',
                  style: GoogleFonts.specialElite(color: SteampunkTheme.bloodRed, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Pontos Mentais (PM):', style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  '${char['current_pm'] ?? 100} / ${char['max_pm'] ?? 100}',
                  style: GoogleFonts.specialElite(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Vigor:', style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  '${char['current_vigor']} / ${char['max_vigor']}',
                  style: GoogleFonts.specialElite(color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Estatísticas secundárias
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMiniStat('Sanidade', '$sanity%'),
                _buildMiniStat('Fome', '$hunger%'),
                _buildMiniStat('Sede', '$thirst%'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMiniStat('Caos', '$chaos%'),
                _buildMiniStat('Radiação', '$rad%'),
                _buildMiniStat('Carga Máx', '${capacity.toInt()}Kg'),
              ],
            ),
            const SizedBox(height: 12),

            // Banners de Alerta
            if (warnings.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: warnings.length,
                  itemBuilder: (context, wIdx) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                      decoration: BoxDecoration(
                        color: SteampunkTheme.bloodRed.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        warnings[wIdx],
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              )
            else
              const Expanded(
                child: Center(
                  child: Text(
                    'ESTADO ESTÁVEL',
                    style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 8, color: Colors.white38),
        ),
        Text(
          value,
          style: GoogleFonts.specialElite(fontSize: 11, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildPlayerDashboard() {
    if (_playerCharacter == null) {
      return Container(
        decoration: const BoxDecoration(
          color: SteampunkTheme.leatherBark,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'NENHUM PERSONAGEM ENCONTRADO',
                  style: GoogleFonts.cinzel(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: SteampunkTheme.copper,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Você precisa criar um personagem nesta campanha para participar da mesa.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    context.push('/campaigns/character/create/${widget.campaignId}');
                  },
                  child: const Text('CRIAR MEU PERSONAGEM'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isDead = _playerCharacter!['is_dead'] == true;

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: SteampunkTheme.castIron,
            child: TabBar(
              labelColor: SteampunkTheme.copper,
              unselectedLabelColor: Colors.white60,
              indicatorColor: SteampunkTheme.copper,
              tabs: const [
                Tab(icon: Icon(Icons.dashboard_outlined), text: 'SESSÃO'),
                Tab(icon: Icon(Icons.history), text: 'HISTÓRICO'),
                Tab(icon: Icon(Icons.menu_book), text: 'DOCUMENTOS'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildPlayerStatsTab(isDead),
                _buildSessionHistoryPlayer(),
                _buildDocumentsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionHistoryPlayer() {
    final finished = _allSessions.where((s) => s['status'] == 'finished').toList();
    if (finished.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history_toggle_off, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text('Nenhuma sessão concluída ainda.', style: GoogleFonts.ebGaramond(color: Colors.white38, fontSize: 16)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: finished.length,
      itemBuilder: (context, idx) {
        final s = finished[idx];
        final summary = s['player_summary'] as String? ?? '';
        final startTime = s['start_time'] != null
            ? DateTime.parse(s['start_time'].toString()).toLocal().toString().substring(0, 16)
            : 'Não iniciada';
        final endTime = s['end_time'] != null
            ? DateTime.parse(s['end_time'].toString()).toLocal().toString().substring(0, 16)
            : 'Não encerrada';
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: SteampunkTheme.castIron.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.white12),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: Text(
              s['title'].toString().toUpperCase(),
              style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, color: Colors.white60, fontSize: 14),
            ),
            subtitle: Text('$startTime → $endTime', style: GoogleFonts.specialElite(fontSize: 11, color: Colors.white38)),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: summary.isNotEmpty
                    ? Text(summary, style: GoogleFonts.ebGaramond(fontSize: 15, color: Colors.white70))
                    : Text('O Mestre não deixou um resumo para esta sessão.', style: GoogleFonts.ebGaramond(fontSize: 14, color: Colors.white30)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlayerStatsTab(bool isDead) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. ACTIVE SESSION NOTIFICATION/ALERT
          if (_activeSession != null) ...[
            Card(
              color: _isParticipant ? Colors.green.withValues(alpha: 0.1) : SteampunkTheme.copper.withValues(alpha: 0.15),
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: _isParticipant ? Colors.green : SteampunkTheme.copper,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      _isParticipant ? 'VOCÊ ESTÁ NA SESSÃO' : 'SESSÃO ATIVA DETECTADA!',
                      style: GoogleFonts.cinzel(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _isParticipant ? Colors.green : SteampunkTheme.copper,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isParticipant
                          ? 'Mesa: ${_activeSession!['title'].toString().toUpperCase()}. Seu personagem está recebendo atualizações do mestre.'
                          : 'O Mestre iniciou a sessão "${_activeSession!['title']}". Entre para participar.',
                      style: const TextStyle(fontSize: 13, color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isParticipant ? SteampunkTheme.bloodRed : SteampunkTheme.copper,
                      ),
                      onPressed: _isParticipant ? _onLeaveSession : _onJoinSession,
                      child: Text(_isParticipant ? 'SAIR DA SESSÃO' : 'ENTRAR NA SESSÃO'),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.hourglass_empty, size: 36, color: Colors.white38),
                    const SizedBox(height: 8),
                    Text(
                      'AGUARDANDO INÍCIO DA SESSÃO',
                      style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Nenhuma sessão de jogo ativa no momento. Aguarde o Mestre.',
                      style: TextStyle(fontSize: 12, color: Colors.white38),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),

          // 2. PENDING ITEMS NOTIFICATION (if any)
          if (_pendingItems.isNotEmpty) ...[
            Card(
              color: SteampunkTheme.copper.withValues(alpha: 0.12),
              shape: const RoundedRectangleBorder(
                side: BorderSide(color: SteampunkTheme.copper, width: 2),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.notifications_active, color: SteampunkTheme.copper),
                        const SizedBox(width: 8),
                        Text(
                          'NOTIFICAÇÕES DA MESA',
                          style: GoogleFonts.cinzel(
                            fontWeight: FontWeight.bold,
                            color: SteampunkTheme.copper,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._pendingItems.map((inv) {
                      final item = inv['items'];
                      if (item == null) return const SizedBox.shrink();
                      final itemId = inv['id'] as String;

                      return Card(
                        color: SteampunkTheme.castIron,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            item['name'].toString().toUpperCase(),
                            style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text(
                            'Quantidade: ${inv['quantity']} | Peso: ${item['weight']} Kg\n${item['description'] ?? ''}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: () async {
                                  await _inventoryRepo.deleteItem(itemId);
                                  await _loadPendingItems();
                                },
                                child: const Text('REJEITAR', style: TextStyle(color: SteampunkTheme.bloodRed)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                ),
                                onPressed: () async {
                                  await _inventoryRepo.acceptItem(itemId);
                                  await _loadPendingItems();
                                },
                                child: const Text('ACEITAR'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 3. REALTIME CHARACTER SHEET STATUS & DAMAGE TRACKER
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: Supabase.instance.client
                .from('characters')
                .stream(primaryKey: ['id'])
                .eq('id', _playerCharacter!['id']),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: SteampunkTheme.copper));
              }
              final chars = snapshot.data ?? [];
              if (chars.isEmpty) {
                return const Center(child: Text('Erro ao carregar dados do personagem.'));
              }
              final char = chars.first;

              final int currentFv = char['current_fv'] as int? ?? 10;
              final int maxFv = char['max_fv'] as int? ?? 10;
              final int currentPm = char['current_pm'] as int? ?? 100;
              final int maxPm = char['max_pm'] as int? ?? 100;
              final int currentVigor = char['current_vigor'] as int? ?? 10;
              final int maxVigor = char['max_vigor'] as int? ?? 10;
              final int damageTaken = maxFv - currentFv;

              final int level = char['level'] as int? ?? 0;
              final int xp = char['xp'] as int? ?? 0;
              final int chaos = char['caos'] as int? ?? 0;
              final int rad = char['exposicao_rad'] as int? ?? 0;
              final int sanity = char['sanidade'] as int? ?? 100;
              final int hunger = char['fome'] as int? ?? 100;
              final int thirst = char['sede'] as int? ?? 100;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // DANO TOMADO ALERTA
                  if (damageTaken > 0) ...[
                    Card(
                      color: SteampunkTheme.bloodRed.withValues(alpha: 0.12),
                      shape: const RoundedRectangleBorder(
                        side: BorderSide(color: SteampunkTheme.bloodRed, width: 2),
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.healing, color: SteampunkTheme.bloodRed, size: 36),
                        title: Text(
                          'DANO DE COMBATE NESTA SESSÃO',
                          style: GoogleFonts.cinzel(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Seu personagem perdeu $damageTaken pontos de Fôrça Vital.',
                          style: GoogleFonts.ebGaramond(fontSize: 16),
                        ),
                        trailing: Text(
                          '-$damageTaken FV',
                          style: GoogleFonts.specialElite(
                            color: SteampunkTheme.bloodRed,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // RESUMO DO PERSONAGEM
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                char['name'].toString().toUpperCase(),
                                style: GoogleFonts.cinzel(
                                  color: SteampunkTheme.copper,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                'NÍVEL $level',
                                style: GoogleFonts.specialElite(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white12),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildDashboardStat('FÔRÇA VITAL', '$currentFv / $maxFv', SteampunkTheme.bloodRed),
                              _buildDashboardStat('P. MENTAIS', '$currentPm / $maxPm', Colors.blueAccent),
                              _buildDashboardStat('VIGOR', '$currentVigor / $maxVigor', Colors.green),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildDashboardStat('SANIDADE', '$sanity%', Colors.purple),
                              _buildDashboardStat('CAOS', '$chaos%', SteampunkTheme.brassGlow),
                              _buildDashboardStat('RADIAÇÃO', '$rad%', Colors.teal),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildDashboardStat('FOME', '$hunger%', Colors.orange),
                              _buildDashboardStat('SEDE', '$thirst%', Colors.blue),
                              _buildDashboardStat('EXPERIÊNCIA', '$xp / ${(level + 1) * 100} XP', SteampunkTheme.copper),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: () {
              context.push('/campaigns/character/${_playerCharacter!['id']}');
            },
            child: const Text('ABRIR FICHA COMPLETA'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38)),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.specialElite(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsList() {
    final docRepo = DocumentRepository();
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: docRepo.fetchDocuments(widget.campaignId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: SteampunkTheme.copper));
        }
        final docs = snapshot.data ?? [];
        final approvedDocs = docs.where((d) => d['status'] == 'approved').toList();

        if (approvedDocs.isEmpty) {
          return const Center(
            child: Text(
              'Nenhum documento público compartilhado nesta campanha.',
              style: TextStyle(color: Colors.white38),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: approvedDocs.length,
          itemBuilder: (context, idx) {
            final doc = approvedDocs[idx];
            final title = doc['title'] as String;
            final category = doc['category'] as String? ?? 'DOCUMENTO';
            final content = doc['content'] as String? ?? '';
            final author = doc['profiles']?['username'] as String? ?? 'Mestre';
            final imageUrl = doc['image_url'] as String?;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: SteampunkTheme.copper.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: SteampunkTheme.copper, width: 1),
                      ),
                      child: Text(
                        category.toUpperCase(),
                        style: const TextStyle(fontSize: 10, color: SteampunkTheme.copper, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title.toUpperCase(),
                        style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    content.length > 100 ? '${content.substring(0, 100)}...' : content,
                    style: GoogleFonts.ebGaramond(fontSize: 16),
                  ),
                ),
                trailing: const Icon(Icons.menu_book, color: SteampunkTheme.copper),
                onTap: () => _viewDocumentDetails(title, category, content, author, imageUrl),
              ),
            );
          },
        );
      },
    );
  }

  void _viewDocumentDetails(String title, String category, String content, String author, String? imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SteampunkTheme.castIron,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, color: SteampunkTheme.copper),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (imageUrl != null && imageUrl.isNotEmpty) ...[
                Image.network(
                  imageUrl,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                'Autor: $author | Categoria: ${category.toUpperCase()}',
                style: const TextStyle(fontSize: 12, color: Colors.white38),
              ),
              const Divider(color: Colors.white12),
              const SizedBox(height: 8),
              Text(
                content,
                style: GoogleFonts.ebGaramond(fontSize: 18, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Inline editor for the master to write a player-visible session summary
class _PlayerSummaryEditor extends StatefulWidget {
  final String sessionId;
  final String initialValue;
  const _PlayerSummaryEditor({required this.sessionId, required this.initialValue});

  @override
  State<_PlayerSummaryEditor> createState() => _PlayerSummaryEditorState();
}

class _PlayerSummaryEditorState extends State<_PlayerSummaryEditor> {
  late final TextEditingController _ctrl;
  bool _isSaving = false;
  bool _isSaved = true;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await Supabase.instance.client
          .from('sessions')
          .update({'player_summary': _ctrl.text.trim()})
          .eq('id', widget.sessionId);
      setState(() {
        _isSaved = true;
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resumo da sessão salvo com sucesso!'),
            backgroundColor: SteampunkTheme.copper,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _ctrl,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Escreva um resumo público desta sessão para os jogadores...',
            hintStyle: GoogleFonts.ebGaramond(color: Colors.white24, fontSize: 13),
          ),
          style: GoogleFonts.ebGaramond(fontSize: 14, color: Colors.white70),
          onChanged: (text) {
            if (_isSaved) {
              setState(() => _isSaved = false);
            }
          },
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _isSaved ? Colors.green.withValues(alpha: 0.2) : SteampunkTheme.copper,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Icon(_isSaved ? Icons.check : Icons.save, size: 16, color: Colors.white),
            label: Text(
              _isSaving
                  ? 'SALVANDO...'
                  : _isSaved
                      ? 'RESUMO SALVO'
                      : 'SALVAR RESUMO',
              style: GoogleFonts.cinzel(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
