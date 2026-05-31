import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/theme.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/system_info_repository.dart';

class SystemInfoScreen extends ConsumerStatefulWidget {
  const SystemInfoScreen({super.key});

  @override
  ConsumerState<SystemInfoScreen> createState() => _SystemInfoScreenState();
}

class _SystemInfoScreenState extends ConsumerState<SystemInfoScreen> {
  final _repo = SystemInfoRepository();

  void _showCreatePostDialog(String authorId) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SteampunkTheme.castIron,
        title: Text('NOVA PUBLICAÇÃO', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (v) => v == null || v.isEmpty ? 'Insira um título' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: contentCtrl,
                decoration: const InputDecoration(labelText: 'Conteúdo'),
                maxLines: 6,
                validator: (v) => v == null || v.isEmpty ? 'Insira o conteúdo' : null,
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final navigator = Navigator.of(ctx);
                final success = await _repo.createPost(authorId, titleCtrl.text.trim(), contentCtrl.text.trim());
                if (success && mounted) {
                  navigator.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Publicação criada com sucesso!'), backgroundColor: Colors.green),
                  );
                }
              }
            },
            child: const Text('PUBLICAR'),
          ),
        ],
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

            final posts = snapshot.data ?? [];

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
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.delete, color: SteampunkTheme.bloodRed, size: 20),
                                onPressed: () => _confirmDelete(post['id']),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(dateStr, style: GoogleFonts.specialElite(fontSize: 12, color: Colors.white38)),
                        const SizedBox(height: 16),
                        Text(
                          post['content'] as String? ?? '',
                          style: GoogleFonts.ebGaramond(fontSize: 16, color: Colors.white70),
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
