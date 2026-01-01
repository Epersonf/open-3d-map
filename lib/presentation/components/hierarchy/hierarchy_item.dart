import 'package:flutter/material.dart';
import '../../../domain/scene/game_object.dart';

class HierarchyItem extends StatelessWidget {
  final GameObject node;
  final int depth;

  const HierarchyItem({super.key, required this.node, this.depth = 0});

  @override
  Widget build(BuildContext context) {
    final name = node.name.isNotEmpty ? node.name : node.id;
    final children = node.children;
    if (children.isEmpty) {
      return ListTile(
        title: Text(name, style: const TextStyle(color: Colors.white)),
        dense: true,
        contentPadding: EdgeInsets.only(left: 12.0 + depth * 12.0, right: 12),
      );
    }

    return ExpansionTile(
      title: Text(name, style: const TextStyle(color: Colors.white)),
      tilePadding: EdgeInsets.only(left: 8.0 + depth * 12.0, right: 8),
      children: children.map((c) => HierarchyItem(node: c, depth: depth + 1)).toList(),
      backgroundColor: Colors.transparent,
      collapsedIconColor: Colors.white70,
      iconColor: Colors.white70,
    );
  }
}
