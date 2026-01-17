import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../../../domain/scene/game_object/game_object.dart';
import '../../../stores/selection_store.dart';
import 'hierarchy_context_menu.dart';

// Callbacks for communicating with the Store
typedef ReparentCallback = void Function(String childId, String? newParentId);
typedef CreateEmptyCallback = void Function(String? parentId);

class HierarchyNode extends StatefulWidget {
  final GameObject node;
  final ReparentCallback onReparent;
  final CreateEmptyCallback onCreateEmpty;
  final int level;

  const HierarchyNode({
    super.key,
    required this.node,
    required this.onReparent,
    required this.onCreateEmpty,
    this.level = 0,
  });

  @override
  State<HierarchyNode> createState() => _HierarchyNodeState();
}

class _HierarchyNodeState extends State<HierarchyNode> {
  bool _isHovering = false;
  bool _isExpanded = true;

  bool _containsDescendant(GameObject node, String id) {
    for (final c in node.children) {
      if (c.id == id) return true;
      if (_containsDescendant(c, id)) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Observer around the entire build so changes to `widget.node.children`
    // are observed and trigger rebuilds (e.g., when children are deleted).
    return Observer(builder: (context) {
      final children = widget.node.children;
      final hasChildren = children.isNotEmpty;

      final selectedId = SelectionStore.instance.selected?.id;
      final isSelected = selectedId == widget.node.id;

      final isSpatial = widget.node.getComponentById('transform') != null;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag & Drop area (the row itself)
          DragTarget<String>(
            onWillAccept: (data) {
              if (data == null) return false;
              if (data == widget.node.id) return false;
              if (_containsDescendant(widget.node, data)) return false;
              setState(() => _isHovering = true);
              return true;
            },
            onAccept: (childId) {
              setState(() => _isHovering = false);
              widget.onReparent(childId, widget.node.id);
              setState(() => _isExpanded = true);
            },
            onLeave: (_) => setState(() => _isHovering = false),
            builder: (context, candidateData, rejectedData) {
              // use `isSelected` calculated above (at Observer scope)

              Widget content = Container(
                height: 28,
                color: _isHovering
                    ? Colors.blue.withOpacity(0.3)
                    : (isSelected
                        ? Colors.blue.withOpacity(0.2)
                        : Colors.transparent),
                padding: EdgeInsets.only(left: widget.level * 16.0),
                child: Row(
                  children: [
                    GestureDetector(
                      // Ensure the arrow area is hittable even when empty
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      child: SizedBox(
                        width: 24,
                        height: 28,
                        child: hasChildren
                            ? Icon(
                                _isExpanded
                                    ? Icons.arrow_drop_down
                                    : Icons.arrow_right,
                                size: 18,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                    ),
                    Icon(
                      isSpatial ? Icons.view_in_ar : Icons.circle_outlined,
                      size: 16,
                      color: isSpatial
                          ? Colors.blueAccent.withOpacity(0.7)
                          : Colors.white38,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.node.name,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.blue[100]
                              : (isSpatial ? Colors.white : Colors.white70),
                          fontSize: 13,
                          fontStyle:
                              isSpatial ? FontStyle.normal : FontStyle.italic,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );

              content = GestureDetector(
                // Make the whole row tappable even if background is transparent
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  SelectionStore.instance.select(widget.node);
                },
                onSecondaryTapUp: (details) {
                  // Select then open context menu
                  SelectionStore.instance.select(widget.node);
                  showHierarchyContextMenu(
                      context, details.globalPosition, widget.node);
                },
                child: content,
              );

              return Draggable<String>(
                data: widget.node.id,
                feedback: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.black54,
                    child: Text(widget.node.name,
                        style: const TextStyle(color: Colors.white)),
                  ),
                ),
                child: content,
              );
            },
          ),

          if (_isExpanded && hasChildren)
            Column(
              children: children
                  .map((child) => HierarchyNode(
                        key: ValueKey(child.id),
                        node: child,
                        onReparent: widget.onReparent,
                        onCreateEmpty: widget.onCreateEmpty,
                        level: widget.level + 1,
                      ))
                  .toList(),
            ),
        ],
      );
    });
  }
}
