import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';

class AuthStateData {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? profile;
  final bool isAuthenticated;

  AuthStateData({
    this.isLoading = false,
    this.error,
    this.profile,
    this.isAuthenticated = false,
  });

  AuthStateData copyWith({
    bool? isLoading,
    String? error,
    Map<String, dynamic>? profile,
    bool? isAuthenticated,
  }) {
    return AuthStateData(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      profile: profile ?? this.profile,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthController extends StateNotifier<AuthStateData> {
  final AuthRepository _repository;
  StreamSubscription? _authSubscription;

  AuthController(this._repository) : super(AuthStateData(isLoading: true)) {
    _init();
  }

  void _init() async {
    // Escutar mudanças de estado do Supabase
    _authSubscription = _repository.authStateChanges.listen((event) async {
      final user = event.session?.user;
      if (user != null) {
        final profile = await _repository.fetchProfile(user.id);
        state = AuthStateData(
          isAuthenticated: true,
          profile: profile,
          isLoading: false,
        );
      } else {
        state = AuthStateData(isAuthenticated: false, isLoading: false);
      }
    });

    // Estado inicial
    final user = _repository.currentUser;
    if (user != null) {
      final profile = await _repository.fetchProfile(user.id);
      state = AuthStateData(
        isAuthenticated: true,
        profile: profile,
        isLoading: false,
      );
    } else {
      state = AuthStateData(isAuthenticated: false, isLoading: false);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.signIn(email: email, password: password);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> register(String email, String password, String username, String role) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.signUp(
        email: email,
        password: password,
        username: username,
        role: role,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _repository.signOut();
    state = AuthStateData(isAuthenticated: false, isLoading: false);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

// Providers do Riverpod
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthStateData>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthController(repo);
});
