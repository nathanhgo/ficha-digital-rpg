import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:despertar_caos_app/main.dart';
import 'package:despertar_caos_app/features/auth/data/auth_repository.dart';
import 'package:despertar_caos_app/features/auth/presentation/auth_controller.dart';
import 'package:despertar_caos_app/features/auth/presentation/login_screen.dart';

class FakeAuthRepository implements AuthRepository {
  @override
  User? get currentUser => null;

  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();

  @override
  Future<void> signIn({required String email, required String password}) async {}

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    required String role,
  }) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<Map<String, dynamic>?> fetchProfile(String userId) async => null;
}

void main() {
  testWidgets('App smoke test - verifies login screen loads', (WidgetTester tester) async {
    // Build our app and trigger a frame, overriding repository to bypass Supabase init.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify that our login button text is displayed.
    expect(find.text('ENTRAR'), findsOneWidget);
  });
}
