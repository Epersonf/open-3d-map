import 'package:flutter/material.dart';

class TransformInspector extends StatefulWidget {
  const TransformInspector({super.key});

  @override
  State<TransformInspector> createState() => _TransformInspectorState();
}

class _TransformInspectorState extends State<TransformInspector> {
  final TextEditingController px = TextEditingController(text: '0');
  final TextEditingController py = TextEditingController(text: '0');
  final TextEditingController pz = TextEditingController(text: '0');

  final TextEditingController rx = TextEditingController(text: '0');
  final TextEditingController ry = TextEditingController(text: '0');
  final TextEditingController rz = TextEditingController(text: '0');

  final TextEditingController sx = TextEditingController(text: '1');
  final TextEditingController sy = TextEditingController(text: '1');
  final TextEditingController sz = TextEditingController(text: '1');

  @override
  void dispose() {
    px.dispose();
    py.dispose();
    pz.dispose();
    rx.dispose();
    ry.dispose();
    rz.dispose();
    sx.dispose();
    sy.dispose();
    sz.dispose();
    super.dispose();
  }

  Widget _tripleField(String label, TextEditingController a, TextEditingController b, TextEditingController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: TextField(controller: a, decoration: const InputDecoration(labelText: 'X'))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: b, decoration: const InputDecoration(labelText: 'Y'))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: c, decoration: const InputDecoration(labelText: 'Z'))),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _tripleField('Position', px, py, pz),
          _tripleField('Rotation', rx, ry, rz),
          _tripleField('Scale', sx, sy, sz),
        ],
      ),
    );
  }
}
