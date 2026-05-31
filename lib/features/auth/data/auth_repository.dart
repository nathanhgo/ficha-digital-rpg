import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    required String role,
  }) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'username': username,
        'role': role,
      },
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select('id, username, role')
          .eq('id', userId)
          .maybeSingle();
      
      // Auto-heal/recreate profile if it exists in Auth but missing in public.profiles table (e.g. after db reset)
      if (response == null) {
        final user = _client.auth.currentUser;
        if (user != null && user.id == userId) {
          final username = user.userMetadata?['username'] as String? ?? 'Jogador_${userId.substring(0, 6)}';
          final role = user.userMetadata?['role'] as String? ?? 'player';
          
          debugPrint("Aviso: Perfil não encontrado para o usuário $userId. Criando automaticamente...");
          final insertResponse = await _client.from('profiles').insert({
            'id': userId,
            'username': username,
            'role': role,
          }).select('id, username, role').single();
          return insertResponse;
        }
      }
      return response;
    } catch (e) {
      debugPrint("Erro ao buscar/autocriar perfil: $e");
      return null;
    }
  }
}
