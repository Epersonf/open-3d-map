import 'package:flutter/material.dart';
import '../../../../core/utils/flutter_icons_map.dart';

class IconPickerDialog extends StatefulWidget {
  final Function(String) onSelect;
  const IconPickerDialog({super.key, required this.onSelect});

  @override
  State<IconPickerDialog> createState() => _IconPickerDialogState();
}

class _IconPickerDialogState extends State<IconPickerDialog> {
  String _search = '';
  
  @override
  Widget build(BuildContext context) {
    final allKeys = FlutterIconsMap.allNames;
    final filtered = _search.isEmpty 
        ? allKeys 
        : allKeys.where((k) => k.toLowerCase().contains(_search.toLowerCase())).toList();

    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SizedBox(
        width: 500,
        height: 600,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search icon...',
                  hintStyle: TextStyle(color: Colors.white38),
                  prefixIcon: Icon(Icons.search, color: Colors.white38),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (val) => setState(() => _search = val),
              ),
            ),
            
            const Divider(height: 1, color: Colors.white10),

            Expanded(
              child: filtered.isEmpty 
              ? const Center(child: Text("No icons found", style: TextStyle(color: Colors.white54)))
              : GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 60,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final key = filtered[index];
                  final icon = FlutterIconsMap.map[key];

                  return Tooltip(
                    message: key,
                    child: InkWell(
                      onTap: () {
                        widget.onSelect(key);
                        Navigator.of(context).pop();
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Icon(icon, color: Colors.white70, size: 24),
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