import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CharacterRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchCharactersForUser(String userId) async {
    if (userId.isEmpty) return [];
    try {
      final response = await _client
          .from('characters')
          .select('*, campaigns(name)')
          .eq('owner_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Erro ao buscar personagens do usuário: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchCharacterById(String characterId) async {
    try {
      final response = await _client.from('characters').select().eq('id', characterId).single();
      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint("Erro ao buscar personagem por ID: $e");
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchCharactersForCampaign(String campaignId) async {
    if (campaignId.isEmpty) return [];
    try {
      final response = await _client
          .from('characters')
          .select('*, profiles(username)')
          .eq('campaign_id', campaignId)
          .order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Erro ao buscar personagens da campanha: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>?> createCharacter({
    required String ownerId,
    required String name,
    required String race,
    required String charClass,
    String? subclass,
    required String profession,
    required int dvValue,
    required int campaignIdOrNull, // wait, campaignId is UUID in Postgres, so it must be a String?
    String? campaignId,
    required Map<String, int> attributes,
    required int maxFv,
    required int maxVigor,
    String? avatarUrl,
    int level = 1,
  }) async {
    try {
      final response = await _client.from('characters').insert({
        'owner_id': ownerId,
        'name': name,
        'race': race,
        'char_class': charClass,
        'subclass': subclass,
        'profession': profession,
        'dv_value': dvValue,
        'campaign_id': campaignId,
        'attributes': attributes,
        'current_fv': maxFv,
        'max_fv': maxFv,
        'current_vigor': maxVigor,
        'max_vigor': maxVigor,
        'current_pm': 100,
        'max_pm': 100,
        'efeitos': [],
        'avatar_url': avatarUrl,
        'sanidade': 100,
        'conciencia': 100,
        'fome': 100,
        'sede': 100,
        'sangue': 100,
        'caos': 0,
        'exposicao_rad': 0,
        'level': level,
        'xp': 0,
      }).select().single();
      return response;
    } catch (e) {
      debugPrint("Erro ao criar personagem: $e");
      return null;
    }
  }

  Future<void> updateVitals(String characterId, Map<String, dynamic> updates) async {
    try {
      await _client.from('characters').update(updates).eq('id', characterId);
    } catch (e) {
      debugPrint("Erro ao atualizar vitais: $e");
    }
  }

  Future<void> updateDiary(String characterId, String diaryText) async {
    try {
      await _client.from('characters').update({'diary': diaryText}).eq('id', characterId);
    } catch (e) {
      debugPrint("Erro ao atualizar diário: $e");
    }
  }

  Future<void> killCharacter(String characterId) async {
    try {
      await _client.from('characters').update({'is_dead': true}).eq('id', characterId);
    } catch (e) {
      debugPrint("Erro ao matar personagem: $e");
    }
  }

  Future<void> addXp(String characterId, int currentXp, int currentLevel, int xpToAdd) async {
    try {
      int newXp = currentXp + xpToAdd;
      int newLevel = currentLevel;

      // Progressão linear: Delta = (NívelAtual + 1) * 100
      // Nível 0 -> 1: precisa de 100 XP (Total 100)
      // Nível 1 -> 2: precisa de 200 XP (Total 300)
      // Nível 2 -> 3: precisa de 300 XP (Total 600)
      // Nível 3 -> 4: precisa de 400 XP (Total 1000)
      // etc.
      while (true) {
        int xpNeededForNextLevel = (newLevel + 1) * 100;
        if (newXp >= xpNeededForNextLevel) {
          newXp -= xpNeededForNextLevel;
          newLevel++;
        } else {
          break;
        }
      }

      await _client.from('characters').update({
        'xp': newXp,
        'level': newLevel,
      }).eq('id', characterId);

      try {
        final charDoc = await _client.from('characters').select('owner_id, name').eq('id', characterId).single();
        final ownerId = charDoc['owner_id'] as String;
        final charName = charDoc['name'] as String;
        await _client.from('notifications').insert({
          'user_id': ownerId,
          'title': 'XP Recebido!',
          'message': 'Seu personagem $charName recebeu $xpToAdd de XP! Nível atual: $newLevel.',
        });
      } catch (e) {
        debugPrint("Erro ao criar notificação de XP: $e");
      }
    } catch (e) {
      debugPrint("Erro ao adicionar XP: $e");
    }
  }

  Future<void> addMoney(String characterId, String currency, int amount) async {
    try {
      final charDoc = await _client.from('characters').select('drax, creditos, owner_id, name').eq('id', characterId).single();
      final currentDrax = charDoc['drax'] as int? ?? 0;
      final currentCreditos = charDoc['creditos'] as int? ?? 0;
      final ownerId = charDoc['owner_id'] as String;
      final charName = charDoc['name'] as String;

      int newDrax = currentDrax;
      int newCreditos = currentCreditos;

      if (currency == 'drax') {
        newDrax += amount;
      } else {
        newCreditos += amount;
      }

      await _client.from('characters').update({
        'drax': newDrax,
        'creditos': newCreditos,
      }).eq('id', characterId);

      try {
        final currencyName = currency == 'drax' ? 'Drax' : 'Créditos';
        await _client.from('notifications').insert({
          'user_id': ownerId,
          'title': 'Dinheiro Recebido!',
          'message': 'Seu personagem $charName recebeu $amount $currencyName do Mestre! Novo saldo: ${currency == 'drax' ? newDrax : newCreditos} $currencyName.',
        });
      } catch (e) {
        debugPrint("Erro ao notificar recebimento de dinheiro: $e");
      }
    } catch (e) {
      debugPrint("Erro ao adicionar dinheiro: $e");
    }
  }

  Future<void> updateCharacter(String characterId, Map<String, dynamic> data) async {
    try {
      await _client.from('characters').update(data).eq('id', characterId);
    } catch (e) {
      debugPrint("Erro ao atualizar personagem: $e");
    }
  }
}
