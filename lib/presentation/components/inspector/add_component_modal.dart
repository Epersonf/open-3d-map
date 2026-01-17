import 'package:flutter/material.dart';
import '../../../domain/scene/game_component.dart';

class AddComponentModal extends StatefulWidget {
  final List<String> existingComponentIds;

  const AddComponentModal({super.key, required this.existingComponentIds});

  @override
  State<AddComponentModal> createState() => _AddComponentModalState();
}

class _AddComponentModalState extends State<AddComponentModal> {
  final TextEditingController _searchCtrl = TextEditingController();
  
  String _filter = '';
  late final Map<String, String> _availableComponents;

  @override
  void initState() {
    super.initState();
    _availableComponents = ComponentRegistry.getAvailableComponents();
  }

  @override
  Widget build(BuildContext context) {
    // Filtra componentes que já existem no objeto ou não batem com a busca
    final filtered = _availableComponents.entries.where((entry) {
      final id = entry.key;
      final name = entry.value;
      
      // Se já tem, não mostra (assumindo 1 componente por tipo)
      if (widget.existingComponentIds.contains(id)) return false;

      return id.contains(_filter.toLowerCase()) || 
             name.toLowerCase().contains(_filter.toLowerCase());
    }).toList();

    return Container(
      height: 400,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        children: [
          // Handle de arrastar
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Campo de Busca
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search, color: Colors.white54),
                hintText: 'Search component...',
                hintStyle: TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              onChanged: (val) => setState(() => _filter = val),
            ),
          ),

          const Divider(color: Colors.white10),

          // Lista
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final entry = filtered[index];
                return ListTile(
                  leading: const Icon(Icons.extension, color: Colors.blueAccent),
                  title: Text(entry.value, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(entry.key, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                  onTap: () {
                    // Retorna o ID do tipo selecionado
                    Navigator.of(context).pop(entry.key);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper para abrir o modal
Future<String?> showAddComponentModal(BuildContext context, List<String> existingIds) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => AddComponentModal(existingComponentIds: existingIds),
  );
}
