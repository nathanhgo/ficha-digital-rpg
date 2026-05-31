import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/notification_repository.dart';
import '../../character/data/character_repository.dart';
import '../../session/data/session_repository.dart';
import '../../../core/theme/theme.dart';

class NotificationsTab extends ConsumerStatefulWidget {
  final String userId;
  const NotificationsTab({super.key, required this.userId});

  @override
  ConsumerState<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends ConsumerState<NotificationsTab> {
  final _notiRepo = NotificationRepository();

  @override
  void initState() {
    super.initState();
    if (widget.userId.isNotEmpty) {
      _notiRepo.markAllAsRead(widget.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userId.isEmpty) {
      return const Center(child: Text("Usuário não autenticado."));
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _notiRepo.streamNotifications(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: SteampunkTheme.copper));
        }

        final notifications = snapshot.data ?? [];

        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.notifications_none, size: 64, color: Colors.white24),
                const SizedBox(height: 16),
                Text(
                  'TUDO LIMPO POR AQUI',
                  style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white30),
                ),
                const SizedBox(height: 8),
                Text(
                  'Você não tem novas notificações.',
                  style: GoogleFonts.ebGaramond(fontSize: 14, color: Colors.white30),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          itemBuilder: (context, idx) {
            final noti = notifications[idx];
            final id = noti['id'] as String;
            final isRead = noti['is_read'] == true;
            final type = noti['type'] ?? 'general';
            final title = noti['title'] ?? 'Notificação';
            final message = noti['message'] ?? '';
            final metadata = noti['metadata'] as Map? ?? {};
            final dateStr = noti['created_at'] != null
                ? DateTime.parse(noti['created_at'].toString()).toLocal().toString().substring(0, 16)
                : '';

            if (type == 'session_invite') {
              return _SessionInviteCard(
                notificationId: id,
                sessionId: metadata['session_id'] as String? ?? '',
                campaignId: metadata['campaign_id'] as String? ?? '',
                sessionTitle: metadata['session_title'] as String? ?? title,
                message: message,
                dateStr: dateStr,
                isRead: isRead,
                userId: widget.userId,
                onAction: () => _notiRepo.markAsRead(id),
              );
            }

            return _GenericNotificationCard(
              id: id,
              title: title,
              message: message,
              dateStr: dateStr,
              isRead: isRead,
              notiRepo: _notiRepo,
            );
          },
        );
      },
    );
  }
}

// ── Generic notification card ──────────────────────────────────────────────

class _GenericNotificationCard extends StatelessWidget {
  final String id, title, message, dateStr;
  final bool isRead;
  final NotificationRepository notiRepo;

  const _GenericNotificationCard({
    required this.id,
    required this.title,
    required this.message,
    required this.dateStr,
    required this.isRead,
    required this.notiRepo,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isRead ? SteampunkTheme.castIron.withValues(alpha: 0.7) : SteampunkTheme.castIron,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isRead ? Colors.transparent : SteampunkTheme.copper.withValues(alpha: 0.5),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isRead ? Icons.drafts : Icons.mark_email_unread,
              color: isRead ? Colors.white38 : SteampunkTheme.copper,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title.toUpperCase(),
                          style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, color: isRead ? Colors.white60 : SteampunkTheme.copper, fontSize: 14),
                        ),
                      ),
                      if (dateStr.isNotEmpty)
                        Text(dateStr, style: GoogleFonts.specialElite(fontSize: 11, color: Colors.white38)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(message, style: GoogleFonts.ebGaramond(fontSize: 15, color: isRead ? Colors.white38 : Colors.white70)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.delete_outline, size: 20, color: SteampunkTheme.bloodRed),
                        tooltip: 'Excluir',
                        onPressed: () => notiRepo.deleteNotification(id),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Session invite card with character selection ──────────────────────────

class _SessionInviteCard extends StatefulWidget {
  final String notificationId, sessionId, campaignId, sessionTitle, message, dateStr, userId;
  final bool isRead;
  final VoidCallback onAction;

  const _SessionInviteCard({
    required this.notificationId,
    required this.sessionId,
    required this.campaignId,
    required this.sessionTitle,
    required this.message,
    required this.dateStr,
    required this.isRead,
    required this.userId,
    required this.onAction,
  });

  @override
  State<_SessionInviteCard> createState() => _SessionInviteCardState();
}

class _SessionInviteCardState extends State<_SessionInviteCard> {
  final _charRepo = CharacterRepository();
  final _sessionRepo = SessionRepository();
  final _notiRepo = NotificationRepository();
  bool _loading = false;
  bool _responded = false;

  @override
  void initState() {
    super.initState();
    _responded = widget.isRead;
  }

  void _onAccept() async {
    // Load player's characters in this campaign
    final chars = await _charRepo.fetchCharactersForUser(widget.userId);
    final campaignChars = chars.where((c) => c['campaign_id'] == widget.campaignId).toList();

    if (!mounted) return;

    if (campaignChars.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você não tem personagem nessa campanha. Crie um primeiro!'),
          backgroundColor: SteampunkTheme.bloodRed,
        ),
      );
      return;
    }

    Map<String, dynamic>? selectedChar = campaignChars.length == 1 ? campaignChars.first : null;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setDialogState) => AlertDialog(
          backgroundColor: SteampunkTheme.castIron,
          title: Text('CONFIRMAR PARTICIPAÇÃO', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sessão: ${widget.sessionTitle}',
                style: GoogleFonts.cinzel(color: SteampunkTheme.copper, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text('Selecione o personagem que vai participar:', style: GoogleFonts.ebGaramond(color: Colors.white70)),
              const SizedBox(height: 12),
               DropdownButtonFormField<Map<String, dynamic>>(
                initialValue: selectedChar,
                decoration: const InputDecoration(labelText: 'Personagem'),
                items: campaignChars.map((c) => DropdownMenuItem<Map<String, dynamic>>(
                  value: c,
                  child: Text(c['name'] as String, style: GoogleFonts.ebGaramond()),
                )).toList(),
                onChanged: (v) => setDialogState(() => selectedChar = v),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCELAR', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: selectedChar == null ? null : () async {
                final navigator = Navigator.of(ctx);
                setState(() => _loading = true);
                final charId = selectedChar!['id'] as String;
                final joined = await _sessionRepo.joinSession(widget.sessionId, charId);
                if (joined) {
                  await _notiRepo.markAsRead(widget.notificationId);
                  widget.onAction();
                  setState(() {
                    _loading = false;
                    _responded = true;
                  });
                }
                if (mounted) navigator.pop();
              },
              child: const Text('CONFIRMAR'),
            ),
          ],
        ),
      ),
    );
  }

  void _onDecline() async {
    setState(() => _loading = true);
    await _notiRepo.markAsRead(widget.notificationId);
    widget.onAction();
    if (mounted) setState(() { _loading = false; _responded = true; });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: SteampunkTheme.castIron,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: SteampunkTheme.brassGlow.withValues(alpha: 0.7), width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.campaign, color: SteampunkTheme.brassGlow, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CONVITE DE SESSÃO',
                        style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, color: SteampunkTheme.brassGlow, fontSize: 14),
                      ),
                      Text(widget.sessionTitle, style: GoogleFonts.cinzel(color: SteampunkTheme.copper, fontSize: 13)),
                    ],
                  ),
                ),
                Text(widget.dateStr, style: GoogleFonts.specialElite(fontSize: 11, color: Colors.white38)),
              ],
            ),
            const SizedBox(height: 8),
            Text(widget.message, style: GoogleFonts.ebGaramond(fontSize: 14, color: Colors.white70)),
            const SizedBox(height: 16),
            if (_responded)
              Text(
                'Resposta registrada.',
                style: GoogleFonts.cinzel(color: Colors.green, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              )
            else if (_loading)
              const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: SteampunkTheme.copper, strokeWidth: 2)))
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _onDecline,
                      icon: const Icon(Icons.close, size: 16, color: SteampunkTheme.bloodRed),
                      label: Text('RECUSAR', style: GoogleFonts.cinzel(color: SteampunkTheme.bloodRed, fontSize: 12)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: SteampunkTheme.bloodRed)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _onAccept,
                      icon: const Icon(Icons.check, size: 16),
                      label: Text('ACEITAR', style: GoogleFonts.cinzel(fontSize: 12)),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
