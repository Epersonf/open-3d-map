import 'package:flutter/material.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key});

  void _onSelected(BuildContext context, String value) {
    final messenger = ScaffoldMessenger.of(context);
    switch (value) {
      case 'new':
        messenger.showSnackBar(const SnackBar(content: Text('New project (stub)')));
        break;
      case 'open':
        messenger.showSnackBar(const SnackBar(content: Text('Open project (stub)')));
        break;
      case 'export':
        messenger.showSnackBar(const SnackBar(content: Text('Export project (stub)')));
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B1B),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          const Text(
            'O3M',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 20),
          PopupMenuButton<String>(
            onSelected: (v) => _onSelected(context, v),
            color: const Color(0xFF2A2A2A),
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'new', child: Text('New')),
              PopupMenuItem(value: 'open', child: Text('Open')),
              PopupMenuItem(value: 'export', child: Text('Export')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: const [
                  Icon(Icons.folder_open, color: Colors.white70, size: 18),
                  SizedBox(width: 8),
                  Text('Project', style: TextStyle(color: Colors.white70)),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_drop_down, color: Colors.white70),
                ],
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
