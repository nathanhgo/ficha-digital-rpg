import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../auth/presentation/auth_controller.dart';
import '../data/character_repository.dart';
import 'diary_editor_screen.dart';
import '../../inventory/data/inventory_repository.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/storage_helper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// WIDGET ADICIONAL: MANÔMETRO DE VAPOR E ENGENHARIA (STEAM MANOMETER)
class SteamManometer extends StatelessWidget {
  final String label;
  final double value;
  final double maxVal;
  final Color accentColor;

  const SteamManometer({
    super.key,
    required this.label,
    required this.value,
    this.maxVal = 100.0,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 90,
          height: 90,
          child: CustomPaint(
            painter: _ManometerPainter(
              value: value,
              maxVal: maxVal,
              accentColor: accentColor,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.cinzel(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: SteampunkTheme.copper,
          ),
        ),
        Text(
          '${value.toInt()} / ${maxVal.toInt()}',
          style: GoogleFonts.specialElite(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

class _ManometerPainter extends CustomPainter {
  final double value;
  final double maxVal;
  final Color accentColor;

  _ManometerPainter({
    required this.value,
    required this.maxVal,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Pintar fundo metalizado do dial
    final dialPaint = Paint()
      ..color = SteampunkTheme.castIron
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, dialPaint);

    // Pintar borda de bronze/cobre do medidor
    final ringPaint = Paint()
      ..color = SteampunkTheme.copper
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    canvas.drawCircle(center, radius - 2, ringPaint);

    // Pintar arco do valor atual
    final arcPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6.0;

    final sweepAngle = (value / maxVal) * (1.5 * math.pi);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 8),
      0.75 * math.pi, // Ângulo inicial
      sweepAngle.clamp(0.0, 1.5 * math.pi),
      false,
      arcPaint,
    );

    // Desenhar agulha indicadora
    final needleAngle = 0.75 * math.pi + sweepAngle.clamp(0.0, 1.5 * math.pi);
    final needlePaint = Paint()
      ..color = SteampunkTheme.bloodRed
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final needleLength = radius - 15;
    final needleTarget = Offset(
      center.dx + needleLength * math.cos(needleAngle),
      center.dy + needleLength * math.sin(needleAngle),
    );
    canvas.drawLine(center, needleTarget, needlePaint);

    // Desenhar pino central da agulha
    final pinPaint = Paint()
      ..color = SteampunkTheme.copper
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4, pinPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


// TELA DA FICHA DE PERSONAGEM
class CharacterSheetScreen extends ConsumerStatefulWidget {
  final String characterId;
  const CharacterSheetScreen({super.key, required this.characterId});

  @override
  ConsumerState<CharacterSheetScreen> createState() => _CharacterSheetScreenState();
}

class _CharacterSheetScreenState extends ConsumerState<CharacterSheetScreen> {
  final _charRepo = CharacterRepository();
  final _inventoryRepo = InventoryRepository();

  Map<String, dynamic>? _charData;
  List<Map<String, dynamic>> _inventory = [];
  bool _isLoading = true;

  Timer? _diaryDebounce;
  final _diaryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _diaryDebounce?.cancel();
    _diaryController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final users = await _charRepo.fetchCharactersForUser(ref.read(authControllerProvider).profile?['id'] ?? '');
    final char = users.firstWhere(
      (c) => c['id'] == widget.characterId,
      orElse: () => <String, dynamic>{},
    );

    if (char.isNotEmpty) {
      _charData = char;
      _diaryController.text = char['diary'] ?? '';
      await _loadInventory();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadInventory() async {
    if (_charData == null) return;
    final items = await _inventoryRepo.fetchInventory(_charData!['id'] as String);
    setState(() {
      _inventory = items;
    });
  }

  final Map<String, List<String>> _attributeSkills = const {
    'CON': [
      'Pele de Ferro',
      'Resistir Veneno',
      'Resistir Frio',
      'Resistir Calor',
    ],
    'FOR': [
      'Carregar',
      'Armas Pesadas',
      'Canhões',
      'Arremessar',
    ],
    'DES': [
      'Arma Branca',
      'Arma de fogo',
      'Arcos',
      'Artes Marciais',
      'Explosivos',
      'Escudo',
      'Furtar',
      'Fechaduras',
      'Condução',
      'Trabalhos Manuais',
    ],
    'AGI': [
      'Esportes',
      'Natação',
      'Mergulho',
      'Furtividade',
      'Montaria',
      'Artes',
      'Esquiva',
    ],
    'CAR': [
      'Barganha',
      'Etiqueta',
      'Gestão',
      'Liderança',
      'Manipulação',
      'Oratória',
      'Esoterismo',
      'Melodia',
    ],
    'VON': [
      'Fé',
      'Resistir',
      'Vidência',
      'Mentalização',
      'Controle Mental',
    ],
    'PER': [
      'Camuflagem',
      'Procura',
      'Rastreio',
      'Sobrevivência',
      'Avaliar',
      'Jogos',
      'Armadilhas',
      'Escapismo',
      'Escutar',
    ],
    'INT': [
      'Historia',
      'Leitura',
      'Conhecimentos',
      'Pesquisa',
      'Idiomas',
      'Falsificação',
      'Computação',
      'Arcanismo',
      'Mente Blindada',
    ],
  };

  void _updateVital(String key, dynamic value) async {
    if (_charData == null || _charData!['is_dead'] == true) return;
    setState(() {
      _charData![key] = value;
    });
    await _charRepo.updateVitals(_charData!['id'] as String, {key: value});
  }

  void _updateSkill(String skillName, int newValue) async {
    if (_charData == null || _charData!['is_dead'] == true) return;
    final Map<String, dynamic> skills = Map<String, dynamic>.from(_charData!['skills'] as Map? ?? {});
    skills[skillName] = newValue;
    setState(() {
      _charData!['skills'] = skills;
    });
    await _charRepo.updateVitals(_charData!['id'] as String, {'skills': skills});
  }

  void _updateAttribute(String attrName, int newValue) async {
    if (_charData == null || _charData!['is_dead'] == true || newValue < 0) return;
    final Map<String, dynamic> attrs = Map<String, dynamic>.from(_charData!['attributes'] as Map? ?? {});
    attrs[attrName] = newValue;

    final conVal = int.tryParse(attrs['CON']?.toString() ?? '10') ?? 10;
    final forVal = int.tryParse(attrs['FOR']?.toString() ?? '10') ?? 10;
    final agiVal = int.tryParse(attrs['AGI']?.toString() ?? '10') ?? 10;
    final dvValue = int.tryParse(_charData!['dv_value']?.toString() ?? '8') ?? 8;

    final maxFv = conVal * dvValue;
    final maxVigor = (conVal * agiVal) ~/ 2;
    final maxCarga = (conVal * forVal).toDouble();

    setState(() {
      _charData!['attributes'] = attrs;
      _charData!['max_fv'] = maxFv;
      _charData!['max_vigor'] = maxVigor;
      _charData!['max_carga'] = maxCarga;

      if ((_charData!['current_fv'] ?? 0) > maxFv) _charData!['current_fv'] = maxFv;
      if ((_charData!['current_vigor'] ?? 0) > maxVigor) _charData!['current_vigor'] = maxVigor;
    });

    await _charRepo.updateVitals(_charData!['id'] as String, {
      'attributes': attrs,
      'max_fv': maxFv,
      'max_vigor': maxVigor,
      'current_fv': _charData!['current_fv'],
      'current_vigor': _charData!['current_vigor'],
    });
  }

  void _editAttributeValue(String attr, int currentVal) {
    final ctrl = TextEditingController(text: currentVal.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SteampunkTheme.castIron,
        title: Text('Editar $attr', style: const TextStyle(color: SteampunkTheme.copper)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Novo Valor'),
          onSubmitted: (v) {
            final val = int.tryParse(v);
            if (val != null && val >= 0) _updateAttribute(attr, val);
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              final val = int.tryParse(ctrl.text);
              if (val != null && val >= 0) _updateAttribute(attr, val);
              Navigator.pop(ctx);
            },
            child: const Text('SALVAR', style: TextStyle(color: SteampunkTheme.copper)),
          ),
        ],
      ),
    );
  }

  void _onDiaryChanged(String text) {
    if (_charData == null || _charData!['is_dead'] == true) return;
    _diaryDebounce?.cancel();
    _diaryDebounce = Timer(const Duration(milliseconds: 800), () async {
      await _charRepo.updateDiary(_charData!['id'] as String, text);
    });
  }

  void _onKillCharacter() {
    final confirmController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SteampunkTheme.castIron,
        title: Text(
          'MORTALIDADE DO CAOS',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: SteampunkTheme.bloodRed),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'A morte é permanente. Sua ficha será bloqueada para edição e seu diário ficará aberto para toda a mesa. Para confirmar, digite o nome exato do personagem abaixo:',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: confirmController,
              decoration: const InputDecoration(labelText: 'Nome do Personagem'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: SteampunkTheme.bloodRed),
            onPressed: () async {
              if (confirmController.text.trim() == _charData!['name']) {
                final navigator = Navigator.of(ctx);
                await _charRepo.killCharacter(_charData!['id'] as String);
                navigator.pop();
                _loadData();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nome incorreto.'),
                    backgroundColor: SteampunkTheme.bloodRed,
                  ),
                );
              }
            },
            child: const Text('MORRER'),
          ),
        ],
      ),
    );
  }

  void _onAddItem() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final weightController = TextEditingController(text: '1.0');
    final qtyController = TextEditingController(text: '1');
    final formKey = GlobalKey<FormState>();
    String category = 'item';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SteampunkTheme.castIron,
        title: Text('ADICIONAR AO INVENTÁRIO', style: Theme.of(context).textTheme.titleLarge),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                  items: const [
                    DropdownMenuItem(value: 'item', child: Text('Item Geral')),
                    DropdownMenuItem(value: 'equipment', child: Text('Equipamento (Durabilidade)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => category = val);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  validator: (v) => v == null || v.isEmpty ? 'Insira o nome' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: weightController,
                        decoration: const InputDecoration(labelText: 'Peso (Kg)'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: qtyController,
                        decoration: const InputDecoration(labelText: 'Quantidade'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],
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
                final success = await _inventoryRepo.addItem(
                  characterId: _charData!['id'] as String,
                  name: nameController.text.trim(),
                  description: descController.text.trim(),
                  weight: double.tryParse(weightController.text) ?? 1.0,
                  quantity: int.tryParse(qtyController.text) ?? 1,
                  accepted: true, // Jogador adicionando a si mesmo é auto-aceito
                  category: category,
                  campaignId: _charData!['campaign_id'],
                );
                if (success) {
                  await _loadInventory();
                  if (mounted) navigator.pop();
                }
              }
            },
            child: const Text('ADICIONAR'),
          ),
        ],
      ),
    );
  }

  void _onEditItem(Map<String, dynamic> inv) {
    final item = inv['items'];
    if (item == null) return;
    
    final nameController = TextEditingController(text: item['name'] ?? '');
    final descController = TextEditingController(text: item['description'] ?? '');
    final weightController = TextEditingController(text: item['weight'].toString());
    final formKey = GlobalKey<FormState>();
    String category = item['category'] ?? 'item';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SteampunkTheme.castIron,
        title: Text('EDITAR ITEM', style: Theme.of(context).textTheme.titleLarge),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                  items: const [
                    DropdownMenuItem(value: 'item', child: Text('Item Geral')),
                    DropdownMenuItem(value: 'equipment', child: Text('Equipamento (Durabilidade)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => category = val);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  validator: (v) => v == null || v.isEmpty ? 'Insira o nome' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: weightController,
                  decoration: const InputDecoration(labelText: 'Peso (Kg)'),
                  keyboardType: TextInputType.number,
                ),
              ],
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
                await _inventoryRepo.updateItem(
                  itemId: item['id'] as String,
                  name: nameController.text.trim(),
                  description: descController.text.trim(),
                  weight: double.tryParse(weightController.text) ?? 0.0,
                  category: category,
                );
                await _loadInventory();
                if (mounted) navigator.pop();
              }
            },
            child: const Text('SALVAR'),
          ),
        ],
      ),
    );
  }

  void _onTransferItem(String inventoryId, String itemName) async {
    final campaignId = _charData?['campaign_id'] as String?;
    if (campaignId == null) return;
    
    // Buscar outros personagens da campanha
    final response = await Supabase.instance.client
        .from('characters')
        .select('id, name')
        .eq('campaign_id', campaignId)
        .neq('id', _charData!['id']);
        
    final otherChars = List<Map<String, dynamic>>.from(response);
    
    if (otherChars.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum outro personagem na campanha para receber o item.')),
      );
      return;
    }
    
    String? selectedCharId;
    
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SteampunkTheme.castIron,
        title: Text('ENVIAR ITEM', style: Theme.of(context).textTheme.titleLarge),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Selecione para quem enviar o item:'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Destinatário'),
                items: otherChars.map((c) => DropdownMenuItem(
                  value: c['id'] as String,
                  child: Text(c['name'] as String),
                )).toList(),
                onChanged: (val) {
                  setDialogState(() => selectedCharId = val);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedCharId != null) {
                final navigator = Navigator.of(ctx);
                await _inventoryRepo.transferItem(
                  inventoryId: inventoryId,
                  targetCharacterId: selectedCharId!,
                  itemName: itemName,
                );
                await _loadInventory();
                if (mounted) navigator.pop();
              }
            },
            child: const Text('ENVIAR'),
          ),
        ],
      ),
    );
  }


  // Cálculos de Peso e Sobrecarga
  double get _currentWeight {
    double total = 0.0;
    for (var item in _inventory) {
      if (item['accepted'] == true) {
        final itemData = item['items'];
        if (itemData != null) {
          final double itemW = double.tryParse(itemData['weight'].toString()) ?? 0.0;
          final int qty = item['quantity'] as int? ?? 1;
          total += itemW * qty;
        }
      }
    }
    return total;
  }

  double get _weightCapacity {
    if (_charData == null) return 50.0;
    final attrs = _charData!['attributes'] as Map<String, dynamic>? ?? {};
    final con = double.tryParse(attrs['CON']?.toString() ?? '10') ?? 10.0;
    final str = double.tryParse(attrs['FOR']?.toString() ?? '10') ?? 10.0;
    // Fórmulas da Ficha: Capacidade de Carga = CON * FOR
    return con * str;
  }

  bool get _isOverloaded => _currentWeight > _weightCapacity;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: SteampunkTheme.copper)),
      );
    }

    if (_charData == null) {
      return const Scaffold(
        body: Center(child: Text('Personagem não encontrado.')),
      );
    }

    final isDead = _charData!['is_dead'] == true;
    final attrs = _charData!['attributes'] as Map<String, dynamic>? ?? {};

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${_charData!['name']} (Nível ${_charData!['level']})'.toUpperCase()),
          bottom: TabBar(
            isScrollable: true,
            labelColor: SteampunkTheme.copper,
            unselectedLabelColor: Colors.white60,
            indicatorColor: SteampunkTheme.copper,
            tabs: const [
              Tab(text: 'VITAIS'),
              Tab(text: 'ATRIBUTOS'),
              Tab(text: 'PRÓTESES'),
              Tab(text: 'INVENTÁRIO'),
              Tab(text: 'DIÁRIO'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ABA 1: VITAIS
            _buildVitalsTab(isDead),

            // ABA 2: ATRIBUTOS & SKILLS
            _buildAttributesTab(attrs),

            // ABA 3: PRÓTESES
            _buildProstheticsTab(isDead),

            // ABA 4: INVENTÁRIO
            _buildInventoryTab(isDead),

            // ABA 5: DIÁRIO & MORTE
            _buildDiaryTab(isDead),
          ],
        ),
      ),
    );
  }
  Future<void> _addEffect(Map<String, dynamic> effect) async {
    if (_charData == null) return;
    
    final target = effect['target'] as String;
    final value = effect['value'] as int;
    
    final newData = Map<String, dynamic>.from(_charData!);
    
    if (target == 'FV') {
      newData['current_fv'] = (newData['current_fv'] as int? ?? 10) + value;
      newData['max_fv'] = (newData['max_fv'] as int? ?? 10) + value;
    } else if (target == 'Vigor') {
      newData['current_vigor'] = (newData['current_vigor'] as int? ?? 10) + value;
      newData['max_vigor'] = (newData['max_vigor'] as int? ?? 10) + value;
    } else if (target == 'PM') {
      newData['current_pm'] = (newData['current_pm'] as int? ?? 100) + value;
      newData['max_pm'] = (newData['max_pm'] as int? ?? 100) + value;
    } else if (target == 'Sanidade') {
      newData['sanidade'] = (newData['sanidade'] as int? ?? 100) + value;
    }
    
    final efeitos = List<Map<String, dynamic>>.from(newData['efeitos'] ?? []);
    efeitos.add(effect);
    newData['efeitos'] = efeitos;
    
    final payload = {
      'efeitos': efeitos,
      'current_fv': newData['current_fv'],
      'max_fv': newData['max_fv'],
      'current_vigor': newData['current_vigor'],
      'max_vigor': newData['max_vigor'],
      'current_pm': newData['current_pm'],
      'max_pm': newData['max_pm'],
      'sanidade': newData['sanidade'],
    };
    await _charRepo.updateVitals(widget.characterId, payload);
    setState(() => _charData = newData);
  }

  Future<void> _removeEffect(int index) async {
    if (_charData == null) return;
    
    final efeitos = List<Map<String, dynamic>>.from(_charData!['efeitos'] ?? []);
    if (index < 0 || index >= efeitos.length) return;
    
    final effect = efeitos[index];
    final target = effect['target'] as String;
    final value = effect['value'] as int;
    
    final newData = Map<String, dynamic>.from(_charData!);
    
    if (target == 'FV') {
      newData['current_fv'] = (newData['current_fv'] as int? ?? 10) - value;
      newData['max_fv'] = (newData['max_fv'] as int? ?? 10) - value;
    } else if (target == 'Vigor') {
      newData['current_vigor'] = (newData['current_vigor'] as int? ?? 10) - value;
      newData['max_vigor'] = (newData['max_vigor'] as int? ?? 10) - value;
    } else if (target == 'PM') {
      newData['current_pm'] = (newData['current_pm'] as int? ?? 100) - value;
      newData['max_pm'] = (newData['max_pm'] as int? ?? 100) - value;
    } else if (target == 'Sanidade') {
      newData['sanidade'] = (newData['sanidade'] as int? ?? 100) - value;
    }
    
    efeitos.removeAt(index);
    newData['efeitos'] = efeitos;
    
    final payload = {
      'efeitos': efeitos,
      'current_fv': newData['current_fv'],
      'max_fv': newData['max_fv'],
      'current_vigor': newData['current_vigor'],
      'max_vigor': newData['max_vigor'],
      'current_pm': newData['current_pm'],
      'max_pm': newData['max_pm'],
      'sanidade': newData['sanidade'],
    };
    await _charRepo.updateVitals(widget.characterId, payload);
    setState(() => _charData = newData);
  }

  Widget _buildEffectsSection(bool isDead) {
    final efeitos = List<Map<String, dynamic>>.from(_charData!['efeitos'] ?? []);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(color: SteampunkTheme.copper, height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('EFEITOS ATIVOS', style: GoogleFonts.cinzel(fontSize: 18, fontWeight: FontWeight.bold, color: SteampunkTheme.copper)),
            IconButton(
              icon: const Icon(Icons.add_circle, color: SteampunkTheme.copper),
              onPressed: isDead ? null : _showAddEffectDialog,
            ),
          ],
        ),
        if (efeitos.isEmpty)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Nenhum efeito ativo.', style: TextStyle(color: Colors.white54)),
          )
        else
          ...efeitos.asMap().entries.map((entry) {
            final idx = entry.key;
            final ef = entry.value;
            final val = ef['value'] as int;
            final valStr = val > 0 ? '+$val' : '$val';
            final color = val > 0 ? Colors.green : SteampunkTheme.bloodRed;
            return Card(
              color: SteampunkTheme.castIron,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(ef['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Alvo: ${ef['target']} ($valStr)'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: SteampunkTheme.bloodRed),
                  onPressed: isDead ? null : () => _removeEffect(idx),
                ),
              ),
            );
          }),
      ],
    );
  }

  void _showAddEffectDialog() {
    final titleCtrl = TextEditingController();
    final valCtrl = TextEditingController(text: '0');
    String selectedTarget = 'FV';
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: SteampunkTheme.castIron,
          title: const Text('ADICIONAR EFEITO', style: TextStyle(color: SteampunkTheme.copper)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Título do Efeito (Ex: Maldição)'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedTarget,
                dropdownColor: SteampunkTheme.leatherBark,
                decoration: const InputDecoration(labelText: 'Atributo Alvo'),
                items: ['FV', 'Vigor', 'PM', 'Sanidade'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setDialogState(() => selectedTarget = v!),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: valCtrl,
                keyboardType: const TextInputType.numberWithOptions(signed: true),
                decoration: const InputDecoration(labelText: 'Valor (+ ou -)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: SteampunkTheme.copper, foregroundColor: SteampunkTheme.castIron),
              onPressed: () {
                final val = int.tryParse(valCtrl.text) ?? 0;
                if (titleCtrl.text.isNotEmpty && val != 0) {
                  _addEffect({
                    'title': titleCtrl.text,
                    'target': selectedTarget,
                    'value': val,
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('ADICIONAR'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalsTab(bool isDead) {
    final int level = _charData!['level'] as int? ?? 0;
    final int currentXp = _charData!['xp'] as int? ?? 0;
    final int nextLevelXp = (level + 1) * 100;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: SteampunkTheme.castIron,
                  backgroundImage: _charData!['avatar_url'] != null && _charData!['avatar_url'].toString().isNotEmpty
                      ? NetworkImage(_charData!['avatar_url'].toString())
                      : null,
                  child: _charData!['avatar_url'] == null || _charData!['avatar_url'].toString().isEmpty
                      ? const Icon(Icons.person, size: 60, color: SteampunkTheme.copper)
                      : null,
                ),
                if (!isDead)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: SteampunkTheme.copper,
                      radius: 18,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                        onPressed: () async {
                          final url = await SupabaseStorageHelper.pickAndUploadFile(
                            fileType: FileType.image,
                          );
                          if (url != null) {
                            setState(() {
                              _charData!['avatar_url'] = url;
                            });
                            await _charRepo.updateVitals(_charData!['id'] as String, {'avatar_url': url});
                          }
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (isDead)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SteampunkTheme.bloodRed.withValues(alpha: 0.2),
                border: Border.all(color: SteampunkTheme.bloodRed, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'PERSONAGEM DECEASADO / MORTO',
                style: GoogleFonts.cinzel(color: Colors.white, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),

          // Progresso de XP
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'EXPERIÊNCIA',
                        style: GoogleFonts.cinzel(
                          fontWeight: FontWeight.bold,
                          color: SteampunkTheme.copper,
                        ),
                      ),
                      Text(
                        '$currentXp / $nextLevelXp XP (NÍVEL $level)',
                        style: GoogleFonts.specialElite(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (currentXp / nextLevelXp).clamp(0.0, 1.0),
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(SteampunkTheme.copper),
                    minHeight: 8,
                  ),
                ],
              ),
            ),
          ),

          // HP / FV Slider
          _buildVitalSlider(
            label: 'FV (FÔRÇA VITAL)',
            currentKey: 'current_fv',
            maxKey: 'max_fv',
            color: SteampunkTheme.bloodRed,
            isDead: isDead,
          ),
          const SizedBox(height: 16),

          // Vigor Slider
          _buildVitalSlider(
            label: 'VIGOR',
            currentKey: 'current_vigor',
            maxKey: 'max_vigor',
            color: Colors.green,
            isDead: isDead,
          ),
          const SizedBox(height: 16),

          // Pontos Mentais Slider
          _buildVitalSlider(
            label: 'P. MENTAIS',
            currentKey: 'current_pm',
            maxKey: 'max_pm',
            color: Colors.blueAccent,
            isDead: isDead,
          ),
          const SizedBox(height: 16),

          // Sanidade Slider
          _buildSliderWithCustomMax(
            label: 'SANIDADE',
            key: 'sanidade',
            color: Colors.purple,
            maxVal: 100.0,
            isDead: isDead,
          ),
          const SizedBox(height: 16),

          // Fome & Sede
          Row(
            children: [
              Expanded(
                child: _buildSliderWithCustomMax(
                  label: 'FOME',
                  key: 'fome',
                  color: Colors.orange,
                  maxVal: 100.0,
                  isDead: isDead,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSliderWithCustomMax(
                  label: 'SEDE',
                  key: 'sede',
                  color: Colors.blue,
                  maxVal: 100.0,
                  isDead: isDead,
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),

          // MANÔMETROS ANALÓGICOS (CAOS E RADIAÇÃO)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SteamManometer(
                label: 'CAOS',
                value: double.tryParse(_charData!['caos']?.toString() ?? '0') ?? 0.0,
                accentColor: SteampunkTheme.brassGlow,
              ),
              SteamManometer(
                label: 'RADIAÇÃO',
                value: double.tryParse(_charData!['exposicao_rad']?.toString() ?? '0') ?? 0.0,
                accentColor: Colors.teal,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: SteampunkTheme.copper),
                onPressed: isDead ? null : () => _updateVital('caos', math.max(0, (_charData!['caos'] as int? ?? 0) - 5)),
              ),
              Text('AJUSTAR CAOS', style: Theme.of(context).textTheme.labelLarge),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: SteampunkTheme.copper),
                onPressed: isDead ? null : () => _updateVital('caos', math.min(100, (_charData!['caos'] as int? ?? 0) + 5)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.teal),
                onPressed: isDead ? null : () => _updateVital('exposicao_rad', math.max(0, (_charData!['exposicao_rad'] as int? ?? 0) - 5)),
              ),
              Text('AJUSTAR RADIAÇÃO', style: Theme.of(context).textTheme.labelLarge),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.teal),
                onPressed: isDead ? null : () => _updateVital('exposicao_rad', math.min(100, (_charData!['exposicao_rad'] as int? ?? 0) + 5)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildEffectsSection(isDead),
        ],
      ),
    );
  }

  Widget _buildVitalSlider({
    required String label,
    required String currentKey,
    required String maxKey,
    required Color color,
    required bool isDead,
  }) {
    final double max = double.tryParse(_charData![maxKey]?.toString() ?? '10') ?? 10.0;
    final double current = double.tryParse(_charData![currentKey]?.toString() ?? '10') ?? 10.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, color: SteampunkTheme.copper)),
                Text('${current.toInt()} / ${max.toInt()}', style: GoogleFonts.specialElite(fontSize: 14)),
              ],
            ),
            Slider(
              value: current.clamp(0.0, max),
              min: 0,
              max: max,
              activeColor: color,
              inactiveColor: color.withValues(alpha: 0.2),
              onChanged: isDead ? null : (val) => _updateVital(currentKey, val.toInt()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderWithCustomMax({
    required String label,
    required String key,
    required Color color,
    required double maxVal,
    required bool isDead,
  }) {
    final double val = double.tryParse(_charData![key]?.toString() ?? '50') ?? 50.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, color: SteampunkTheme.copper)),
                Text('${val.toInt()}%', style: GoogleFonts.specialElite(fontSize: 14)),
              ],
            ),
            Slider(
              value: val.clamp(0.0, maxVal),
              min: 0,
              max: maxVal,
              activeColor: color,
              inactiveColor: color.withValues(alpha: 0.2),
              onChanged: isDead ? null : (v) => _updateVital(key, v.toInt()),
            ),
          ],
        ),
      ),
    );
  }

  void _onRollAttributeDice(String attr, int mod) {
    final roll = math.Random().nextInt(20) + 1;
    final total = roll + mod;
    final isCrit = roll == 20;
    final isFail = roll == 1;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SteampunkTheme.castIron,
        title: Text('TESTE DE ${attr.toUpperCase()}', style: const TextStyle(color: SteampunkTheme.copper)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Resultado do d20: $roll', style: GoogleFonts.specialElite(fontSize: 18, color: isCrit ? Colors.green : (isFail ? SteampunkTheme.bloodRed : Colors.white))),
            Text('Modificador: ${mod >= 0 ? '+' : ''}$mod', style: GoogleFonts.specialElite(fontSize: 14)),
            const Divider(color: Colors.white24),
            Text('TOTAL: $total', style: GoogleFonts.cinzel(fontSize: 32, fontWeight: FontWeight.bold, color: SteampunkTheme.brassGlow)),
            if (isCrit)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text('SUCESSO CRÍTICO!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            if (isFail)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text('FALHA CRÍTICA!', style: TextStyle(color: SteampunkTheme.bloodRed, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('FECHAR'),
          )
        ],
      ),
    );
  }

  Widget _buildAttributesTab(Map<String, dynamic> attributes) {
    final isDead = _charData!['is_dead'] == true;
    final Map<String, dynamic> skills = Map<String, dynamic>.from(_charData!['skills'] as Map? ?? {});

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: attributes.keys.length,
      itemBuilder: (context, idx) {
        final attr = attributes.keys.elementAt(idx);
        final val = int.tryParse(attributes[attr].toString()) ?? 10;
        final mod = (val - 10) ~/ 2;

        final groupSkills = _attributeSkills[attr] ?? [];
        int groupTotalSpent = 0;
        for (var s in groupSkills) {
          groupTotalSpent += (skills[s] as num? ?? 0).toInt();
        }
        final maxPointsAllowed = val * 3;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            trailing: const SizedBox.shrink(),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Esquerda: Sigla do Atributo
                SizedBox(
                  width: 32,
                  child: Text(
                    attr.split('').join('\n'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cinzel(
                      fontWeight: FontWeight.bold,
                      color: SteampunkTheme.copper,
                      fontSize: 16,
                      height: 1.1,
                    ),
                  ),
                ),
                
                // Centro: Controles de Valor
                GestureDetector(
                  onTap: () {}, // Evita expandir o tile ao clicar na área entre botões
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 20, color: SteampunkTheme.copper),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: isDead ? null : () => _updateAttribute(attr, val - 1),
                      ),
                      InkWell(
                        onTap: isDead ? null : () => _editAttributeValue(attr, val),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Text(
                            'VAL: $val (MOD: ${mod >= 0 ? '+' : ''}$mod)',
                            style: GoogleFonts.specialElite(fontSize: 14, decoration: TextDecoration.underline),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 20, color: SteampunkTheme.copper),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: isDead ? null : () => _updateAttribute(attr, val + 1),
                      ),
                    ],
                  ),
                ),

                // Direita: Botão de Rolar Dado
                GestureDetector(
                  onTap: () => _onRollAttributeDice(attr, mod),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.casino, size: 24, color: SteampunkTheme.brassGlow),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'Perícias: $groupTotalSpent / $maxPointsAllowed Pts',
                style: TextStyle(
                  color: groupTotalSpent == maxPointsAllowed ? Colors.green : Colors.white38,
                  fontSize: 12,
                ),
              ),
            ),
            children: [
              ...groupSkills.map((skill) {
                final currentSkillPoints = (skills[skill] as num? ?? 0).toInt();
                final canAdd = groupTotalSpent < maxPointsAllowed;
                final canSub = currentSkillPoints > 0;

                return ListTile(
                  title: Text(skill, style: GoogleFonts.ebGaramond(fontSize: 18)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 18, color: Colors.white70),
                        onPressed: (!isDead && canSub)
                            ? () => _updateSkill(skill, currentSkillPoints - 1)
                            : null,
                      ),
                      Text(
                        '$currentSkillPoints',
                        style: GoogleFonts.specialElite(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 18, color: Colors.white70),
                        onPressed: (!isDead && canAdd)
                            ? () => _updateSkill(skill, currentSkillPoints + 1)
                            : null,
                      ),
                    ],
                  ),
                );
              }),
              if (groupSkills.isEmpty)
                const ListTile(
                  title: Text('Nenhuma perícia vinculada a este atributo.'),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProstheticsTab(bool isDead) {
    // Vapor / Óleo Sliders para próteses steampunk
    final double v = double.tryParse(_charData!['vapor']?.toString() ?? '0') ?? 0.0;
    final double o = double.tryParse(_charData!['oleo']?.toString() ?? '0') ?? 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ENGENHARIA CORPORAL & PRÓTESES',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('NÍVEL DE VAPOR', style: GoogleFonts.cinzel(color: Colors.cyan)),
                      Text('${v.toInt()} Psi', style: GoogleFonts.specialElite()),
                    ],
                  ),
                  Slider(
                    value: v,
                    min: 0,
                    max: 100,
                    activeColor: Colors.cyan,
                    onChanged: isDead ? null : (val) => _updateVital('vapor', val.toInt()),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('NÍVEL DE ÓLEO/FLUIDO', style: GoogleFonts.cinzel(color: Colors.amber)),
                      Text('${o.toInt()} Lt', style: GoogleFonts.specialElite()),
                    ],
                  ),
                  Slider(
                    value: o,
                    min: 0,
                    max: 100,
                    activeColor: Colors.amber,
                    onChanged: isDead ? null : (val) => _updateVital('oleo', val.toInt()),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Descrição livre das Próteses instaladas
          TextFormField(
            initialValue: _charData!['c_corpo'] ?? '',
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Descrição de Implantes e Próteses instaladas',
              alignLabelWithHint: true,
            ),
            readOnly: isDead,
            onChanged: (text) => _updateVital('c_corpo', text),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryTab(bool isDead) {
    return Column(
      children: [
        // Barra de Capacidade de Carga
        Container(
          padding: const EdgeInsets.all(16),
          color: SteampunkTheme.castIron,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CAPACIDADE DE CARGA (FOR * CON)',
                    style: GoogleFonts.cinzel(color: SteampunkTheme.copper, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_currentWeight.toStringAsFixed(1)} / ${_weightCapacity.toStringAsFixed(1)} Kg',
                    style: GoogleFonts.specialElite(
                      color: _isOverloaded ? SteampunkTheme.bloodRed : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentWeight / _weightCapacity).clamp(0.0, 1.0),
                  minHeight: 12,
                  color: _isOverloaded ? SteampunkTheme.bloodRed : SteampunkTheme.copper,
                  backgroundColor: Colors.white10,
                ),
              ),
              if (_isOverloaded)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    '⚠️ ALERTA: SOBRECARREGADO (PUNIÇÕES DE DESVANTAGEM APLICÁVEIS)',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: SteampunkTheme.bloodRed,
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_inventory.where((inv) => (inv['items']?['category'] ?? 'item') == 'equipment').isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
                    child: Text('EQUIPAMENTOS', style: GoogleFonts.cinzel(color: SteampunkTheme.copper, fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _inventory.length,
                    itemBuilder: (context, idx) {
                      final inv = _inventory[idx];
                      if ((inv['items']?['category'] ?? 'item') != 'equipment') return const SizedBox.shrink();
                      return _buildInventoryCard(inv, isDead);
                    },
                  ),
                ],
                if (_inventory.where((inv) => (inv['items']?['category'] ?? 'item') != 'equipment').isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
                    child: Text('ITENS', style: GoogleFonts.cinzel(color: SteampunkTheme.copper, fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _inventory.length,
                    itemBuilder: (context, idx) {
                      final inv = _inventory[idx];
                      if ((inv['items']?['category'] ?? 'item') == 'equipment') return const SizedBox.shrink();
                      return _buildInventoryCard(inv, isDead);
                    },
                  ),
                ],
              ],
            ),
          ),
        ),

        if (!isDead)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _onAddItem,
              child: const Text('ADICIONAR ITEM AO INVENTÁRIO'),
            ),
          ),
      ],
    );
  }

  Widget _buildInventoryCard(Map<String, dynamic> inv, bool isDead) {
    final item = inv['items'];
    if (item == null) return const SizedBox.shrink();

    final isAccepted = inv['accepted'] == true;
    final weight = double.tryParse(item['weight'].toString()) ?? 0.0;
    final qty = inv['quantity'] as int? ?? 1;

    final cat = item['category'] ?? 'item';
    final isEq = cat == 'equipment';
    final durability = inv['durability'] as int? ?? 20;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isAccepted ? SteampunkTheme.castIron : SteampunkTheme.copper.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'].toUpperCase(),
                        style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, color: isAccepted ? Colors.white : SteampunkTheme.copper),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item['description'] ?? 'Sem descrição'} | Peso: ${weight}Kg',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (isAccepted && !isDead) ...[
                  IconButton(
                    icon: const Icon(Icons.send, color: SteampunkTheme.brassGlow, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _onTransferItem(inv['id'] as String, item['name']),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.edit, color: SteampunkTheme.copper, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _onEditItem(inv),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.delete, color: SteampunkTheme.bloodRed, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () async {
                      await _inventoryRepo.deleteItem(inv['id'] as String);
                      _loadInventory();
                    },
                  ),
                ] else if (!isAccepted && !isDead) ...[
                  ElevatedButton(
                    onPressed: () async {
                      await _inventoryRepo.acceptItem(inv['id'] as String);
                      _loadInventory();
                    },
                    child: const Text('ACEITAR'),
                  )
                ]
              ],
            ),
            if (isEq && isAccepted) ...[
              const Divider(color: Colors.white10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text('DURABILIDADE DO EQUIPAMENTO', style: GoogleFonts.specialElite(color: Colors.white70))),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: isDead ? null : () async {
                          await _inventoryRepo.updateDurability(inv['id'] as String, durability - 1);
                          _loadInventory();
                        },
                      ),
                      const SizedBox(width: 12),
                      Text('$durability', style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.add, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: isDead ? null : () async {
                          await _inventoryRepo.updateDurability(inv['id'] as String, durability + 1);
                          _loadInventory();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ] else if (!isEq && isAccepted) ...[
              const Divider(color: Colors.white10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text('QUANTIDADE', style: GoogleFonts.specialElite(color: Colors.white70))),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: isDead || qty <= 1 ? null : () async {
                          await _inventoryRepo.updateQuantity(inv['id'] as String, qty - 1);
                          _loadInventory();
                        },
                      ),
                      const SizedBox(width: 12),
                      Text('$qty', style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.add, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: isDead ? null : () async {
                          await _inventoryRepo.updateQuantity(inv['id'] as String, qty + 1);
                          _loadInventory();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDiaryTab(bool isDead) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'DIÁRIO DO PERSONAGEM',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isDead
                ? 'Este diário foi tornado público na campanha por conta do óbito do personagem e seus registros estão trancados.'
                : 'Suas notas pessoais. O mestre não pode ver até você morrer.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white60),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SteampunkTheme.castIron,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: SingleChildScrollView(
                child: _diaryController.text.isNotEmpty
                    ? MarkdownBody(
                        data: _diaryController.text,
                        styleSheet: MarkdownStyleSheet(
                          p: GoogleFonts.ebGaramond(fontSize: 16, color: Colors.white70),
                          h1: GoogleFonts.cinzel(fontSize: 22, color: SteampunkTheme.copper, fontWeight: FontWeight.bold),
                          h2: GoogleFonts.cinzel(fontSize: 20, color: SteampunkTheme.copper),
                          h3: GoogleFonts.cinzel(fontSize: 18, color: SteampunkTheme.brassGlow),
                          listBullet: const TextStyle(color: SteampunkTheme.copper),
                        ),
                      )
                    : Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            'O diário está vazio.',
                            style: GoogleFonts.ebGaramond(color: Colors.white30, fontSize: 16),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          if (!isDead) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => DiaryEditorScreen(
                      characterId: _charData!['id'] as String,
                      initialContent: _diaryController.text,
                    ),
                  ),
                );
                // Refresh after returning
                _loadData();
              },
              icon: const Icon(Icons.edit),
              label: const Text('EDITAR DIÁRIO'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: SteampunkTheme.bloodRed),
              onPressed: _onKillCharacter,
              child: const Text('DECLARAR ÓBITO DO PERSONAGEM'),
            ),
          ],
        ],
      ),
    );
  }
}
