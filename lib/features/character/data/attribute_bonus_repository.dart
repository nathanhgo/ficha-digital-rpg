import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'attribute_bonus.dart';

/// Acesso aos bônus de atributo do personagem (tabela `character_attribute_bonuses`).
///
/// Mesmo padrão dos demais repositories do projeto: `Supabase.instance.client`,
/// try/catch com debugPrint e retornos tipados (lista vazia / null / false em erro).
class AttributeBonusRepository {
  static const String _table = 'character_attribute_bonuses';

  final SupabaseClient _client = Supabase.instance.client;

  /// Busca todos os bônus de um personagem, do mais antigo para o mais recente.
  Future<List<AttributeBonus>> fetchBonuses(String characterId) async {
    if (characterId.isEmpty) return [];
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('character_id', characterId)
          .order('created_at');
      return List<Map<String, dynamic>>.from(response)
          .map((m) => AttributeBonus.fromMap(m))
          .toList();
    } catch (e) {
      debugPrint("Erro ao buscar bônus de atributo: $e");
      return [];
    }
  }

  /// Cria um bônus e devolve a linha criada (com o `id` gerado pelo banco).
  /// Retorna `null` em caso de erro.
  Future<AttributeBonus?> addBonus({
    required String characterId,
    required String source,
    required String attribute,
    required int amount,
  }) async {
    if (characterId.isEmpty) return null;
    try {
      final response = await _client.from(_table).insert({
        'character_id': characterId,
        'source': source,
        'attribute': attribute,
        'amount': amount,
      }).select().single();
      return AttributeBonus.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      debugPrint("Erro ao adicionar bônus de atributo: $e");
      return null;
    }
  }

  /// Remove um bônus. Retorna `true` em caso de sucesso.
  Future<bool> deleteBonus(String bonusId) async {
    if (bonusId.isEmpty) return false;
    try {
      await _client.from(_table).delete().eq('id', bonusId);
      return true;
    } catch (e) {
      debugPrint("Erro ao remover bônus de atributo: $e");
      return false;
    }
  }

  /// Remove todos os bônus de um personagem. Retorna `true` em caso de sucesso.
  Future<bool> deleteBonusesForCharacter(String characterId) async {
    if (characterId.isEmpty) return false;
    try {
      await _client.from(_table).delete().eq('character_id', characterId);
      return true;
    } catch (e) {
      debugPrint("Erro ao remover bônus do personagem: $e");
      return false;
    }
  }
}
