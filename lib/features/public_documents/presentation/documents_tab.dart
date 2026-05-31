import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:file_picker/file_picker.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/document_repository.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/storage_helper.dart';
import 'package:url_launcher/url_launcher.dart';

import 'public_document_editor_screen.dart';

class DocumentsTab extends ConsumerStatefulWidget {
  final String campaignId;
  const DocumentsTab({super.key, required this.campaignId});

  @override
  ConsumerState<DocumentsTab> createState() => _DocumentsTabState();
}

class _DocumentsTabState extends ConsumerState<DocumentsTab> {
  final _docRepo = DocumentRepository();
  List<Map<String, dynamic>> _documents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    final docs = await _docRepo.fetchDocuments(widget.campaignId);
    setState(() {
      _documents = docs;
      _isLoading = false;
    });
  }

  void _onCreateDocument() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => PublicDocumentEditorScreen(campaignId: widget.campaignId),
      ),
    );
    if (result == true) {
      _loadDocuments();
    }
  }

  void _onEditDocument(Map<String, dynamic> doc) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => PublicDocumentEditorScreen(
          campaignId: widget.campaignId,
          existingDoc: doc,
        ),
      ),
    );
    if (result == true) {
      _loadDocuments();
    }
  }

  void _onModerate(String docId, String status) async {
    final success = await _docRepo.updateDocumentStatus(docId, status);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Status atualizado com sucesso!' : 'Erro ao atualizar status.'),
          backgroundColor: success ? SteampunkTheme.copper : SteampunkTheme.bloodRed,
        ),
      );
    }
    if (success) {
      await _loadDocuments();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final role = authState.profile?['role'] ?? 'player';

    // Dividir documentos em Pendentes (moderador) e Aprovados
    final pendingDocs = _documents.where((d) => d['status'] == 'pending').toList();
    final approvedDocs = _documents.where((d) => d['status'] == 'approved').toList();

    return Container(
        decoration: const BoxDecoration(
          color: SteampunkTheme.leatherBark,
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: SteampunkTheme.copper))
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Seção de Moderação para o Mestre
                    if (role == 'master' && pendingDocs.isNotEmpty) ...[
                      Text(
                        'DOCUMENTOS AGUARDANDO APROVAÇÃO',
                        style: GoogleFonts.cinzel(
                          color: SteampunkTheme.bloodRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: pendingDocs.length,
                          itemBuilder: (context, idx) {
                            final doc = pendingDocs[idx];
                            final author = doc['profiles']?['username'] ?? 'Jogador';
                            return Card(
                              color: SteampunkTheme.castIron,
                              margin: const EdgeInsets.only(right: 12),
                              child: Container(
                                width: 280,
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (doc['title'] as String).toUpperCase(),
                                      style: GoogleFonts.cinzel(
                                        fontWeight: FontWeight.bold,
                                        color: SteampunkTheme.copper,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Enviado por: $author',
                                      style: const TextStyle(fontSize: 10, color: Colors.white38),
                                    ),
                                    const Spacer(),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () => _onModerate(doc['id'] as String, 'rejected'),
                                          child: const Text('RECUSAR', style: TextStyle(color: SteampunkTheme.bloodRed, fontSize: 11)),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => _onModerate(doc['id'] as String, 'approved'),
                                          child: const Text('APROVAR', style: TextStyle(fontSize: 11)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Mural de Documentos Aprovados
                    Text(
                      'NOTÍCIAS & RELATOS APROVADOS',
                      style: GoogleFonts.cinzel(
                        color: SteampunkTheme.copper,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    Expanded(
                      child: approvedDocs.isEmpty
                          ? Center(
                              child: Text(
                                'Nenhum relato ou documento compartilhado ainda.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white38),
                              ),
                            )
                          : ListView.builder(
                              itemCount: approvedDocs.length,
                              itemBuilder: (context, idx) {
                                final doc = approvedDocs[idx];
                                final author = doc['profiles']?['username'] ?? 'Desconhecido';
                                final cat = doc['category'] ?? 'outros';
                                final isAuthor = doc['author_id'] == authState.profile?['id'];
                                final canEdit = role == 'master' || isAuthor;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: ExpansionTile(
                                    title: Text(
                                      (doc['title'] as String).toUpperCase(),
                                      style: GoogleFonts.cinzel(
                                        fontWeight: FontWeight.bold,
                                        color: SteampunkTheme.copper,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Categoria: ${cat.toString().toUpperCase()} | Autor: $author',
                                      style: const TextStyle(fontSize: 11, color: Colors.white38),
                                    ),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            if (doc['image_url'] != null && doc['image_url'].toString().isNotEmpty) ...[
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(6),
                                                child: Image.network(
                                                  doc['image_url'].toString(),
                                                  height: 200,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              ElevatedButton.icon(
                                                onPressed: () async {
                                                  final url = Uri.parse(doc['image_url'].toString());
                                                  try {
                                                    await launchUrl(url, mode: LaunchMode.externalApplication);
                                                  } catch (e) {
                                                    debugPrint('Erro ao abrir link: $e');
                                                  }
                                                },
                                                icon: const Icon(Icons.open_in_new, size: 16),
                                                label: const Text('ABRIR / BAIXAR ANEXO'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: SteampunkTheme.castIron,
                                                  foregroundColor: SteampunkTheme.copper,
                                                  side: const BorderSide(color: SteampunkTheme.copper, width: 1),
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                            ],
                                            MarkdownBody(
                                              data: doc['content'] ?? '',
                                              styleSheet: MarkdownStyleSheet(
                                                p: Theme.of(context).textTheme.bodyMedium,
                                                h1: GoogleFonts.cinzel(fontSize: 22, color: SteampunkTheme.copper, fontWeight: FontWeight.bold),
                                                h2: GoogleFonts.cinzel(fontSize: 20, color: SteampunkTheme.copper),
                                                h3: GoogleFonts.cinzel(fontSize: 18, color: SteampunkTheme.brassGlow),
                                                listBullet: const TextStyle(color: SteampunkTheme.copper),
                                              ),
                                            ),
                                            if (canEdit) ...[
                                              const SizedBox(height: 16),
                                              ElevatedButton.icon(
                                                onPressed: () => _onEditDocument(doc),
                                                icon: const Icon(Icons.edit, size: 16),
                                                label: const Text('EDITAR DOCUMENTO'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: SteampunkTheme.castIron,
                                                  foregroundColor: SteampunkTheme.brassGlow,
                                                  side: const BorderSide(color: SteampunkTheme.brassGlow, width: 1),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),

                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _onCreateDocument,
                      child: const Text('SUBMETER NOVO DOCUMENTO'),
                    ),
                  ],
                ),
              ),
    );
  }
}
