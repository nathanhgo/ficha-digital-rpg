import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/campaign_repository.dart';

class CampaignsState {
  final List<Map<String, dynamic>> campaigns;
  final bool isLoading;
  final String? error;

  CampaignsState({
    this.campaigns = const [],
    this.isLoading = false,
    this.error,
  });

  CampaignsState copyWith({
    List<Map<String, dynamic>>? campaigns,
    bool? isLoading,
    String? error,
  }) {
    return CampaignsState(
      campaigns: campaigns ?? this.campaigns,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CampaignsController extends StateNotifier<CampaignsState> {
  final CampaignRepository _repository;
  final String _userId;
  final String _role;

  CampaignsController(this._repository, this._userId, this._role) : super(CampaignsState()) {
    loadCampaigns();
  }

  Future<void> loadCampaigns() async {
    state = state.copyWith(isLoading: true);
    try {
      final list = await _repository.fetchCampaigns(_userId, _role);
      state = CampaignsState(campaigns: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createCampaign(String name, String description, String? mapUrl) async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await _repository.createCampaign(
        name: name,
        description: description,
        mapUrl: mapUrl,
        masterId: _userId,
      );
      if (res != null) {
        await loadCampaigns();
        return true;
      }
      state = state.copyWith(isLoading: false, error: 'Erro ao salvar campanha');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> joinCampaign(String campaignId) async {
    state = state.copyWith(isLoading: true);
    try {
      final success = await _repository.joinCampaign(campaignId: campaignId, playerId: _userId);
      if (success) {
        await loadCampaigns();
        return true;
      }
      state = state.copyWith(isLoading: false, error: 'Não foi possível entrar na campanha');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

// Providers
final campaignRepositoryProvider = Provider<CampaignRepository>((ref) {
  return CampaignRepository();
});

final campaignsControllerProvider = StateNotifierProvider<CampaignsController, CampaignsState>((ref) {
  final repo = ref.watch(campaignRepositoryProvider);
  final authState = ref.watch(authControllerProvider);
  final userId = authState.profile?['id'] ?? '';
  final role = authState.profile?['role'] ?? 'player';
  return CampaignsController(repo, userId, role);
});
