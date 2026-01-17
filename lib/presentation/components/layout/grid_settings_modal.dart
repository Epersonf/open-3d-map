import 'package:flutter/material.dart';
import '../../../stores/tool_store.dart';

class GridSettingsModal extends StatefulWidget {
  const GridSettingsModal({super.key});

  @override
  State<GridSettingsModal> createState() => _GridSettingsModalState();
}

class _GridSettingsModalState extends State<GridSettingsModal> {
  late TextEditingController _incrementCtrl;
  late bool _enabled;
  late bool _snapToGrid;

  @override
  void initState() {
    super.initState();
    final store = ToolStore.instance;
    _enabled = store.snapEnabled;
    _snapToGrid = store.snapToGrid;
    _incrementCtrl =
        TextEditingController(text: store.snapIncrement.toString());
  }

  @override
  void dispose() {
    _incrementCtrl.dispose();
    super.dispose();
  }

  void _apply() {
    final val = double.tryParse(_incrementCtrl.text) ?? 1.0;
    ToolStore.instance.setSnapEnabled(_enabled);
    ToolStore.instance.setSnapToGrid(_snapToGrid);
    ToolStore.instance.setSnapIncrement(val);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: const Text('Grid Snapping Settings',
          style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text('Enable Magnet',
                style: TextStyle(color: Colors.white70)),
            value: _enabled,
            activeColor: Colors.blueAccent,
            onChanged: (v) => setState(() => _enabled = v),
          ),
          const Divider(color: Colors.white24),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Increment Value',
                style: TextStyle(color: Colors.white70)),
            trailing: SizedBox(
              width: 80,
              child: TextField(
                controller: _incrementCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.all(8),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          RadioListTile<bool>(
            title: const Text('Global Grid',
                style: TextStyle(color: Colors.white70)),
            subtitle: const Text('Snap to world coordinates (0, 1, 2...)',
                style: TextStyle(color: Colors.white30, fontSize: 11)),
            value: true,
            groupValue: _snapToGrid,
            activeColor: Colors.blueAccent,
            onChanged: (v) => setState(() => _snapToGrid = v!),
          ),
          RadioListTile<bool>(
            title: const Text('Current Position',
                style: TextStyle(color: Colors.white70)),
            subtitle: const Text('Snap relative to current position',
                style: TextStyle(color: Colors.white30, fontSize: 11)),
            value: false,
            groupValue: _snapToGrid,
            activeColor: Colors.blueAccent,
            onChanged: (v) => setState(() => _snapToGrid = v!),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: _apply,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          child: const Text('Apply', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
