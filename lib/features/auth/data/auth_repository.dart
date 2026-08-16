import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // Esquema customizado usado para deep links no app mobile (recuperação de
  // senha e retorno do login Google).
  static const String mobileScheme = 'despertarcaos';

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// No Web, usa a origem atual do navegador (funciona tanto em produção na
  /// Vercel quanto em `localhost` durante testes locais) em vez de uma URL
  /// fixa, evitando que o redirect do Supabase leve para o domínio de
  /// produção enquanto se testa localmente.
  String get _webOrigin => Uri.base.origin;

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> resetPasswordForEmail(String email) async {
    final redirectTo = kIsWeb ? '$_webOrigin/reset-password' : '$mobileScheme://reset-password';
    await _client.auth.resetPasswordForEmail(email, redirectTo: redirectTo);
  }

  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> signInWithGoogle() async {
    // Importante: usar um caminho (ex: "/login"), não a origem "pura" (sem
    // "/" no final), pois o padrão de wildcard configurado no Supabase
    // (ex: "http://localhost:*/**") só casa com URLs que tenham um "/" após
    // o host/porta. Sem isso, o Supabase não reconhece a URL na allow list e
    // usa a "Site URL" (produção) como fallback, mesmo testando localmente.
    final redirectTo = kIsWeb ? '$_webOrigin/login' : '$mobileScheme://login-callback';
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectTo,
      authScreenLaunchMode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
    );
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
