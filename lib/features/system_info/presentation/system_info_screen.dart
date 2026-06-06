import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/theme.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/system_info_repository.dart';
import 'system_post_editor_screen.dart';
import '../../character/presentation/characters_provider.dart';

class SystemInfoScreen extends ConsumerStatefulWidget {
  const SystemInfoScreen({super.key});

  @override
  ConsumerState<SystemInfoScreen> createState() => _SystemInfoScreenState();
}

class _SystemInfoScreenState extends ConsumerState<SystemInfoScreen> {
  final _repo = SystemInfoRepository();

  void _showCreatePostDialog(String authorId, [Map<String, dynamic>? post]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => SystemPostEditorScreen(
          authorId: authorId,
          existingPost: post,
        ),
      ),
    );
  }

  void _confirmDelete(String postId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SteampunkTheme.castIron,
        title: Text('EXCLUIR PUBLICAÇÃO?', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
        content: const Text('Esta ação não pode ser desfeita.'),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: SteampunkTheme.bloodRed, foregroundColor: Colors.white),
            onPressed: () async {
              final navigator = Navigator.of(ctx);
              await _repo.deletePost(postId);
              if (mounted) navigator.pop();
            },
            child: const Text('EXCLUIR'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.profile;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final userId = user['id'] as String;
    final role = user['role'] as String? ?? 'player';
    final isMaster = role == 'master';
    
    // Obter personagens do usuário para checar permissão em posts privados
    final userCharsAsync = ref.watch(userCharactersProvider);
    final userCharacters = userCharsAsync.valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/campaigns');
            }
          },
        ),
        title: Text('SISTEMA & LORE', style: GoogleFonts.cinzel(fontWeight: FontWeight.bold)),
      ),
      body: Container(
        color: SteampunkTheme.leatherBark,
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _repo.streamPosts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: SteampunkTheme.copper));
            }

            final allPosts = snapshot.data ?? [];
            final posts = allPosts.where((post) {
              if (isMaster) return true; // Master vê tudo
              final isPublic = post['is_public'] as bool? ?? true;
              if (isPublic) return true;
              
              // Se privado, checa se algum personagem do usuário está na lista
              final allowed = post['allowed_character_ids'] as List<dynamic>? ?? [];
              for (var char in userCharacters) {
                if (allowed.contains(char['id']) || allowed.contains(char['name'])) {
                  return true;
                }
              }
              return false;
            }).toList();

            if (posts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.menu_book, size: 64, color: Colors.white24),
                    const SizedBox(height: 16),
                    Text(
                      'O ACERVO ESTÁ VAZIO',
                      style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white30),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nenhuma regra ou lore foi publicada ainda.',
                      style: GoogleFonts.ebGaramond(fontSize: 14, color: Colors.white30),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: posts.length,
              itemBuilder: (context, idx) {
                final post = posts[idx];
                final dateStr = post['created_at'] != null
                    ? DateTime.parse(post['created_at'].toString()).toLocal().toString().substring(0, 16)
                    : '';

                return Card(
                  color: SteampunkTheme.castIron,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: SteampunkTheme.brassGlow.withValues(alpha: 0.5), width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                (post['title'] as String? ?? '').toUpperCase(),
                                style: GoogleFonts.cinzel(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: SteampunkTheme.copper,
                                ),
                              ),
                            ),
                            if (isMaster)
                              Row(
                                children: [
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.edit, color: SteampunkTheme.copper, size: 20),
                                    onPressed: () => _showCreatePostDialog(userId, post),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.delete, color: SteampunkTheme.bloodRed, size: 20),
                                    onPressed: () => _confirmDelete(post['id']),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(dateStr, style: GoogleFonts.specialElite(fontSize: 12, color: Colors.white38)),
                        const SizedBox(height: 16),
                        MarkdownBody(
                          data: post['content'] as String? ?? '',
                          onTapLink: (text, href, title) {
                            if (href != null) {
                              launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);
                            }
                          },
                          styleSheet: MarkdownStyleSheet(
                            p: GoogleFonts.ebGaramond(fontSize: 16, color: Colors.white70),
                            h1: GoogleFonts.cinzel(fontSize: 22, color: SteampunkTheme.copper, fontWeight: FontWeight.bold),
                            h2: GoogleFonts.cinzel(fontSize: 20, color: SteampunkTheme.copper),
                            h3: GoogleFonts.cinzel(fontSize: 18, color: SteampunkTheme.brassGlow),
                            listBullet: const TextStyle(color: SteampunkTheme.copper),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: isMaster
          ? FloatingActionButton(
              backgroundColor: SteampunkTheme.copper,
              foregroundColor: SteampunkTheme.castIron,
              onPressed: () => _showCreatePostDialog(userId),
              child: const Icon(Icons.edit_document),
            )
          : null,
    );
  }
}
