import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:open_3d_mapper/presentation/components/inspector/tag_modal.dart';
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
                  onPressed: () => _openTagModal(context),
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
                            onPressed: () => _openTagModal(context, tag: tag, index: idx),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 18, color: Colors.redAccent),
                            onPressed: () => _removeTag(idx),
                          ),
                        ],
                      ),
                      onTap: () => _openTagModal(context, tag: tag, index: idx),
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

  Future<void> _openTagModal(BuildContext context, {Tag? tag, int? index}) async {
    final result = await showTagModal(context, tag: tag);
    if (result != null) {
      setState(() {
        if (tag != null && index != null) {
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