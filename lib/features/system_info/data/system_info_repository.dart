import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SystemInfoRepository {
  final _client = Supabase.instance.client;

  Stream<List<Map<String, dynamic>>> streamPosts() {
    return _client
        .from('system_posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  Future<bool> createPost(String authorId, String title, String content, {bool isPublic = true, List<String> allowedCharacterIds = const []}) async {
    try {
      await _client.from('system_posts').insert({
        'author_id': authorId,
        'title': title,
        'content': content,
        'is_public': isPublic,
        'allowed_character_ids': allowedCharacterIds,
      });
      return true;
    } catch (e) {
      debugPrint("Erro ao criar post do sistema: $e");
      return false;
    }
  }

  Future<bool> deletePost(String postId) async {
    try {
      await _client.from('system_posts').delete().eq('id', postId);
      return true;
    } catch (e) {
      debugPrint("Erro ao deletar post do sistema: $e");
      return false;
    }
  }

  Future<bool> updatePost(String postId, String title, String content, {bool isPublic = true, List<String> allowedCharacterIds = const []}) async {
    try {
      await _client.from('system_posts').update({
        'title': title,
        'content': content,
        'is_public': isPublic,
        'allowed_character_ids': allowedCharacterIds,
      }).eq('id', postId);
      return true;
    } catch (e) {
      debugPrint("Erro ao atualizar post do sistema: $e");
      return false;
    }
  }
}
