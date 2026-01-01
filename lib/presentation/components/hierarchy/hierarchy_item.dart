import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../../../domain/scene/game_object.dart';
import '../../../stores/selection_store.dart';

class HierarchyItem extends StatelessWidget {
  final GameObject node;
  final int depth;

  const HierarchyItem({super.key, required this.node, this.depth = 0});

  @override
  Widget build(BuildContext context) {
    final name = node.name.isNotEmpty ? node.name : node.id;
    final children = node.children;
    if (children.isEmpty) {
      return Observer(builder: (_) {
        final selected = SelectionStore.instance.selected;
        final isSelected = selected != null && selected.id == node.id;
        return ListTile(
          title: Text(name, style: TextStyle(color: isSelected ? Colors.blue[200] : Colors.white)),
          dense: true,
          selected: isSelected,
          tileColor: isSelected ? Colors.blue.withOpacity(0.12) : Colors.transparent,
          contentPadding: EdgeInsets.only(left: 12.0 + depth * 12.0, right: 12),
          onTap: () => SelectionStore.instance.select(node),
        );
      });
    }

    return Observer(builder: (_) {
      final selected = SelectionStore.instance.selected;
      final isSelected = selected != null && selected.id == node.id;
      return ExpansionTile(
        title: Container(
          color: isSelected ? Colors.blue.withOpacity(0.12) : Colors.transparent,
          padding: EdgeInsets.only(left: 0),
          child: Text(name, style: TextStyle(color: isSelected ? Colors.blue[200] : Colors.white)),
        ),
        tilePadding: EdgeInsets.only(left: 8.0 + depth * 12.0, right: 8),
        children: children.map((c) => HierarchyItem(node: c, depth: depth + 1)).toList(),
        backgroundColor: Colors.transparent,
        collapsedIconColor: Colors.white70,
        iconColor: Colors.white70,
        onExpansionChanged: (_) {},
        key: Key(node.id),
        // tap to select this node
        childrenPadding: EdgeInsets.zero,
      );
    });
  }
}
