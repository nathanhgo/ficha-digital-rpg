/// Bônus de atributo do personagem.
///
/// Representa um modificador EXTERNO ao valor base do atributo (raça,
/// equipamento, maldição, etc.). O valor final exibido na ficha é:
///
///   valor final = valor base (characters.attributes) + soma dos bônus
///
/// Persistido na tabela `character_attribute_bonuses` do Supabase.
class AttributeBonus {
  final String id;
  final String characterId;

  /// Fonte do bônus, texto livre curto. Ex.: 'Raça: Elfo', 'Equipamento: Anel'.
  final String source;

  /// Sigla do atributo afetado. Ex.: 'CON', 'FOR', 'DES'.
  final String attribute;

  /// Quantidade somada ao atributo base. Pode ser negativa (penalidade).
  final int amount;

  const AttributeBonus({
    required this.id,
    required this.characterId,
    required this.source,
    required this.attribute,
    required this.amount,
  });

  factory AttributeBonus.fromMap(Map<String, dynamic> map) {
    return AttributeBonus(
      id: map['id'] as String? ?? '',
      characterId: map['character_id'] as String? ?? '',
      source: map['source'] as String? ?? '',
      attribute: map['attribute'] as String? ?? '',
      amount: (map['amount'] as num?)?.toInt() ?? 0,
    );
  }

  /// Payload de escrita (o `id` e o `created_at` ficam por conta do banco).
  Map<String, dynamic> toMap() {
    return {
      'character_id': characterId,
      'source': source,
      'attribute': attribute,
      'amount': amount,
    };
  }

  AttributeBonus copyWith({
    String? source,
    String? attribute,
    int? amount,
  }) {
    return AttributeBonus(
      id: id,
      characterId: characterId,
      source: source ?? this.source,
      attribute: attribute ?? this.attribute,
      amount: amount ?? this.amount,
    );
  }

  /// Formatação amigável do valor: sempre com sinal. Ex.: '+2', '-1'.
  String get amountLabel => amount >= 0 ? '+$amount' : '$amount';
}
