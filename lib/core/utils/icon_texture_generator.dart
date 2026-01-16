import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

class IconTextureGenerator {
  /// Gera uma Texture do ThreeJS a partir de um IconData do Flutter
  /// desenhando-o em um Canvas offscreen.
  static Future<three.Texture> createTextureFromIcon(
    IconData icon, {
    int size = 128, // Resolução da textura (quadrada)
    Color color = Colors.white,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final double sizeDouble = size.toDouble();
    canvas.translate(0, sizeDouble);
    canvas.scale(1, -1);

    // 1. Configurar o "Pincel" de texto para desenhar o ícone (que é uma fonte)
    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: sizeDouble,
        fontFamily: icon.fontFamily,
        color: color,
        package: icon.fontPackage, // Importante para ícones de pacotes externos
      ),
    );

    textPainter.layout();

    // 2. Centralizar o ícone no canvas
    final double xCenter = (sizeDouble - textPainter.width) / 2;
    final double yCenter = (sizeDouble - textPainter.height) / 2;
    final Offset offset = Offset(xCenter, yCenter);

    // 3. Desenhar
    textPainter.paint(canvas, offset);

    // 4. Converter para Imagem e depois para Bytes RGBA
    final ui.Image image = await pictureRecorder.endRecording().toImage(size, size);
    final varByteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

    if (varByteData == null) {
      throw Exception('Falha ao gerar textura do ícone');
    }

    final bytes = varByteData.buffer.asUint8List();

    // 5. Criar a DataTexture do ThreeJS
    final data = three.Uint8Array.fromList(bytes);
    final texture = three.DataTexture(
      data,
      size,
      size,
      three.RGBAFormat,
      three.UnsignedByteType,
    );
    
    // Configurações para garantir nitidez e orientação correta
    texture.needsUpdate = true;

    return texture;
  }
}