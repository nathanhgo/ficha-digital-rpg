import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SessionRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchSessions(String campaignId) async {
    if (campaignId.isEmpty) return [];
    try {
      final response = await _client
          .from('sessions')
          .select('*')
          .eq('campaign_id', campaignId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Erro ao buscar sessões: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>?> createSession({
    required String campaignId,
    required String title,
  }) async {
    try {
      final response = await _client.from('sessions').insert({
        'campaign_id': campaignId,
        'title': title,
        'status': 'scheduled',
      }).select().single();

      final sessionId = response['id'] as String;

      try {
        final players = await _client.from('campaign_players').select('player_id').eq('campaign_id', campaignId);
        for (var p in players) {
          final pId = p['player_id'] as String;
          await _client.from('notifications').insert({
            'user_id': pId,
            'title': 'Convite de Sessão!',
            'message': 'O Mestre agendou a sessão "$title". Confirme sua participação e escolha seu personagem.',
            'type': 'session_invite',
            'metadata': {'session_id': sessionId, 'campaign_id': campaignId, 'session_title': title},
          });
        }
      } catch (e) {
        debugPrint("Erro ao notificar nova sessão: $e");
      }

      return response;
    } catch (e) {
      debugPrint("Erro ao criar sessão: $e");
      return null;
    }
  }

  Future<void> startSession(String sessionId) async {
    try {
      await _client.from('sessions').update({
        'status': 'active',
        'start_time': DateTime.now().toIso8601String(),
      }).eq('id', sessionId);

      try {
        final sess = await _client.from('sessions').select('campaign_id, title').eq('id', sessionId).single();
        final campaignId = sess['campaign_id'] as String;
        final title = sess['title'] as String;
        final players = await _client.from('campaign_players').select('player_id').eq('campaign_id', campaignId);
        for (var p in players) {
          final pId = p['player_id'] as String;
          await _client.from('notifications').insert({
            'user_id': pId,
            'title': 'Sessão Iniciada!',
            'message': 'A sessão "$title" está ativa! Entre no monitor de sessão para participar.',
          });
        }
      } catch (e) {
        debugPrint("Erro ao notificar sessão iniciada: $e");
      }
    } catch (e) {
      debugPrint("Erro ao iniciar sessão: $e");
    }
  }

  Future<void> endSession(String sessionId) async {
    try {
      await _client.from('sessions').update({
        'status': 'finished',
        'end_time': DateTime.now().toIso8601String(),
      }).eq('id', sessionId);
    } catch (e) {
      debugPrint("Erro ao finalizar sessão: $e");
    }
  }

  Future<bool> joinSession(String sessionId, String characterId) async {
    try {
      await _client.from('session_participants').insert({
        'session_id': sessionId,
        'character_id': characterId,
      });
      return true;
    } catch (e) {
      debugPrint("Erro ao entrar na sessão: $e");
      return false;
    }
  }

  Future<void> leaveSession(String sessionId, String characterId) async {
    try {
      await _client
          .from('session_participants')
          .delete()
          .eq('session_id', sessionId)
          .eq('character_id', characterId);
    } catch (e) {
      debugPrint("Erro ao sair da sessão: $e");
    }
  }

  // Monitor em Tempo Real dos Personagens da Campanha usando Stream
  Stream<List<Map<String, dynamic>>> streamCharacters(String campaignId) {
    if (campaignId.isEmpty) return Stream.value([]);
    return _client
        .from('characters')
        .stream(primaryKey: ['id'])
        .eq('campaign_id', campaignId)
        .order('name');
  }

  // Monitor em Tempo Real da Presença na Sessão
  Stream<List<Map<String, dynamic>>> streamParticipants(String sessionId) {
    return _client
        .from('session_participants')
        .stream(primaryKey: ['session_id', 'character_id'])
        .eq('session_id', sessionId);
  }
}
