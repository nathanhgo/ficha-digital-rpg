import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/theme.dart';
import '../data/system_info_repository.dart';
import '../../campaign/data/campaign_repository.dart';
import '../../character/data/character_repository.dart';

class SystemPostEditorScreen extends StatefulWidget {
  final String authorId;
  final Map<String, dynamic>? existingPost;

  const SystemPostEditorScreen({
    super.key,
    required this.authorId,
    this.existingPost,
  });

  @override
  State<SystemPostEditorScreen> createState() => _SystemPostEditorScreenState();
}

class _SystemPostEditorScreenState extends State<SystemPostEditorScreen> {
  final _repo = SystemInfoRepository();
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _allowedCharactersCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSaving = false;
  bool _isPublic = true;
  List<Map<String, dynamic>> _masterCharacters = [];
  List<String> _selectedCharacterIds = [];

  @override
  void initState() {
    super.initState();
    if (widget.existingPost != null) {
      _titleCtrl.text = widget.existingPost!['title'] as String? ?? '';
      _contentCtrl.text = widget.existingPost!['content'] as String? ?? '';
      _isPublic = widget.existingPost!['is_public'] as bool? ?? true;
      final allowed = widget.existingPost!['allowed_character_ids'] as List<dynamic>? ?? [];
      _selectedCharacterIds = allowed.map((e) => e.toString()).toList();
    }
    _loadMasterCharacters();
  }

  Future<void> _loadMasterCharacters() async {
    final campRepo = CampaignRepository();
    final charRepo = CharacterRepository();
    
    final campaigns = await campRepo.fetchCampaigns(widget.authorId, 'master');
    final List<Map<String, dynamic>> chars = [];
    for (var camp in campaigns) {
      final campChars = await charRepo.fetchCharactersForCampaign(camp['id'] as String);
      chars.addAll(campChars);
    }
    
    if (mounted) {
      setState(() {
        _masterCharacters = chars;
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _savePost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    bool success = false;
    if (widget.existingPost == null) {
      success = await _repo.createPost(
        widget.authorId, 
        _titleCtrl.text.trim(), 
        _contentCtrl.text.trim(),
        isPublic: _isPublic,
        allowedCharacterIds: _selectedCharacterIds,
      );
    } else {
      success = await _repo.updatePost(
        widget.existingPost!['id'] as String,
        _titleCtrl.text.trim(),
        _contentCtrl.text.trim(),
        isPublic: _isPublic,
        allowedCharacterIds: _selectedCharacterIds,
      );
    }

    setState(() => _isSaving = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existingPost == null ? 'Publicação criada!' : 'Publicação atualizada!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao salvar publicação.'),
          backgroundColor: SteampunkTheme.bloodRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SteampunkTheme.castIron,
      appBar: AppBar(
        title: Text(widget.existingPost == null ? 'NOVA PUBLICAÇÃO' : 'EDITAR PUBLICAÇÃO'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20, 
                height: 20, 
                child: CircularProgressIndicator(color: SteampunkTheme.copper, strokeWidth: 2)
              ),
            )
          else
            TextButton(
              onPressed: _savePost,
              child: const Text('SALVAR', style: TextStyle(color: SteampunkTheme.copper, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left side: Editor
          Expanded(
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
                      decoration: const InputDecoration(labelText: 'Título'),
                      validator: (v) => v == null || v.isEmpty ? 'Insira um título' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Switch(
                          value: _isPublic,
                          activeColor: SteampunkTheme.copper,
                          onChanged: (val) => setState(() => _isPublic = val),
                        ),
                        Text('Post Público?', style: TextStyle(color: _isPublic ? Colors.white : Colors.white54)),
                      ],
                    ),
                    if (!_isPublic) ...[
                      const SizedBox(height: 8),
                      const Text('Personagens Permitidos:', style: TextStyle(color: SteampunkTheme.copper, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (_masterCharacters.isEmpty)
                        const Text('Carregando personagens...', style: TextStyle(color: Colors.white54))
                      else
                        Container(
                          constraints: const BoxConstraints(maxHeight: 150),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ListView.builder(
                            itemCount: _masterCharacters.length,
                            itemBuilder: (ctx, idx) {
                              final char = _masterCharacters[idx];
                              final charId = char['id'] as String;
                              return CheckboxListTile(
                                title: Text('${char['name']} (${char['profiles']?['username'] ?? '?'})', style: const TextStyle(color: Colors.white70)),
                                value: _selectedCharacterIds.contains(charId),
                                checkColor: SteampunkTheme.castIron,
                                activeColor: SteampunkTheme.copper,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedCharacterIds.add(charId);
                                    } else {
                                      _selectedCharacterIds.remove(charId);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                    ],
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
                        validator: (v) => v == null || v.isEmpty ? 'Insira o conteúdo' : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Right side: Preview
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              color: SteampunkTheme.leatherBark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'PREVIEW DA PUBLICAÇÃO', 
                    style: GoogleFonts.cinzel(color: SteampunkTheme.copper, fontWeight: FontWeight.bold),
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
                          const SizedBox(height: 16),
                          if (_contentCtrl.text.isNotEmpty)
                            MarkdownBody(
                              data: _contentCtrl.text,
                              styleSheet: MarkdownStyleSheet(
                                p: GoogleFonts.ebGaramond(fontSize: 16, color: Colors.white70),
                                h1: GoogleFonts.cinzel(fontSize: 22, color: SteampunkTheme.copper, fontWeight: FontWeight.bold),
                                h2: GoogleFonts.cinzel(fontSize: 20, color: SteampunkTheme.copper),
                                h3: GoogleFonts.cinzel(fontSize: 18, color: SteampunkTheme.brassGlow),
                                listBullet: const TextStyle(color: SteampunkTheme.copper),
                              ),
                            )
                          else
                            Text(
                              'O preview do conteúdo aparecerá aqui...',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontStyle: FontStyle.italic),
                            ),
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
