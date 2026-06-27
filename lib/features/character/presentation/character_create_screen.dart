import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/character_repository.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/storage_helper.dart';
import 'package:file_picker/file_picker.dart';
import 'characters_provider.dart';

class CharacterCreateScreen extends ConsumerStatefulWidget {
  final String campaignId;
  const CharacterCreateScreen({super.key, required this.campaignId});

  @override
  ConsumerState<CharacterCreateScreen> createState() => _CharacterCreateScreenState();
}

class _CharacterCreateScreenState extends ConsumerState<CharacterCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _raceController = TextEditingController();
  final _classController = TextEditingController();
  final _subclassController = TextEditingController();
  final _professionController = TextEditingController();
  final _dvController = TextEditingController(text: '8');
  final _levelController = TextEditingController(text: '1');
  String? _avatarUrl;

  // Atributos iniciais
  final Map<String, int> _attributes = {
    'CON': 10,
    'FOR': 10,
    'DES': 10,
    'AGI': 10,
    'CAR': 10,
    'VON': 10,
    'INT': 10,
    'PER': 10,
  };

  int get _totalAllocated => _attributes.values.fold(0, (sum, val) => sum + val);
  int get _pointsRemaining {
    int total = _attributes.values.fold(0, (sum, val) => sum + val);
    int level = int.tryParse(_levelController.text) ?? 0;
    return (80 + (level * 3)) - total;
  }

  final _charRepo = CharacterRepository();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _raceController.dispose();
    _classController.dispose();
    _subclassController.dispose();
    _professionController.dispose();
    _dvController.dispose();
    _levelController.dispose();
    super.dispose();
  }

  void _adjustAttribute(String attr, int delta) {
    setState(() {
      final newVal = _attributes[attr]! + delta;
      if (newVal >= 0 && newVal <= 30) {
        if (delta > 0 && _pointsRemaining > 0) {
          _attributes[attr] = newVal;
        } else if (delta < 0) {
          _attributes[attr] = newVal;
        }
      }
    });
  }

  void _editAttribute(String attr) {
    final ctrl = TextEditingController(text: _attributes[attr].toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SteampunkTheme.castIron,
        title: Text('Editar $attr', style: const TextStyle(color: SteampunkTheme.copper)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Valor'),
          onSubmitted: (v) {
            final val = int.tryParse(v);
            if (val != null && val >= 0 && val <= 30) {
              setState(() {
                final diff = val - _attributes[attr]!;
                if (diff <= _pointsRemaining || diff < 0) {
                  _attributes[attr] = val;
                }
              });
            }
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }


  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_pointsRemaining != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _pointsRemaining > 0
                ? 'Você ainda tem $_pointsRemaining pontos para distribuir!'
                : 'Você distribuiu ${_pointsRemaining.abs()} pontos a mais do que o limite!',
          ),
          backgroundColor: SteampunkTheme.bloodRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authState = ref.read(authControllerProvider);
    final userId = authState.profile?['id'] ?? '';

    // Fórmulas da Ficha:
    // Constituição (CON) bruta serve para calcular FV (Vida) e Vigor
    final conValue = _attributes['CON'] ?? 10;
    final dvValue = int.tryParse(_dvController.text) ?? 8;
    
    // FV Máxima = Constituição * DV
    final maxFv = conValue * dvValue;
    // Vigor Máximo = (Constituição * Agilidade) / 2
    final agiValue = _attributes['AGI'] ?? 10;
    final maxVigor = (conValue * agiValue) ~/ 2;

    final char = await _charRepo.createCharacter(
      ownerId: userId,
      name: _nameController.text.trim(),
      race: _raceController.text.trim(),
      charClass: _classController.text.trim(),
      subclass: _subclassController.text.isNotEmpty ? _subclassController.text.trim() : null,
      profession: _professionController.text.trim(),
      dvValue: dvValue,
      campaignIdOrNull: 1, // Just dummy flag parameter
      campaignId: widget.campaignId,
      attributes: _attributes,
      maxFv: maxFv,
      maxVigor: maxVigor,
      level: int.tryParse(_levelController.text) ?? 1,
      avatarUrl: _avatarUrl,
    );

    setState(() => _isLoading = false);

    if (char != null && mounted) {
      ref.invalidate(userCharactersProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Personagem criado com sucesso!'),
          backgroundColor: SteampunkTheme.copper,
        ),
      );
      context.go('/campaigns');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao criar personagem.'),
          backgroundColor: SteampunkTheme.bloodRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NOVO PERSONAGEM'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: SteampunkTheme.leatherBark,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: SteampunkTheme.castIron,
                        backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                            ? NetworkImage(_avatarUrl!)
                            : null,
                        child: _avatarUrl == null || _avatarUrl!.isEmpty
                            ? const Icon(Icons.person, size: 50, color: SteampunkTheme.copper)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          backgroundColor: SteampunkTheme.copper,
                          radius: 16,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                            onPressed: () async {
                              final url = await SupabaseStorageHelper.pickAndUploadFile(
                                fileType: FileType.image,
                              );
                              if (url != null) {
                                setState(() {
                                  _avatarUrl = url;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Identificação
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DADOS DO PERSONAGEM',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Nome do Personagem'),
                          validator: (v) => v == null || v.isEmpty ? 'Insira o nome' : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _raceController,
                                decoration: const InputDecoration(labelText: 'Raça'),
                                validator: (v) => v == null || v.isEmpty ? 'Insira a raça' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _professionController,
                                decoration: const InputDecoration(labelText: 'Profissão (Opcional)'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _classController,
                                decoration: const InputDecoration(labelText: 'Classe'),
                                validator: (v) => v == null || v.isEmpty ? 'Insira a classe' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _subclassController,
                                decoration: const InputDecoration(labelText: 'Subclasse (Opcional)'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _dvController,
                                decoration: const InputDecoration(
                                  labelText: 'Dado de Vida (DV) - Ex: 6, 8, 10, 12',
                                  hintText: 'Apenas o número',
                                ),
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Insira o valor do DV';
                                  final numVal = int.tryParse(v);
                                  if (numVal == null || numVal <= 0) return 'DV inválido';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _levelController,
                                decoration: const InputDecoration(
                                  labelText: 'Nível Inicial',
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setState(() {}),
                                validator: (v) {
                                  final lvl = int.tryParse(v ?? '');
                                  if (lvl == null || lvl < 0) return 'Nível inválido';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Distribuidor de Pontos
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'DISTRIBUIR ATRIBUTOS',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Você deve distribuir exatamente 80 pontos entre os 8 atributos da mesa.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          decoration: BoxDecoration(
                            color: _pointsRemaining == 0
                                ? Colors.green.withValues(alpha: 0.15)
                                : SteampunkTheme.copper.withValues(alpha: 0.15),
                            border: Border.all(
                              color: _pointsRemaining == 0 ? Colors.green : SteampunkTheme.copper,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'PONTOS RESTANTES: $_pointsRemaining / 80',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _pointsRemaining == 0 ? Colors.green : SteampunkTheme.copper,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Grid de Atributos
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 1,
                            childAspectRatio: 4.0,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _attributes.keys.length,
                          itemBuilder: (context, idx) {
                            final attr = _attributes.keys.elementAt(idx);
                            final val = _attributes[attr]!;

                            return Container(
                              decoration: BoxDecoration(
                                color: SteampunkTheme.leatherBark,
                                border: Border.all(color: Colors.white24),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        attr,
                                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                              color: SteampunkTheme.copper,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Text(
                                        'Mod. ${(val - 10) ~/ 2 >= 0 ? '+' : ''}${(val - 10) ~/ 2}',
                                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                              color: Colors.white38,
                                              fontSize: 10,
                                            ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove, size: 18, color: Colors.white70),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => _adjustAttribute(attr, -1),
                                      ),
                                      const SizedBox(width: 8),
                                      InkWell(
                                        onTap: () => _editAttribute(attr),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                          child: Text(
                                            '$val',
                                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.add, size: 18, color: Colors.white70),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => _adjustAttribute(attr, 1),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                if (_isLoading)
                  const Center(child: CircularProgressIndicator(color: SteampunkTheme.copper))
                else
                  ElevatedButton(
                    onPressed: _submit,
                    child: const Text('SALVAR PERSONAGEM'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
