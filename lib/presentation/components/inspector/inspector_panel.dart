import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:open_3d_mapper/stores/selection_store.dart';
import 'package:open_3d_mapper/stores/project_store.dart';
import '../../../components/component_registry.dart';
import '../../../domain/scene/game_object/game_object.dart';
import 'component_section.dart';
import 'add_component_modal.dart';

class InspectorPanel extends StatefulWidget {
  const InspectorPanel({super.key});

  @override
  State<InspectorPanel> createState() => _InspectorPanelState();
}

class _InspectorPanelState extends State<InspectorPanel> {
  void _removeComponent(GameObject obj, String componentId) {
    final newComponents =
        obj.components.where((c) => c.id != componentId).toList();

    // Cria novo objeto com lista atualizada
    final updated = GameObject(
      id: obj.id,
      name: obj.name,
      parentId: obj.parentId,
      components: newComponents,
      children: obj.children,
    );

    ProjectStore.instance.updateGameObject(updated);
    SelectionStore.instance.select(updated);
  }

  void _addComponent(BuildContext context) async {
    final sel = SelectionStore.instance.selected;
    if (sel == null) return;

    final existingIds = sel.components.map((c) => c.id).toList();

    final newTypeId = await showAddComponentModal(context, existingIds);
    if (newTypeId == null) return;

    // Create via ComponentRegistry
    try {
      final newComp = ComponentRegistry.createDefault(newTypeId);
      final updated = sel.copyWithComponent(newComp);
      ProjectStore.instance.updateGameObject(updated);
      SelectionStore.instance.select(updated);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create component: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: double.infinity,
      alignment: Alignment.topCenter,
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
        border: Border(left: BorderSide(color: Colors.white10)),
      ),
      child: SingleChildScrollView(
        child: Observer(builder: (_) {
          final sel = SelectionStore.instance.selected;

          if (sel == null) {
            return const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Text('No object selected',
                  style: TextStyle(color: Colors.white24)),
            );
          }

          return Column(
            children: [
              // Lista de Componentes
              ...sel.components.map((component) {
                return ComponentSection(
                  key: ValueKey("${sel.id}_${component.id}"),
                  component: component,
                  onRemove: () => _removeComponent(sel, component.id),
                );
              }),

              const SizedBox(height: 20),

              // Botão Add Component
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _addComponent(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A2A2A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: const BorderSide(color: Colors.white12),
                      ),
                    ),
                    child: const Text('Add Component'),
                  ),
                ),
              ),

              const SizedBox(height: 40), // Bottom padding
            ],
          );
        }),
      ),
    );
  }
}
