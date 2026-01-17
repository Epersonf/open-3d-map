import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ColorPalette extends StatefulWidget {
  final int selectedColor;
  final Function(int) onColorChanged;

  const ColorPalette({
    super.key,
    required this.selectedColor,
    required this.onColorChanged,
  });

  @override
  State<ColorPalette> createState() => _ColorPaletteState();
}

class _ColorPaletteState extends State<ColorPalette> {
  late TextEditingController _hexController;
  
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
  void initState() {
    super.initState();
    _hexController = TextEditingController(text: _formatHex(widget.selectedColor));
  }

  @override
  void didUpdateWidget(covariant ColorPalette oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Se a cor mudou externamente (ex: undo/redo), atualiza o texto
    if (oldWidget.selectedColor != widget.selectedColor) {
      // Verifica se o texto atual já não representa a cor (evita loop ao digitar)
      final currentTextVal = _parseHex(_hexController.text);
      if (currentTextVal != widget.selectedColor) {
        _hexController.text = _formatHex(widget.selectedColor);
      }
    }
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  // Converte int (0xFFRRGGBB) para string "RRGGBB"
  String _formatHex(int color) {
    return (color & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();
  }

  // Tenta converter string para int color
  int? _parseHex(String value) {
    final clean = value.replaceAll('#', '').trim();
    if (clean.length == 6) {
      try {
        return int.parse('FF$clean', radix: 16);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  void _onPresetTap(int color) {
    widget.onColorChanged(color);
    _hexController.text = _formatHex(color);
    // Remove o foco do teclado ao clicar num preset
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _onHexChanged(String value) {
    final newColor = _parseHex(value);
    if (newColor != null) {
      widget.onColorChanged(newColor);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Grid de Presets
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors.map((color) {
            final isSelected = (widget.selectedColor & 0xFFFFFF) == (color & 0xFFFFFF);
            return InkWell(
              onTap: () => _onPresetTap(color),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Color(color | 0xFF000000),
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
        ),
        
        const SizedBox(height: 12),
        
        // Input Hexadecimal
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              // Prefixo "#" visual
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  border: Border(right: BorderSide(color: Colors.white12)),
                ),
                child: const Text("#", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
              ),
              // Campo de Texto
              Expanded(
                child: TextField(
                  controller: _hexController,
                  onChanged: _onHexChanged,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    hintText: "RRGGBB",
                    hintStyle: TextStyle(color: Colors.white24),
                  ),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(6),
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]')),
                  ],
                ),
              ),
              // Preview da cor digitada/selecionada
              Container(
                width: 36,
                decoration: BoxDecoration(
                  color: Color(widget.selectedColor | 0xFF000000),
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                ),
              )
            ],
          ),
        )
      ],
    );
  }
}
