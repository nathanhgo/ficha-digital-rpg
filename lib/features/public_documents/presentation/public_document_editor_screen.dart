import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/storage_helper.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/document_repository.dart';

class PublicDocumentEditorScreen extends ConsumerStatefulWidget {
  final String campaignId;
  final Map<String, dynamic>? existingDoc;

  const PublicDocumentEditorScreen({
    super.key,
    required this.campaignId,
    this.existingDoc,
  });

  @override
  ConsumerState<PublicDocumentEditorScreen> createState() =>
      _PublicDocumentEditorScreenState();
}

class _PublicDocumentEditorScreenState
    extends ConsumerState<PublicDocumentEditorScreen> {
  final _docRepo = DocumentRepository();
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _category = 'lore';
  String? _fileUrl;
  bool _isSaving = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingDoc != null) {
      _titleCtrl.text = widget.existingDoc!['title'] as String? ?? '';
      _contentCtrl.text = widget.existingDoc!['content'] as String? ?? '';
      _category = widget.existingDoc!['category'] as String? ?? 'lore';
      _fileUrl = widget.existingDoc!['image_url'] as String?;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadFile() async {
    setState(() => _isUploading = true);
    final url = await SupabaseStorageHelper.pickAndUploadFile(
      fileType: FileType.any,
    );
    setState(() {
      if (url != null) _fileUrl = url;
      _isUploading = false;
    });
  }

  Future<void> _saveDoc() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final authState = ref.read(authControllerProvider);
    final userId = authState.profile?['id'] ?? '';
    final role = authState.profile?['role'] ?? 'player';

    // Mestres criam auto-aprovados, Jogadores criam como pendentes
    final initialStatus = role == 'master' ? 'approved' : 'pending';

    bool success = false;
    if (widget.existingDoc == null) {
      success = await _docRepo.createDocument(
        campaignId: widget.campaignId,
        authorId: userId,
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
        category: _category,
        imageUrl: _fileUrl,
        initialStatus: initialStatus,
      );
    } else {
      success = await _docRepo.updateDocument(
        documentId: widget.existingDoc!['id'] as String,
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
        category: _category,
        imageUrl: _fileUrl,
      );
    }

    setState(() => _isSaving = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.existingDoc == null
                ? 'Documento enviado!'
                : 'Documento atualizado!',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true); // Return true to refresh list
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao salvar documento.'),
          backgroundColor: SteampunkTheme.bloodRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isImage =
        _fileUrl != null &&
        (_fileUrl!.toLowerCase().endsWith('.jpg') ||
            _fileUrl!.toLowerCase().endsWith('.png') ||
            _fileUrl!.toLowerCase().endsWith('.jpeg') ||
            _fileUrl!.toLowerCase().endsWith('.webp'));

    return Scaffold(
      backgroundColor: SteampunkTheme.castIron,
      appBar: AppBar(
        title: Text(
          widget.existingDoc == null ? 'NOVO DOCUMENTO' : 'EDITAR DOCUMENTO',
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: SteampunkTheme.copper,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveDoc,
              child: const Text(
                'SALVAR',
                style: TextStyle(
                  color: SteampunkTheme.copper,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left side: Editor
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: Colors.white12)),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Título do Documento',
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Insira um título' : null,
                      onChanged: (val) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _category,
                      decoration: const InputDecoration(labelText: 'Categoria'),
                      items: const [
                        DropdownMenuItem(
                          value: 'jornal',
                          child: Text('Gazeta / Jornal'),
                        ),
                        DropdownMenuItem(
                          value: 'lore',
                          child: Text('História / Lore'),
                        ),
                        DropdownMenuItem(
                          value: 'mapa',
                          child: Text('Mapa / Localização'),
                        ),
                        DropdownMenuItem(
                          value: 'pesquisa',
                          child: Text('Pesquisa'),
                        ),
                        DropdownMenuItem(
                          value: 'outros',
                          child: Text('Outros'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _category = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_isUploading)
                      const CircularProgressIndicator(
                        color: SteampunkTheme.copper,
                      )
                    else
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SteampunkTheme.leatherBark,
                          foregroundColor: SteampunkTheme.copper,
                          side: const BorderSide(
                            color: SteampunkTheme.copper,
                            width: 1,
                          ),
                        ),
                        onPressed: _pickAndUploadFile,
                        icon: Icon(
                          _fileUrl == null
                              ? Icons.attach_file
                              : Icons.change_circle_outlined,
                          size: 16,
                        ),
                        label: Text(
                          _fileUrl == null ? 'ANEXAR ARQUIVO' : 'ALTERAR ANEXO',
                        ),
                      ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _contentCtrl,
                        textAlignVertical: TextAlignVertical.top,
                        expands: true,
                        maxLines: null,
                        decoration: const InputDecoration(
                          labelText: 'Conteúdo (Markdown)',
                          alignLabelWithHint: true,
                        ),
                        onChanged: (val) => setState(() {}),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Insira o conteúdo' : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Right side: Preview
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              color: SteampunkTheme.leatherBark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'PREVIEW',
                    style: GoogleFonts.cinzel(
                      color: SteampunkTheme.copper,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_titleCtrl.text.isNotEmpty)
                            Text(
                              _titleCtrl.text.toUpperCase(),
                              style: GoogleFonts.cinzel(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: SteampunkTheme.copper,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: SteampunkTheme.copper.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: SteampunkTheme.copper,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _category.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                color: SteampunkTheme.copper,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_contentCtrl.text.isNotEmpty)
                            MarkdownBody(
                              data: _contentCtrl.text,
                              styleSheet: MarkdownStyleSheet(
                                p: GoogleFonts.ebGaramond(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                                h1: GoogleFonts.cinzel(
                                  fontSize: 22,
                                  color: SteampunkTheme.copper,
                                  fontWeight: FontWeight.bold,
                                ),
                                h2: GoogleFonts.cinzel(
                                  fontSize: 20,
                                  color: SteampunkTheme.copper,
                                ),
                                h3: GoogleFonts.cinzel(
                                  fontSize: 18,
                                  color: SteampunkTheme.brassGlow,
                                ),
                                listBullet: const TextStyle(
                                  color: SteampunkTheme.copper,
                                ),
                              ),
                            )
                          else
                            Text(
                              'O preview do conteúdo aparecerá aqui...',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.3),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          if (_fileUrl != null) ...[
                            const SizedBox(height: 24),
                            if (isImage)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(_fileUrl!),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.all(12),
                                color: Colors.white10,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.insert_drive_file,
                                      color: SteampunkTheme.copper,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Arquivo anexado com sucesso.',
                                        style: GoogleFonts.ebGaramond(
                                          color: Colors.white70,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
