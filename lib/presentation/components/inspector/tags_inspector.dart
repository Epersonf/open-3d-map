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
  String? _currentSelectedId;
  GameObject? _currentObject;

  void _applyTags() {
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
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      final sel = SelectionStore.instance.selected;
      if (sel == null) {
        _currentSelectedId = null;
        _currentObject = null;
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
        _currentObject = sel;
        _tags.clear();
        sel.tags.forEach((k, v) => _tags.add(Tag(k, v)));
      }

      return Container(
        padding: const EdgeInsets.all(12),
        color: const Color(0xFF121212),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            
            // Current tags section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tags:',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                TextButton.icon(
                  onPressed: () => _showAddEditTagDialog(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Tag'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blueAccent,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Tags list
            if (_tags.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                alignment: Alignment.center,
                child: const Text(
                  'No tags added yet',
                  style: TextStyle(color: Colors.white54),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _tags.length,
                itemBuilder: (ctx, idx) {
                  final tag = _tags[idx];
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18, color: Colors.blueAccent),
                            onPressed: () => _showAddEditTagDialog(context, tag: tag, index: idx),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 18, color: Colors.redAccent),
                            onPressed: () => _removeTag(idx),
                          ),
                        ],
                      ),
                      onTap: () => _showAddEditTagDialog(context, tag: tag, index: idx),
                      dense: true,
                    ),
                  );
                },
              ),
          ],
        ),
      );
    });
  }

  void _showAddEditTagDialog(BuildContext context, {Tag? tag, int? index}) async {
    final isEditing = tag != null;
    final keyController = TextEditingController(text: tag?.key ?? '');
    final valueController = TextEditingController(text: tag?.value ?? '');

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(
            isEditing ? 'Edit Tag' : 'Add Tag',
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                TextField(
                  controller: keyController,
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
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Value (supports multi-line):',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: TextField(
                    controller: valueController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 6,
                    minLines: 3,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.all(12),
                      border: InputBorder.none,
                      hintText: 'Enter tag value...',
                      hintStyle: TextStyle(color: Colors.white54),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tip: Use Shift+Enter for new lines',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () {
                final key = keyController.text.trim();
                final value = valueController.text;
                if (key.isEmpty) return;
                Navigator.of(context).pop({'key': key, 'value': value});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
              ),
              child: Text(isEditing ? 'Save' : 'Add'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        if (isEditing && index != null) {
          _tags[index] = Tag(result['key']!, result['value']!);
        } else {
          _tags.add(Tag(result['key']!, result['value']!));
        }
        _applyTags();
      });
    }
  }

  void _removeTag(int idx) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Delete Tag', style: TextStyle(color: Colors.white)),
          content: Text(
            'Are you sure you want to delete tag "${_tags[idx].key}"?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _tags.removeAt(idx);
                  _applyTags();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}