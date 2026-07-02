import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/theme.dart';

class DiceScreen extends StatefulWidget {
  const DiceScreen({super.key});

  @override
  State<DiceScreen> createState() => _DiceScreenState();
}

class _DiceScreenState extends State<DiceScreen> {
  final Map<dynamic, int> _selectedDice = {
    4: 0,
    6: 0,
    8: 0,
    10: 0,
    12: 0,
    20: 0,
    100: 0,
    'CORPO': 0,
  };
  
  int _bonus = 0;
  List<String> _rollHistory = [];
  
  final _random = Random();

  void _incrementDice(dynamic sides) {
    setState(() {
      _selectedDice[sides] = (_selectedDice[sides] ?? 0) + 1;
    });
  }

  void _decrementDice(dynamic sides) {
    setState(() {
      if ((_selectedDice[sides] ?? 0) > 0) {
        _selectedDice[sides] = (_selectedDice[sides] ?? 0) - 1;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedDice.updateAll((key, value) => 0);
      _bonus = 0;
    });
  }

  void _rollDice() {
    int total = 0;
    List<String> details = [];
    final bodyParts = ['Braço Direito', 'Braço Esquerdo', 'Cabeça', 'Tronco', 'Perna Esquerda', 'Perna Direita'];
    
    _selectedDice.forEach((sides, count) {
      if (count > 0) {
        if (sides == 'CORPO') {
          List<String> rolls = [];
          for (int i = 0; i < count; i++) {
            String part = bodyParts[_random.nextInt(bodyParts.length)];
            rolls.add(part);
          }
          details.add('${count}dCORPO [${rolls.join(', ')}]');
        } else {
          final intSides = sides as int;
          List<int> rolls = [];
          for (int i = 0; i < count; i++) {
            int roll = _random.nextInt(intSides) + 1;
            rolls.add(roll);
            total += roll;
          }
          details.add('${count}d$intSides [${rolls.join(', ')}]');
        }
      }
    });
    
    if (details.isEmpty) return; // No dice selected
    
    total += _bonus;
    
    String rollResult = '${details.join(' + ')}';
    if (_bonus != 0) {
      rollResult += _bonus > 0 ? ' + $_bonus' : ' - ${_bonus.abs()}';
    }
    rollResult += ' = $total';
    
    setState(() {
      _rollHistory.insert(0, rollResult);
      if (_rollHistory.length > 20) {
        _rollHistory.removeLast();
      }
    });
  }

  void _editDiceCount(dynamic sides, int currentCount) {
    final ctrl = TextEditingController(text: currentCount.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SteampunkTheme.castIron,
        title: Text(sides == 'CORPO' ? 'Quantidade (dCORPO)' : 'Quantidade (d$sides)', style: const TextStyle(color: SteampunkTheme.copper)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Quantidade'),
          onSubmitted: (v) {
            final val = int.tryParse(v);
            if (val != null && val >= 0) {
              setState(() => _selectedDice[sides] = val);
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

  void _editBonus() {
    final ctrl = TextEditingController(text: _bonus.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SteampunkTheme.castIron,
        title: const Text('Bônus/Penalidade', style: TextStyle(color: SteampunkTheme.copper)),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Valor'),
          onSubmitted: (v) {
            final val = int.tryParse(v);
            if (val != null) {
              setState(() => _bonus = val);
            }
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              final val = int.tryParse(ctrl.text);
              if (val != null) {
                setState(() => _bonus = val);
              }
              Navigator.pop(ctx);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ROLAGEM DE DADOS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              setState(() => _rollHistory.clear());
            },
            tooltip: 'Limpar Histórico',
          ),
        ],
      ),
      body: Column(
        children: [
          // Área de seleção de dados
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: _selectedDice.keys.map((sides) {
                        final count = _selectedDice[sides]!;
                        return _buildDiceSelector(sides, count);
                      }).toList(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Bônus/Penalidade:', style: TextStyle(fontSize: 16, color: SteampunkTheme.copper)),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: SteampunkTheme.bloodRed),
                        onPressed: () => setState(() => _bonus--),
                      ),
                      InkWell(
                        onTap: _editBonus,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          child: Text(
                            '$_bonus',
                            style: GoogleFonts.specialElite(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                        onPressed: () => setState(() => _bonus++),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.clear),
                        label: const Text('LIMPAR'),
                        onPressed: _clearSelection,
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.casino),
                        label: const Text('ROLAR DADOS'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SteampunkTheme.copper,
                          foregroundColor: SteampunkTheme.castIron,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        onPressed: _rollDice,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: SteampunkTheme.copper),
          // Área de resultados
          Expanded(
            flex: 2,
            child: Container(
              color: SteampunkTheme.castIron,
              width: double.infinity,
              child: _rollHistory.isEmpty
                  ? Center(
                      child: Text(
                        'Nenhuma rolagem feita ainda.',
                        style: TextStyle(color: Colors.white.withOpacity(0.5)),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _rollHistory.length,
                      separatorBuilder: (context, index) => const Divider(color: Colors.white12),
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            _rollHistory[index],
                            style: GoogleFonts.specialElite(
                              fontSize: index == 0 ? 20 : 16,
                              color: index == 0 ? SteampunkTheme.copper : Colors.white70,
                              fontWeight: index == 0 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiceSelector(dynamic sides, int count) {
    final displayLabel = sides == 'CORPO' ? 'dCORPO' : 'd$sides';
    return Container(
      width: 110,
      decoration: BoxDecoration(
        color: SteampunkTheme.castIron,
        border: Border.all(color: count > 0 ? SteampunkTheme.copper : Colors.white12, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              displayLabel,
              style: GoogleFonts.cinzel(
                fontSize: sides == 'CORPO' ? 18 : 24,
                fontWeight: FontWeight.bold,
                color: count > 0 ? SteampunkTheme.copper : Colors.white54,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 16),
                  color: Colors.white70,
                  onPressed: () => _decrementDice(sides),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
                InkWell(
                  onTap: () => _editDiceCount(sides, count),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Text(
                      '$count',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 16),
                  color: Colors.white70,
                  onPressed: () => _incrementDice(sides),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
