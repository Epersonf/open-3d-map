import 'package:flutter/material.dart';

class ColorPalette extends StatelessWidget {
  final int selectedColor;
  final Function(int) onColorChanged;

  const ColorPalette(
      {required this.selectedColor, required this.onColorChanged});

  // Lista de cores predefinidas (Hex RGB)
  static const List<int> colors = [
    0xFFFFFF, // Branco
    0xFF5555, // Vermelho
    0x55FF55, // Verde
    0x5555FF, // Azul
    0xFFFF55, // Amarelo
    0xFF55FF, // Magenta
    0x55FFFF, // Ciano
    0xFFA500, // Laranja
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colors.map((color) {
        final isSelected = (selectedColor & 0xFFFFFF) == (color & 0xFFFFFF);
        return InkWell(
          onTap: () => onColorChanged(color),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Color(color | 0xFF000000), // Garante alpha 255 para UI
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                          color: Colors.white.withOpacity(0.5), blurRadius: 4)
                    ]
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}
