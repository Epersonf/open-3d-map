import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../../../stores/project_store.dart';
import '../../../domain/scene/scene.dart';
import 'hierarchy_node.dart';
import 'rename_modal.dart';

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
          // --- Scene Selector & Actions ---
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white10)),
              color: Color(0xFF1A1A1A),
            ),
            child: Row(
              children: [
                Expanded(
                  child: AnimatedBuilder(
                    animation: ProjectStore.instance,
                    builder: (context, _) {
                      final project = ProjectStore.instance.project;
                      final currentScene = ProjectStore.instance.currentScene;
                      
                      if (project == null || currentScene == null) {
                        return const Text("No Scene", style: TextStyle(color: Colors.white54));
                      }

                      return DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: currentScene.id,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF2A2A2A),
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                          style: const TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.bold,
                            fontSize: 14
                          ),
                          items: project.scenes.map((Scene s) {
                            return DropdownMenuItem<String>(
                              value: s.id,
                              child: Text(s.name, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (newId) {
                            if (newId != null) {
                              ProjectStore.instance.selectScene(newId);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
                // Scene Actions Menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20, color: Colors.white70),
                  tooltip: 'Scene Options',
                  color: const Color(0xFF2A2A2A),
                  onSelected: (value) async {
                    if (value == 'new') {
                      ProjectStore.instance.createScene();
                    } else if (value == 'duplicate') {
                      final current = ProjectStore.instance.currentScene;
                      if (current != null) ProjectStore.instance.duplicateScene(current.id);
                    } else if (value == 'rename') {
                      final current = ProjectStore.instance.currentScene;
                      if (current != null) {
                         final newName = await showRenameModal(context, currentName: current.name);
                         if (newName != null && newName.isNotEmpty) {
                           ProjectStore.instance.renameScene(current.id, newName);
                         }
                      }
                    } else if (value == 'delete') {
                      final current = ProjectStore.instance.currentScene;
                      if (current != null) {
                         // Confirmation Dialog could be added here
                         ProjectStore.instance.deleteScene(current.id);
                      }
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'new',
                      child: Row(
                        children: [
                           Icon(Icons.add, size: 16, color: Colors.white70),
                           SizedBox(width: 8),
                           Text("New Scene", style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                           Icon(Icons.copy, size: 16, color: Colors.white70),
                           SizedBox(width: 8),
                           Text("Duplicate", style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'rename',
                      child: Row(
                        children: [
                           Icon(Icons.edit, size: 16, color: Colors.white70),
                           SizedBox(width: 8),
                           Text("Rename", style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                           Icon(Icons.delete, size: 16, color: Colors.redAccent),
                           SizedBox(width: 8),
                           Text("Delete", style: TextStyle(color: Colors.redAccent)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // --- Quick Add Object Button ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            color: const Color(0xFF161616),
            child: Row(
               children: [
                 const Text("Hierarchy", style: TextStyle(color: Colors.white38, fontSize: 10)),
                 const Spacer(),
                 IconButton(
                  icon: const Icon(Icons.add, size: 18, color: Colors.white70),
                  tooltip: 'Create Empty Object',
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    // Cria um objeto vazio na raiz (parentId: null) da cena atual
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
                    final currentScene = ProjectStore.instance.currentScene;

                    if (project == null || currentScene == null) {
                      return const Center(
                          child: Text("No Scene",
                              style: TextStyle(color: Colors.white24)));
                    }

                    return Observer(
                      builder: (_) {
                        // Filtra apenas os objetos da cena atual
                        final roots = currentScene.rootObjects
                            .where((obj) => obj.parentId == null)
                            .toList();

                        if (roots.isEmpty) {
                          return const Center(
                              child: Text("Scene Empty",
                                  style: TextStyle(color: Colors.white24)));
                        }

                        return ListView.builder(
                          itemCount: roots.length,
                          itemBuilder: (context, index) {
                            final node = roots[index];
                            return HierarchyNode(
                              key: ValueKey(node.id),
                              node: node,
                              onReparent: ProjectStore.instance.reparentObject,
                              onCreateEmpty: (pid) => ProjectStore.instance
                                  .createEmpty(parentId: pid),
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