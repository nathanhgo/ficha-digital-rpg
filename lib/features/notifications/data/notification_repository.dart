import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchNotifications(String userId) async {
    if (userId.isEmpty) return [];
    try {
      final response = await _client
          .from('notifications')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Erro ao buscar notificações: $e");
      return [];
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);
    } catch (e) {
      debugPrint("Erro ao marcar notificação como lida: $e");
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _client
          .from('notifications')
          .delete()
          .eq('id', id);
    } catch (e) {
      debugPrint("Erro ao deletar notificação: $e");
    }
  }

  Future<bool> createNotification({
    required String userId,
    required String title,
    required String message,
  }) async {
    try {
      await _client.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
      });
      return true;
    } catch (e) {
      debugPrint("Erro ao criar notificação: $e");
      return false;
    }
  }

  Stream<List<Map<String, dynamic>>> streamNotifications(String userId) {
    if (userId.isEmpty) return Stream.value([]);
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }
}
