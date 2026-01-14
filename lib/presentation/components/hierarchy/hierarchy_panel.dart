import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../../../stores/project_store.dart';
import '../../../domain/scene/game_object.dart';
import 'hierarchy_node.dart';

class HierarchyPanel extends StatelessWidget {
  const HierarchyPanel({super.key});

  List<GameObject> _flatten(List<GameObject> roots) {
    final out = <GameObject>[];
    void walk(List<GameObject> list) {
      for (final g in list) {
        out.add(g);
        if (g.children.isNotEmpty) walk(g.children);
      }
    }

    walk(roots);
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      color: const Color(0xFF111111),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Hierarchy', style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: DragTarget<String>(
              onWillAccept: (data) => true,
              onAccept: (childId) {
                ProjectStore.instance.reparentObject(childId, null);
              },
              builder: (context, candidate, rejected) {
                return Observer(
                  builder: (_) {
                    final project = ProjectStore.instance.project;
                    if (project == null || project.scenes.isEmpty) {
                      return const Center(child: Text("No Scene", style: TextStyle(color: Colors.white24)));
                    }

                    final scene = project.scenes.first;

                    // Primeiro: tente usar `scene.objects` caso exista (alguns loaders
                    // populam uma lista plana chamada `objects`). Usamos acesso dinâmico
                    // para não quebrar compilação se a propriedade não existir.
                    List<GameObject> allObjects;
                    try {
                      final dyn = (scene as dynamic).objects;
                      if (dyn is List<GameObject>) {
                        allObjects = dyn;
                      } else if (dyn is List) {
                        // Tenta converter elementos que já sejam GameObject
                        allObjects = dyn.whereType<GameObject>().toList();
                      } else {
                        // Fallback para rootObjects
                        allObjects = _flatten(scene.rootObjects);
                      }
                    } catch (_) {
                      allObjects = _flatten(scene.rootObjects);
                    }

                    final roots = allObjects.where((obj) => obj.parentId == null).toList();

                    if (roots.isEmpty) {
                      return const Center(child: Text("Scene Empty", style: TextStyle(color: Colors.white24)));
                    }

                    return ListView.builder(
                      itemCount: roots.length,
                      itemBuilder: (context, index) {
                        final node = roots[index];
                        return HierarchyNode(
                          key: ValueKey(node.id),
                          node: node,
                          onReparent: (child, parent) => ProjectStore.instance.reparentObject(child, parent),
                          onCreateEmpty: (parent) => ProjectStore.instance.createEmpty(parentId: parent),
                          level: 0,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
