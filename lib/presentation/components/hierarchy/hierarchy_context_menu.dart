import 'package:flutter/material.dart';
import '../../../domain/scene/game_object.dart';
import '../../../stores/project_store.dart';
import '../../../stores/selection_store.dart';
import 'rename_modal.dart';

/// Shows a context menu for a hierarchy node at the given global position.
Future<void> showHierarchyContextMenu(BuildContext context, Offset globalPosition, GameObject node) async {
  final result = await showMenu<int>(
    context: context,
    position: RelativeRect.fromLTRB(globalPosition.dx, globalPosition.dy, globalPosition.dx, globalPosition.dy),
    items: [
      const PopupMenuItem<int>(value: 1, child: Text('Rename')),
      const PopupMenuItem<int>(value: 2, child: Text('Delete', style: TextStyle(color: Colors.redAccent))),
    ],
  );

  if (result == 1) {
    // Rename
    final newName = await showRenameModal(context, currentName: node.name);
    if (newName != null && newName != node.name) {
      final updated = GameObject(
        id: node.id,
        name: newName,
        parentId: node.parentId,
        assetId: node.assetId,
        transform: node.transform,
        tags: node.tags,
        children: node.children,
      );
      ProjectStore.instance.updateGameObject(updated);
      // If the renamed object is currently selected, update the selection to reflect the new name
      final sel = SelectionStore.instance.selected;
      if (sel != null && sel.id == node.id) {
        SelectionStore.instance.select(updated);
      }
    }
  } else if (result == 2) {
    // Delete
    // if deleted, clear selection when appropriate
    final sel = SelectionStore.instance.selected;
    if (sel != null && sel.id == node.id) SelectionStore.instance.clear();
    ProjectStore.instance.deleteGameObject(node.id);
  }
}