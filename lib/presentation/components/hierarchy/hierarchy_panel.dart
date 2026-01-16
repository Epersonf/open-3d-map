import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../../../stores/project_store.dart';
import 'hierarchy_node.dart';

class HierarchyPanel extends StatelessWidget {
  const HierarchyPanel({super.key});

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
              onWillAccept: (_) => true,
              onAccept: (childId) {
                ProjectStore.instance.reparentObject(childId, null);
              },
              builder: (context, candidate, rejected) {
                // FIX: Usamos AnimatedBuilder para escutar o ProjectStore (ChangeNotifier).
                // Isso garante que quando o projeto for carregado (setProject), este widget reconstrua.
                return AnimatedBuilder(
                  animation: ProjectStore.instance,
                  builder: (context, _) {
                    final project = ProjectStore.instance.project;
                    
                    if (project == null || project.scenes.isEmpty) {
                      return const Center(child: Text("No Scene", style: TextStyle(color: Colors.white24)));
                    }

                    final scene = project.scenes.first;
                    
                    // Mantemos o Observer interno para escutar mudanças granulares na lista (ObservableList)
                    // caso algo mude a lista sem disparar o notifyListeners do store.
                    return Observer(
                      builder: (_) {
                        // Acessar .objects (que é ObservableList) garante a reatividade fina
                        final roots = scene.objects.where((obj) => obj.parentId == null).toList();

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
                              onReparent: ProjectStore.instance.reparentObject,
                              onCreateEmpty: (pid) => ProjectStore.instance.createEmpty(parentId: pid),
                              level: 0,
                            );
                          },
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