import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/theme.dart';
import '../data/character_repository.dart';

class DiaryEditorScreen extends StatefulWidget {
  final String characterId;
  final String initialContent;

  const DiaryEditorScreen({
    super.key,
    required this.characterId,
    required this.initialContent,
  });

  @override
  State<DiaryEditorScreen> createState() => _DiaryEditorScreenState();
}

class _DiaryEditorScreenState extends State<DiaryEditorScreen> {
  final _charRepo = CharacterRepository();
  late final TextEditingController _contentCtrl;
  
  Timer? _saveDebounce;
  bool _isSaving = false;
  bool _isSaved = true;

  @override
  void initState() {
    super.initState();
    _contentCtrl = TextEditingController(text: widget.initialContent);
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _onDiaryChanged(String text) {
    if (_isSaved) {
      setState(() => _isSaved = false);
    }
    
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 800), () async {
      setState(() => _isSaving = true);
      try {
        await _charRepo.updateDiary(widget.characterId, text.trim());
        if (mounted) {
          setState(() {
            _isSaved = true;
            _isSaving = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SteampunkTheme.castIron,
      appBar: AppBar(
        title: const Text('EDITAR DIÁRIO'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: SteampunkTheme.copper, strokeWidth: 2),
                    )
                  : Icon(
                      _isSaved ? Icons.check : Icons.edit,
                      color: _isSaved ? Colors.green : SteampunkTheme.copper,
                      size: 20,
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                _isSaving ? 'SALVANDO...' : (_isSaved ? 'SALVO' : 'EDITANDO...'),
                style: GoogleFonts.cinzel(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _isSaving ? SteampunkTheme.copper : (_isSaved ? Colors.green : SteampunkTheme.copper),
                ),
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
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: Colors.white12)),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _contentCtrl,
                      textAlignVertical: TextAlignVertical.top,
                      expands: true,
                      maxLines: null,
                      decoration: const InputDecoration(
                        labelText: 'Conteúdo (Markdown)',
                        alignLabelWithHint: true,
                        hintText: 'Escreva suas memórias de campanha aqui...',
                      ),
                      onChanged: (val) {
                        _onDiaryChanged(val);
                        setState(() {}); // For preview update
                      },
                    ),
                  ),
                ],
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
                    'PREVIEW DO DIÁRIO', 
                    style: GoogleFonts.cinzel(color: SteampunkTheme.copper, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: _contentCtrl.text.isNotEmpty
                          ? MarkdownBody(
                              data: _contentCtrl.text,
                              styleSheet: MarkdownStyleSheet(
                                p: GoogleFonts.ebGaramond(fontSize: 16, color: Colors.white70),
                                h1: GoogleFonts.cinzel(fontSize: 22, color: SteampunkTheme.copper, fontWeight: FontWeight.bold),
                                h2: GoogleFonts.cinzel(fontSize: 20, color: SteampunkTheme.copper),
                                h3: GoogleFonts.cinzel(fontSize: 18, color: SteampunkTheme.brassGlow),
                                listBullet: const TextStyle(color: SteampunkTheme.copper),
                              ),
                            )
                          : Text(
                              'O preview do seu diário aparecerá aqui...',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontStyle: FontStyle.italic),
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
