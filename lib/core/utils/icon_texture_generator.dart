import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

class IconTextureGenerator {
  static Future<three.Texture> createTextureFromIcon(
    IconData icon, {
    int size = 32,
    Color color = Colors.white,
    double iconScale = .25,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final double sizeDouble = size.toDouble();

    // 1. Inverte o Canvas (Flip Y) para corrigir a orientação no ThreeJS
    canvas.translate(0, sizeDouble);
    canvas.scale(1, -1);

    // 2. Calcula o tamanho real da fonte baseado na escala desejada
    final double finalIconSize = sizeDouble * iconScale;

    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: finalIconSize, // Usamos o tamanho com escala
        fontFamily: icon.fontFamily,
        color: color,
        package: icon.fontPackage,
      ),
    );

    textPainter.layout();

    // 3. Centralizar (A lógica se mantém, mas agora com margens maiores)
    final double xCenter = (sizeDouble - textPainter.width) / 2;
    final double yCenter = (sizeDouble - textPainter.height) / 2;
    final Offset offset = Offset(xCenter, yCenter);

    textPainter.paint(canvas, offset);

    // 4. Gerar a imagem
    final ui.Image image = await pictureRecorder.endRecording().toImage(size, size);
    final varByteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

    if (varByteData == null) {
      throw Exception('Falha ao gerar textura do ícone');
    }

    final bytes = varByteData.buffer.asUint8List();

    final data = three.Uint8Array.fromList(bytes);
    final texture = three.DataTexture(
      data,
      size,
      size,
      three.RGBAFormat,
      three.UnsignedByteType,
    );

    texture.needsUpdate = true;
    texture.flipY = false; // Já invertemos manualmente no canvas

    return texture;
  }
}