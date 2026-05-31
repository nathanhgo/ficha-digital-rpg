import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InventoryRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // Busca o inventário completo do personagem com os dados do item
  Future<List<Map<String, dynamic>>> fetchInventory(String characterId) async {
    if (characterId.isEmpty) return [];
    try {
      final response = await _client
          .from('character_inventory')
          .select('*, items(*)')
          .eq('character_id', characterId)
          .order('created_at');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Erro ao buscar inventário: $e");
      return [];
    }
  }

  // Adiciona um item (cria no banco na tabela items e associa no character_inventory)
  Future<bool> addItem({
    required String characterId,
    required String name,
    required String description,
    required double weight,
    required int quantity,
    required bool accepted,
    String? campaignId,
  }) async {
    try {
      // 1. Inserir na tabela items
      final itemResponse = await _client.from('items').insert({
        'campaign_id': campaignId,
        'name': name,
        'description': description,
        'weight': weight,
        'is_template': false,
      }).select().single();

      final itemId = itemResponse['id'] as String;

      // 2. Inserir no character_inventory
      await _client.from('character_inventory').insert({
        'character_id': characterId,
        'item_id': itemId,
        'quantity': quantity,
        'accepted': accepted,
      });

      if (!accepted) {
        try {
          final charDoc = await _client.from('characters').select('owner_id, name').eq('id', characterId).single();
          final ownerId = charDoc['owner_id'] as String;
          final charName = charDoc['name'] as String;
          await _client.from('notifications').insert({
            'user_id': ownerId,
            'title': 'Novo Item Pendente!',
            'message': 'O Mestre enviou o item "$name" para $charName. Aceite ou rejeite na sua ficha/sessão.',
          });
        } catch (e) {
          debugPrint("Erro ao notificar item pendente: $e");
        }
      }

      return true;
    } catch (e) {
      debugPrint("Erro ao adicionar item ao inventário: $e");
      return false;
    }
  }

  Future<void> updateQuantity(String inventoryId, int newQuantity) async {
    try {
      await _client
          .from('character_inventory')
          .update({'quantity': newQuantity})
          .eq('id', inventoryId);
    } catch (e) {
      debugPrint("Erro ao atualizar quantidade do item: $e");
    }
  }

  Future<void> acceptItem(String inventoryId) async {
    try {
      await _client
          .from('character_inventory')
          .update({'accepted': true})
          .eq('id', inventoryId);
    } catch (e) {
      debugPrint("Erro ao aceitar item: $e");
    }
  }

  Future<void> deleteItem(String inventoryId) async {
    try {
      await _client.from('character_inventory').delete().eq('id', inventoryId);
    } catch (e) {
      debugPrint("Erro ao excluir item do inventário: $e");
    }
  }

  /// Busca itens template (catálogo) de uma campanha
  Future<List<Map<String, dynamic>>> fetchTemplateItems(String campaignId) async {
    if (campaignId.isEmpty) return [];
    try {
      final response = await _client
          .from('items')
          .select('*')
          .eq('campaign_id', campaignId)
          .eq('is_template', true)
          .order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Erro ao buscar itens template: $e");
      return [];
    }
  }

  /// Cria um item template no catálogo do Mestre
  Future<Map<String, dynamic>?> createTemplateItem({
    required String campaignId,
    required String name,
    required String description,
    required double weight,
    String? imageUrl,
  }) async {
    try {
      final response = await _client.from('items').insert({
        'campaign_id': campaignId,
        'name': name,
        'description': description,
        'weight': weight,
        'image_url': imageUrl,
        'is_template': true,
      }).select().single();
      return response;
    } catch (e) {
      debugPrint("Erro ao criar item template: $e");
      return null;
    }
  }

  /// Envia um item do catálogo para o inventário de um personagem (pendente)
  Future<bool> sendTemplateItemToCharacter({
    required String itemId,
    required String characterId,
    required int quantity,
  }) async {
    try {
      await _client.from('character_inventory').insert({
        'character_id': characterId,
        'item_id': itemId,
        'quantity': quantity,
        'accepted': false,
      });
      // Notifica o jogador
      final charDoc = await _client.from('characters').select('owner_id, name, items(name)').eq('id', characterId).single();
      final ownerId = charDoc['owner_id'] as String;
      final charName = charDoc['name'] as String;
      final itemName = (await _client.from('items').select('name').eq('id', itemId).single())['name'] as String;
      await _client.from('notifications').insert({
        'user_id': ownerId,
        'title': 'Novo Item Pendente!',
        'message': 'O Mestre enviou "$itemName" para $charName. Aceite ou rejeite na sua ficha.',
        'type': 'item_pending',
        'metadata': {'character_id': characterId, 'item_id': itemId},
      });
      return true;
    } catch (e) {
      debugPrint("Erro ao enviar item template: $e");
      return false;
    }
  }
}
