import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/document_repository.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/storage_helper.dart';
import 'package:url_launcher/url_launcher.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  final String campaignId;
  const DocumentsScreen({super.key, required this.campaignId});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
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

  void _onCreateDocument() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String category = 'lore'; // default
    String? fileUrl;
    bool uploading = false;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SteampunkTheme.castIron,
        title: Text('NOVO DOCUMENTO PÚBLICO', style: Theme.of(context).textTheme.titleLarge),
        content: SizedBox(
          width: 400,
          child: StatefulBuilder(
            builder: (ctx2, setDialogState) => Form(
              key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Título do Documento'),
                    validator: (v) => v == null || v.isEmpty ? 'Insira o título' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    items: const [
                      DropdownMenuItem(value: 'jornal', child: Text('Gazeta / Jornal')),
                      DropdownMenuItem(value: 'lore', child: Text('História / Lore')),
                      DropdownMenuItem(value: 'mapa', child: Text('Mapa / Localização')),
                      DropdownMenuItem(value: 'pesquisa', child: Text('Pesquisa / Engenharia')),
                      DropdownMenuItem(value: 'outros', child: Text('Outros')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          category = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: contentController,
                    decoration: const InputDecoration(labelText: 'Conteúdo / Relato'),
                    maxLines: 5,
                    validator: (v) => v == null || v.isEmpty ? 'Insira o conteúdo' : null,
                  ),
                  const SizedBox(height: 16),
                  if (fileUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        fileUrl!,
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          padding: const EdgeInsets.all(12),
                          color: Colors.white10,
                          child: Row(
                            children: [
                              const Icon(Icons.insert_drive_file, color: SteampunkTheme.copper),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Arquivo anexado com sucesso.',
                                  style: GoogleFonts.ebGaramond(color: Colors.white70, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (uploading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: CircularProgressIndicator(color: SteampunkTheme.copper),
                    )
                  else
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SteampunkTheme.castIron,
                        foregroundColor: SteampunkTheme.copper,
                        side: const BorderSide(color: SteampunkTheme.copper, width: 1),
                      ),
                      onPressed: () async {
                        setDialogState(() => uploading = true);
                        final url = await SupabaseStorageHelper.pickAndUploadFile(
                          fileType: FileType.any,
                        );
                        setDialogState(() {
                          fileUrl = url;
                          uploading = false;
                        });
                      },
                      icon: Icon(fileUrl == null ? Icons.attach_file : Icons.change_circle_outlined, size: 16),
                      label: Text(
                        fileUrl == null ? 'ANEXAR IMAGEM / ARQUIVO' : 'ALTERAR ANEXO',
                        style: GoogleFonts.cinzel(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
          ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final navigator = Navigator.of(ctx);
                final authState = ref.read(authControllerProvider);
                final userId = authState.profile?['id'] ?? '';
                final role = authState.profile?['role'] ?? 'player';

                // Mestres criam auto-aprovados, Jogadores criam como pendentes
                final initialStatus = role == 'master' ? 'approved' : 'pending';

                final success = await _docRepo.createDocument(
                  campaignId: widget.campaignId,
                  authorId: userId,
                  title: titleController.text.trim(),
                  content: contentController.text.trim(),
                  category: category,
                  imageUrl: fileUrl,
                  initialStatus: initialStatus,
                );

                if (success) {
                  await _loadDocuments();
                  if (mounted) navigator.pop();
                }
              }
            },
            child: const Text('ENVIAR'),
          ),
        ],
      ),
    );
  }

  void _onModerate(String docId, String status) async {
    await _docRepo.updateDocumentStatus(docId, status);
    await _loadDocuments();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final role = authState.profile?['role'] ?? 'player';

    // Dividir documentos em Pendentes (moderador) e Aprovados
    final pendingDocs = _documents.where((d) => d['status'] == 'pending').toList();
    final approvedDocs = _documents.where((d) => d['status'] == 'approved').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('MURAL DE DOCUMENTOS'),
      ),
      body: Container(
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
                                            Text(
                                              doc['content'] ?? '',
                                              style: Theme.of(context).textTheme.bodyMedium,
                                            ),
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
      ),
    );
  }
}
