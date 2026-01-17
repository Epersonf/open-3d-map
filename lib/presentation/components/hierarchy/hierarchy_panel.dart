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
          // --- Header com Botão de Adicionar ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hierarchy',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 20, color: Colors.white70),
                  tooltip: 'Create Empty Object',
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    // Cria um objeto vazio na raiz (parentId: null)
                    ProjectStore.instance.createEmpty();
                  },
                ),
              ],
            ),
          ),
          
          // --- Lista de Objetos ---
          Expanded(
            child: DragTarget<String>(
              onWillAccept: (_) => true,
              onAccept: (childId) {
                // Arrastar para o fundo do painel move para a raiz
                ProjectStore.instance.reparentObject(childId, null);
              },
              builder: (context, candidate, rejected) {
                return AnimatedBuilder(
                  animation: ProjectStore.instance,
                  builder: (context, _) {
                    final project = ProjectStore.instance.project;
                    
                    if (project == null || project.scenes.isEmpty) {
                      return const Center(child: Text("No Scene", style: TextStyle(color: Colors.white24)));
                    }

                    final scene = project.scenes.first;
                    
                    return Observer(
                      builder: (_) {
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