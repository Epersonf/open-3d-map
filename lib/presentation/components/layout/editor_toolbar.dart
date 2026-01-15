import 'package:flutter/material.dart';
import '../../../stores/tool_store.dart';
import 'grid_settings_modal.dart';

class EditorToolbar extends StatelessWidget {
  const EditorToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: const Color(0xFF252525),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          _ToolButton(
            icon: Icons.open_with,
            mode: GizmoMode.translate,
            tooltip: 'Move (W)',
          ),
          const SizedBox(width: 4),
          _ToolButton(
            icon: Icons.aspect_ratio,
            mode: GizmoMode.scale,
            tooltip: 'Scale (E)',
          ),
          const SizedBox(width: 4),
          _ToolButton(
            icon: Icons.refresh,
            mode: GizmoMode.rotate,
            tooltip: 'Rotate (R)',
          ),
          const VerticalDivider(color: Colors.white24, indent: 8, endIndent: 8),

          // --- NOVO BOTÃO DE ESPAÇO ---
          _SpaceToggleButton(),
          const SizedBox(width: 8),
          // --- Magnet / Grid Button ---
          _MagnetButton(),
        ],
      ),
    );
  }
}

class _MagnetButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ToolStore.instance,
      builder: (context, _) {
        final enabled = ToolStore.instance.snapEnabled;
        return IconButton(
          icon: Icon(Icons.grid_4x4, size: 20, color: enabled ? Colors.blueAccent : Colors.white54),
          tooltip: 'Snap Settings',
          style: IconButton.styleFrom(
            backgroundColor: enabled ? Colors.blue.withOpacity(0.2) : null,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => const GridSettingsModal(),
            );
          },
        );
      },
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final GizmoMode mode;
  final String tooltip;

  const _ToolButton({
    required this.icon,
    required this.mode,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ToolStore.instance,
      builder: (context, _) {
        final isActive = ToolStore.instance.activeMode == mode;
        return IconButton(
          icon: Icon(icon, size: 20),
          tooltip: tooltip,
          color: isActive ? Colors.blueAccent : Colors.white54,
          style: IconButton.styleFrom(
            backgroundColor: isActive ? Colors.blue.withOpacity(0.2) : null,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
          onPressed: () => ToolStore.instance.setMode(mode),
        );
      },
    );
  }
}

// --- WIDGET DO BOTÃO LOCAL/GLOBAL ---
class _SpaceToggleButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ToolStore.instance,
      builder: (context, _) {
        final isLocal = ToolStore.instance.transformSpace == TransformSpace.local;
        return TextButton.icon(
          onPressed: () => ToolStore.instance.toggleTransformSpace(),
          icon: Icon(
            isLocal ? Icons.my_location : Icons.public,
            size: 16,
            color: Colors.white70,
          ),
          label: Text(
            isLocal ? 'Local' : 'Global',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          style: TextButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.05),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        );
      },
    );
  }
}
