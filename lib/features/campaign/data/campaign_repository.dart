import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CampaignRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchCampaigns(String userId, String role) async {
    if (userId.isEmpty) return [];
    try {
      if (role == 'master') {
        final response = await _client
            .from('campaigns')
            .select('*, profiles!campaigns_master_id_fkey(username)')
            .eq('master_id', userId)
            .order('created_at', ascending: false);
        return List<Map<String, dynamic>>.from(response);
      } else {
        // Obter campanhas nas quais o jogador está inscrito
        final playerCampaigns = await _client
            .from('campaign_players')
            .select('campaign_id')
            .eq('player_id', userId);
        
        final List<String> campaignIds = List<String>.from(
          playerCampaigns.map((e) => e['campaign_id'] as String),
        );

        if (campaignIds.isEmpty) return [];

        final response = await _client
            .from('campaigns')
            .select('*, profiles!campaigns_master_id_fkey(username)')
            .inFilter('id', campaignIds)
            .order('created_at', ascending: false);
        return List<Map<String, dynamic>>.from(response);
      }
    } catch (e) {
      debugPrint("Erro ao buscar campanhas: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>?> createCampaign({
    required String name,
    required String description,
    String? mapUrl,
    required String masterId,
  }) async {
    try {
      final response = await _client.from('campaigns').insert({
        'name': name,
        'description': description,
        'map_url': mapUrl,
        'master_id': masterId,
      }).select().single();
      return response;
    } catch (e) {
      debugPrint("Erro ao criar campanha: $e");
      return null;
    }
  }

  Future<bool> joinCampaign({required String campaignId, required String playerId}) async {
    try {
      await _client.from('campaign_players').insert({
        'campaign_id': campaignId,
        'player_id': playerId,
      });
      return true;
    } catch (e) {
      debugPrint("Erro ao entrar na campanha: $e");
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchCampaignPlayers(String campaignId) async {
    try {
      final response = await _client
          .from('campaign_players')
          .select('player_id, profiles(id, username, role)')
          .eq('campaign_id', campaignId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Erro ao buscar jogadores da campanha: $e");
      return [];
    }
  }
}
