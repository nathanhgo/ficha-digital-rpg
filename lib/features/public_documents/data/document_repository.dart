import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DocumentRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchDocuments(String campaignId) async {
    if (campaignId.isEmpty) return [];
    try {
      final response = await _client
          .from('public_documents')
          .select('*, profiles(username)')
          .eq('campaign_id', campaignId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Erro ao buscar documentos públicos: $e");
      return [];
    }
  }

  Future<bool> createDocument({
    required String campaignId,
    required String authorId,
    required String title,
    required String content,
    required String category,
    String? imageUrl,
    required String initialStatus,
  }) async {
    try {
      await _client.from('public_documents').insert({
        'campaign_id': campaignId,
        'author_id': authorId,
        'title': title,
        'content': content,
        'category': category,
        'image_url': imageUrl,
        'status': initialStatus,
      });

      // Se for pendente, notifica o mestre. Se aprovado, notifica os jogadores.
      try {
        final camp = await _client.from('campaigns').select('master_id, name').eq('id', campaignId).single();
        final masterId = camp['master_id'] as String;
        
        if (initialStatus == 'pending') {
          await _client.from('notifications').insert({
            'user_id': masterId,
            'title': 'Documento para Aprovação',
            'message': 'Um novo documento "$title" foi enviado para moderação na campanha "${camp['name']}".',
          });
        } else if (initialStatus == 'approved') {
          final players = await _client.from('campaign_players').select('player_id').eq('campaign_id', campaignId);
          for (var p in players) {
            final pId = p['player_id'] as String;
            await _client.from('notifications').insert({
              'user_id': pId,
              'title': 'Novo Documento Público!',
              'message': 'Um novo documento de $category chamado "$title" está disponível na campanha "${camp['name']}".',
            });
          }
        }
      } catch (e) {
        debugPrint("Erro ao enviar notificações de documento: $e");
      }

      return true;
    } catch (e) {
      debugPrint("Erro ao criar documento público: $e");
      return false;
    }
  }

  Future<bool> updateDocumentStatus(
    String documentId,
    String status, {
    String? rejectionReason,
  }) async {
    try {
      await _client.from('public_documents').update({
        'status': status,
        'rejection_reason': rejectionReason,
      }).eq('id', documentId).select();

      // Notificar o autor e outros jogadores
      try {
        final doc = await _client.from('public_documents').select('author_id, title, campaign_id, category').eq('id', documentId).single();
        final authorId = doc['author_id'] as String;
        final title = doc['title'] as String;
        final campaignId = doc['campaign_id'] as String;
        final category = doc['category'] as String;

        if (status == 'approved') {
          // Notifica autor
          await _client.from('notifications').insert({
            'user_id': authorId,
            'title': 'Documento Aprovado!',
            'message': 'Seu documento "$title" foi aprovado e publicado!',
          });
          // Notifica outros jogadores
          final players = await _client.from('campaign_players').select('player_id').eq('campaign_id', campaignId);
          for (var p in players) {
            final pId = p['player_id'] as String;
            if (pId != authorId) {
              await _client.from('notifications').insert({
                'user_id': pId,
                'title': 'Novo Documento Público!',
                'message': 'Um novo documento de $category chamado "$title" está disponível.',
              });
            }
          }
        } else if (status == 'rejected') {
          await _client.from('notifications').insert({
            'user_id': authorId,
            'title': 'Documento Recusado',
            'message': 'Seu documento "$title" foi recusado pelo Mestre.${rejectionReason != null ? ' Motivo: $rejectionReason' : ''}',
          });
        }
      } catch (e) {
        debugPrint("Erro ao notificar status de documento: $e");
      }
      return true;
    } catch (e) {
      debugPrint("Erro ao atualizar status do documento: $e");
      return false;
    }
  }

  Future<bool> updateDocument({
    required String documentId,
    required String title,
    required String content,
    required String category,
    String? imageUrl,
  }) async {
    try {
      final updates = {
        'title': title,
        'content': content,
        'category': category,
      };
      if (imageUrl != null) {
        updates['image_url'] = imageUrl;
      }
      await _client.from('public_documents').update(updates).eq('id', documentId);
      return true;
    } catch (e) {
      debugPrint("Erro ao atualizar documento: $e");
      return false;
    }
  }
}
