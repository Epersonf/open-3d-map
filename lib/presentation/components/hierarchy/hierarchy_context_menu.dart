import 'package:flutter/material.dart';
import '../../../domain/scene/game_object.dart';
import '../../../stores/project_store.dart';
import '../../../stores/selection_store.dart';

/// Shows a context menu for a hierarchy node at the given global position.
Future<void> showHierarchyContextMenu(BuildContext context, Offset globalPosition, GameObject node) async {
  final result = await showMenu<int>(
    context: context,
    position: RelativeRect.fromLTRB(globalPosition.dx, globalPosition.dy, globalPosition.dx, globalPosition.dy),
    items: [
      const PopupMenuItem<int>(value: 1, child: Text('Delete', style: TextStyle(color: Colors.redAccent))),
    ],
  );

  if (result == 1) {
    // if deleted, clear selection when appropriate
    final sel = SelectionStore.instance.selected;
    if (sel != null && sel.id == node.id) SelectionStore.instance.clear();
    ProjectStore.instance.deleteGameObject(node.id);
  }
}
