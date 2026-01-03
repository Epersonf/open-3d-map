import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../../../domain/tag/tag.dart';
import '../../../stores/selection_store.dart';
import '../../../stores/project_store.dart';
import '../../../domain/scene/game_object.dart';

class TagsInspector extends StatefulWidget {
  const TagsInspector({super.key});

  @override
  State<TagsInspector> createState() => _TagsInspectorState();
}

class _TagsInspectorState extends State<TagsInspector> {
  final List<Tag> _tags = [];
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();

  String? _currentSelectedId;

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _addTag() {
    final k = _keyController.text.trim();
    final v = _valueController.text.trim();
    if (k.isEmpty) return;
    
    setState(() {
      _tags.add(Tag(k, v));
      _keyController.clear();
      _valueController.clear();
    });
  }

  void _removeTag(int idx) {
    setState(() => _tags.removeAt(idx));
  }

  void _applyTagsToObject() {
    final sel = SelectionStore.instance.selected;
    if (sel == null) return;

    final Map<String, String> map = {for (var t in _tags) t.key: t.value};
    final updated = GameObject(
      id: sel.id,
      name: sel.name,
      parentId: sel.parentId,
      assetId: sel.assetId,
      transform: sel.transform,
      tags: map,
      children: sel.children,
    );
    ProjectStore.instance.updateGameObject(updated);
    SelectionStore.instance.select(updated);
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tags applied successfully'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      final sel = SelectionStore.instance.selected;
      if (sel == null) {
        return Container(
          padding: const EdgeInsets.all(12),
          child: const Text(
            'No object selected',
            style: TextStyle(color: Colors.white70),
          ),
        );
      }

      // Update tags when selection changes
      if (_currentSelectedId != sel.id) {
        _currentSelectedId = sel.id;
        _tags.clear();
        sel.tags.forEach((k, v) => _tags.add(Tag(k, v)));
      }

      return SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(12),
          color: const Color(0xFF121212),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              
              // Current tags section
              if (_tags.isNotEmpty) ...[
                const Text(
                  'Current Tags:',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                ..._tags.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final tag = entry.value;
                  return Card(
                    color: const Color(0xFF1E1E1E),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(
                        tag.key,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        tag.value,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                        onPressed: () => _removeTag(idx),
                      ),
                      dense: true,
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],
              
              // Add new tag section
              const Text(
                'Add New Tag:',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 12),
              
              TextField(
                controller: _keyController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Key',
                  labelStyle: const TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white24),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.blue),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              TextField(
                controller: _valueController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Value',
                  labelStyle: const TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white24),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.blue),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Buttons row
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _addTag,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Tag'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _applyTagsToObject,
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Apply'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF388E3C),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Clear button
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    _keyController.clear();
                    _valueController.clear();
                  },
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Clear Inputs'),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
