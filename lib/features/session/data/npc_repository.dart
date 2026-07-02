import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class NpcRepository {
  final _client = Supabase.instance.client;

  Stream<List<Map<String, dynamic>>> streamNpcs(String campaignId) {
    return _client
        .from('npcs')
        .stream(primaryKey: ['id'])
        .eq('campaign_id', campaignId)
        .order('created_at');
  }

  Future<bool> createNpc({
    required String campaignId,
    required String name,
    required String description,
    required Map<String, dynamic> attributes,
    required List<Map<String, dynamic>> habilidades,
    required int maxFv,
    required int maxVigor,
    int ataque = 0,
    int defesa = 0,
    String? avatarUrl,
  }) async {
    try {
      await _client.from('npcs').insert({
        'campaign_id': campaignId,
        'name': name,
        'description': description,
        'attributes': attributes,
        'habilidades': habilidades,
        'max_fv': maxFv,
        'current_fv': maxFv,
        'max_vigor': maxVigor,
        'current_vigor': maxVigor,
        'ataque': ataque,
        'defesa': defesa,
        'avatar_url': avatarUrl,
      });
      return true;
    } catch (e) {
      debugPrint("Erro ao criar NPC: $e");
      return false;
    }
  }

  Future<bool> updateNpc(String npcId, Map<String, dynamic> updates) async {
    try {
      await _client.from('npcs').update(updates).eq('id', npcId);
      return true;
    } catch (e) {
      debugPrint("Erro ao atualizar NPC: $e");
      return false;
    }
  }

  Future<bool> deleteNpc(String npcId) async {
    try {
      await _client.from('npcs').delete().eq('id', npcId);
      return true;
    } catch (e) {
      debugPrint("Erro ao deletar NPC: $e");
      return false;
    }
  }
}
