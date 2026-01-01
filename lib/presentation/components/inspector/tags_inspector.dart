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
    final v = _valueController.text;
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

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      final sel = SelectionStore.instance.selected;
      if (sel == null) {
        return Container(padding: const EdgeInsets.all(12), child: const Text('No selection', style: TextStyle(color: Colors.white70)));
      }

      if (_currentSelectedId != sel.id) {
        _currentSelectedId = sel.id;
        _tags.clear();
        sel.tags.forEach((k, v) => _tags.add(Tag(k, v)));
      }

      return Container(
        padding: const EdgeInsets.all(12),
        color: const Color(0xFF121212),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tags', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            for (var i = 0; i < _tags.length; i++)
              Card(
                child: ListTile(
                  title: Text(_tags[i].key, style: const TextStyle(color: Colors.white)),
                  subtitle: SelectableText(_tags[i].value, style: const TextStyle(color: Colors.white70)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _removeTag(i),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            TextField(controller: _keyController, decoration: const InputDecoration(labelText: 'Key')),
            const SizedBox(height: 8),
            TextField(
              controller: _valueController,
              decoration: const InputDecoration(labelText: 'Value (multiline supported)'),
              maxLines: 6,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(onPressed: _addTag, child: const Text('Add Tag')),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    // apply tags to selected object
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
                  },
                  child: const Text('Apply Tags'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    _keyController.clear();
                    _valueController.clear();
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}
