import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/inventory_repository.dart';
import '../../campaign/presentation/campaigns_controller.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/storage_helper.dart';
import 'package:file_picker/file_picker.dart';

class ItemsCatalogScreen extends ConsumerStatefulWidget {
  final bool isEmbedded;
  const ItemsCatalogScreen({super.key, this.isEmbedded = false});

  @override
  ConsumerState<ItemsCatalogScreen> createState() => _ItemsCatalogScreenState();
}

class _ItemsCatalogScreenState extends ConsumerState<ItemsCatalogScreen> {
  final _inventoryRepo = InventoryRepository();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _selectedCampaignId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Wait for campaigns to load then pick the first one
    final campaigns = ref.read(campaignsControllerProvider).campaigns;
    if (campaigns.isNotEmpty) {
      _selectedCampaignId = campaigns.first['id'] as String;
    }
    await _load();
  }

  Future<void> _load() async {
    if (_selectedCampaignId == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    final items = await _inventoryRepo.fetchTemplateItems(_selectedCampaignId!);
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  void _onCreateItem() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final weightCtrl = TextEditingController(text: '1.0');
    final formKey = GlobalKey<FormState>();
    String? imageUrl;
    String category = 'item';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setDialogState) => AlertDialog(
          backgroundColor: SteampunkTheme.castIron,
          title: Text('NOVO ITEM DO CATÁLOGO', style: Theme.of(context).textTheme.titleLarge),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Campaign selector
                  _buildCampaignDropdown(
                    onChanged: (v) => setDialogState(() => _selectedCampaignId = v),
                  ),
                  const SizedBox(height: 12),
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
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nome do Item'),
                    validator: (v) => v == null || v.isEmpty ? 'Insira um nome' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Descrição'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: weightCtrl,
                    decoration: const InputDecoration(labelText: 'Peso (kg)', suffixText: 'kg'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Insira o peso';
                      if (double.tryParse(v) == null) return 'Número inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  if (imageUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(imageUrl!, height: 80, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 8),
                  ],
                  ElevatedButton.icon(
                    onPressed: () async {
                      final url = await SupabaseStorageHelper.pickAndUploadFile(fileType: FileType.image);
                      if (url != null) setDialogState(() => imageUrl = url);
                    },
                    icon: const Icon(Icons.image, size: 16),
                    label: Text(imageUrl == null ? 'ADICIONAR IMAGEM' : 'ALTERAR IMAGEM'),
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
                if (formKey.currentState!.validate() && _selectedCampaignId != null) {
                  final navigator = Navigator.of(ctx);
                  final result = await _inventoryRepo.createTemplateItem(
                    campaignId: _selectedCampaignId!,
                    name: nameCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    weight: double.parse(weightCtrl.text),
                    category: category,
                    imageUrl: imageUrl,
                  );
                  if (result != null && mounted) {
                    navigator.pop();
                    _load();
                  }
                }
              },
              child: const Text('CRIAR'),
            ),
          ],
        ),
      ),
    );
  }

  void _onDeleteItem(String itemId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SteampunkTheme.castIron,
        title: Text('DELETAR ITEM', style: Theme.of(context).textTheme.titleLarge),
        content: Text(
          'Tem certeza? Itens já entregues não serão afetados.',
          style: GoogleFonts.ebGaramond(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: SteampunkTheme.bloodRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DELETAR'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await Supabase.instance.client.from('items').delete().eq('id', itemId);
      } catch (_) {}
      _load();
    }
  }

  Widget _buildCampaignDropdown({required void Function(String?) onChanged}) {
    final campaigns = ref.read(campaignsControllerProvider).campaigns;
    if (campaigns.isEmpty) return const SizedBox();
    return DropdownButtonFormField<String>(
      initialValue: _selectedCampaignId,
      decoration: const InputDecoration(labelText: 'Campanha'),
      items: campaigns.map((c) => DropdownMenuItem<String>(
        value: c['id'] as String,
        child: Text(c['name'] as String, style: GoogleFonts.ebGaramond()),
      )).toList(),
      onChanged: (v) {
        setState(() => _selectedCampaignId = v);
        onChanged(v);
        _load();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final campaigns = ref.watch(campaignsControllerProvider).campaigns;

    return Scaffold(
      appBar: widget.isEmbedded ? null : AppBar(
        title: Text('CATÁLOGO DE ITENS', style: GoogleFonts.cinzel(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onCreateItem,
        backgroundColor: SteampunkTheme.copper,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('NOVO ITEM', style: GoogleFonts.cinzel(color: Colors.white, fontSize: 12)),
      ),
      body: Container(
        color: SteampunkTheme.leatherBark,
        child: Column(
          children: [
            if (campaigns.length > 1)
              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildCampaignDropdown(onChanged: (_) {}),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: SteampunkTheme.copper))
                  : _selectedCampaignId == null
                      ? Center(
                          child: Text(
                            'Selecione ou crie uma campanha primeiro.',
                            style: GoogleFonts.ebGaramond(color: Colors.white38, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : _items.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.white24),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Catálogo vazio.',
                                    style: GoogleFonts.cinzel(fontSize: 16, color: Colors.white38),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Crie itens para usá-los nas sessões.',
                                    style: GoogleFonts.ebGaramond(color: Colors.white24, fontSize: 14),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                              itemCount: _items.length,
                              itemBuilder: (context, idx) {
                                final item = _items[idx];
                                final name = item['name'] ?? 'Sem Nome';
                                final desc = item['description'] ?? '';
                                final weight = (item['weight'] as num? ?? 0).toDouble();
                                final imageUrl = item['image_url'] as String?;
                                final id = item['id'] as String;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(12),
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: imageUrl != null && imageUrl.isNotEmpty
                                          ? Image.network(imageUrl, width: 52, height: 52, fit: BoxFit.cover)
                                          : Container(
                                              width: 52,
                                              height: 52,
                                              color: SteampunkTheme.leatherBark,
                                              child: const Icon(Icons.inventory_2, color: SteampunkTheme.copper),
                                            ),
                                    ),
                                    title: Text(
                                      name.toString().toUpperCase(),
                                      style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, color: SteampunkTheme.copper, fontSize: 14),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (desc.isNotEmpty)
                                          Text(desc, style: GoogleFonts.ebGaramond(color: Colors.white60, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                                        Text('${weight.toStringAsFixed(1)} kg', style: GoogleFonts.specialElite(color: Colors.white38, fontSize: 12)),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline, color: SteampunkTheme.bloodRed),
                                      onPressed: () => _onDeleteItem(id),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
