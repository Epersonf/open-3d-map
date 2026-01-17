import 'package:flutter/material.dart';
import '../../../components/game_component.dart';

class ComponentSection extends StatefulWidget {
  final GameComponent component;
  final VoidCallback onRemove;

  const ComponentSection({
    super.key, 
    required this.component,
    required this.onRemove,
  });

  @override
  State<ComponentSection> createState() => _ComponentSectionState();
}

class _ComponentSectionState extends State<ComponentSection> {
  bool _isExpanded = true;

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // --- Header (Clicável) ---
        Container(
          padding: const EdgeInsets.only(left: 4, right: 4, top: 4, bottom: 4),
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            border: Border(
              bottom: BorderSide(color: Colors.black, width: 1),
              top: BorderSide(color: Colors.white10, width: 1),
            ),
          ),
          width: double.infinity,
          child: Row(
            children: [
              // Área clicável para expandir/retrair
              Expanded(
                child: InkWell(
                  onTap: _toggle,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          _isExpanded ? Icons.arrow_drop_down : Icons.arrow_right,
                          color: Colors.white70,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.component.id.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Menu de 3 pontos
              SizedBox(
                width: 28,
                height: 28,
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 16, color: Colors.white54),
                  color: const Color(0xFF2A2A2A),
                  tooltip: 'Component Actions',
                  onSelected: (value) {
                    if (value == 'remove') {
                      widget.onRemove();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'reset',
                      child: Text('Reset', style: TextStyle(color: Colors.white)),
                    ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: Colors.redAccent),
                          SizedBox(width: 8),
                          Text('Remove Component', style: TextStyle(color: Colors.redAccent)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // --- Body (Inspector) ---
        if (_isExpanded)
          Container(
            color: const Color(0xFF121212),
            child: widget.component.inspectorWidget(),
          ),
      ],
    );
  }
}
