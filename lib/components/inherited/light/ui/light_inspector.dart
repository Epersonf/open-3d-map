import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../../../../stores/selection_store.dart';
import '../../../../stores/project_store.dart';
import '../light_component.dart';
import '../light_enums.dart';
import '../../icon/ui/color_palette.dart';

class LightInspector extends StatelessWidget {
  const LightInspector({super.key});

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      final sel = SelectionStore.instance.selected;
      if (sel == null) return const SizedBox.shrink();

      final light = sel.getComponent<LightComponent>();
      if (light == null) return const Text('No Light Component');

      void update({
        LightType? type,
        int? color,
        double? intensity,
        double? range,
        double? angle,
        double? penumbra,
        double? width,
        double? height,
      }) {
        final updated = sel.copyWithComponent(light.copyWith(
          type: type,
          color: color,
          intensity: intensity,
          range: range,
          spotAngle: angle,
          spotPenumbra: penumbra,
          areaWidth: width,
          areaHeight: height,
        ));
        ProjectStore.instance.updateGameObject(updated);
        SelectionStore.instance.select(updated);
      }

      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Type', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white24),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<LightType>(
                  value: light.type,
                  dropdownColor: const Color(0xFF2A2A2A),
                  isExpanded: true,
                  style: const TextStyle(color: Colors.white),
                  items: LightType.values.map((t) {
                    return DropdownMenuItem(
                      value: t,
                      child: Text(t.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) update(type: val);
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Divider(color: Colors.white10),
            const Text('Color', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            ColorPalette(
              selectedColor: light.color,
              onColorChanged: (c) => update(color: c),
            ),
            const SizedBox(height: 16),
            _buildSlider(context, 'Intensity', light.intensity, 0, 10,
                (v) => update(intensity: v)),

            if (light.type == LightType.point || light.type == LightType.spot)
              _buildSlider(context, 'Range', light.range, 0.1, 50,
                  (v) => update(range: v)),

            if (light.type == LightType.spot) ...[
              _buildSlider(context, 'Spot Angle', light.spotAngle, 1, 179,
                  (v) => update(angle: v)),
              _buildSlider(context, 'Penumbra', light.spotPenumbra, 0, 1,
                  (v) => update(penumbra: v)),
            ],

            if (light.type == LightType.area) ...[
              _buildSlider(context, 'Width', light.areaWidth, 0.1, 20,
                  (v) => update(width: v)),
              _buildSlider(context, 'Height', light.areaHeight, 0.1, 20,
                  (v) => update(height: v)),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildSlider(BuildContext context, String label, double value, double min, double max, Function(double) onChanged) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text(value.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
        SizedBox(
          height: 30,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.amber,
              inactiveTrackColor: Colors.white10,
              thumbColor: Colors.white,
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
