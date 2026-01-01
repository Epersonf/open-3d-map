import 'package:flutter/material.dart';
import '../../../stores/project_store.dart';
import '../../../domain/scene/game_object.dart';
import 'hierarchy_item.dart';

class HierarchyPanel extends StatelessWidget {
  const HierarchyPanel({super.key});

  List<GameObject> _getRootObjects() {
    final proj = ProjectStore.instance.project;
    if (proj == null) return [];
    if (proj.scenes.isEmpty) return [];
    final scene = proj.scenes.first;
    final ro = scene.rootObjects;
    return ro;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      color: const Color(0xFF0F0F0F),
      child: AnimatedBuilder(
        animation: ProjectStore.instance,
        builder: (ctx, _) {
          final project = ProjectStore.instance.project;
          if (project == null) return const SizedBox.shrink();
          final roots = _getRootObjects();

          return Container(
            height: double.infinity,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: 300, maxWidth: MediaQuery.of(context).size.width),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Hierarchy', style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 8),
                        for (final root in roots) HierarchyItem(node: root, depth: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
