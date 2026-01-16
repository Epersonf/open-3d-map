import 'package:flutter/material.dart';
import '../../../domain/scene/game_object.dart';
import '../../../stores/project_store.dart';
import '../../../stores/selection_store.dart';
import '../../../stores/camera_store.dart'; // Importe o CameraStore
import 'rename_modal.dart';

/// Shows a context menu for a hierarchy node at the given global position.
Future<void> showHierarchyContextMenu(BuildContext context, Offset globalPosition, GameObject node) async {
  final result = await showMenu<int>(
    context: context,
    position: RelativeRect.fromLTRB(globalPosition.dx, globalPosition.dy, globalPosition.dx, globalPosition.dy),
    items: [
      // Opção Focus adicionada no topo
      const PopupMenuItem<int>(
        value: 3,
        child: Row(
          children: [
            Icon(Icons.center_focus_strong, size: 16, color: Colors.white70),
            SizedBox(width: 8),
            Text('Focus'),
          ],
        ),
      ),
      // Duplicate option
      const PopupMenuItem<int>(
        value: 4,
        child: Row(
          children: [
            Icon(Icons.content_copy, size: 16, color: Colors.white70),
            SizedBox(width: 8),
            Text('Duplicate'),
          ],
        ),
      ),
      const PopupMenuItem<int>(
        value: 5,
        child: Row(
          children: [
            Icon(Icons.add, size: 16, color: Colors.white70),
            SizedBox(width: 8),
            Text('Create Empty Child'),
          ],
        ),
      ),
      const PopupMenuDivider(height: 1),
      const PopupMenuItem<int>(value: 1, child: Text('Rename')),
      const PopupMenuItem<int>(value: 2, child: Text('Delete', style: TextStyle(color: Colors.redAccent))),
    ],
  );

  if (result == 3) {
    // Focus Action
    SelectionStore.instance.select(node); // Garante que seleciona ao focar
    CameraStore.instance.requestFocus(node);
  } 
  else if (result == 4) {
    // Duplicate
    ProjectStore.instance.duplicateGameObject(node);
  }
  else if (result == 5) {
    // Create Empty Child
    ProjectStore.instance.createEmpty(parentId: node.id);
  }
  else if (result == 1) {
    // Rename
    final newName = await showRenameModal(context, currentName: node.name);
      if (newName != null && newName != node.name) {
        final updated = GameObject(
          id: node.id,
          name: newName,
          parentId: node.parentId,
          components: node.components, // Added components field
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