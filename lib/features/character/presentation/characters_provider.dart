import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/character_repository.dart';

final userCharactersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final authState = ref.watch(authControllerProvider);
  final userId = authState.profile?['id'] as String? ?? '';
  if (userId.isEmpty) return const [];
  return CharacterRepository().fetchCharactersForUser(userId);
});
