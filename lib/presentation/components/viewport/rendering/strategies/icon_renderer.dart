import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import '../../../../../core/utils/icon_texture_generator.dart';
import '../../../../../domain/scene/game_object.dart';
import '../../../../../components/inherited/visual/visual_component.dart';
import '../scene_component_renderer.dart';

class IconRenderer implements SceneComponentRenderer {
  @override
  Future<three.Object3D> render(GameObject gameObject) async {
    final visual = gameObject.getComponent<VisualComponent>();
    if (visual == null) return three.Group();
    final iconName = visual.iconName;
    if (iconName == null) return three.Group();

    // 1. Mapeamento de String -> IconData
    IconData iconData = Icons.help_outline;

    switch (iconName) {
      case 'light':
        iconData = Icons.lightbulb;
        break;
      case 'camera':
        iconData = Icons.videocam;
        break;
      case 'spawn':
        iconData = Icons.flag;
        break;
      case 'enemy':
        iconData = Icons.bug_report;
        break;
    }

    // 2. Gerar textura (Preenche 95% do canvas para alta resolução)
    final texture = await IconTextureGenerator.createTextureFromIcon(
      iconData,
      size: 128,
      color: Colors.white,
    );

    final material = three.SpriteMaterial();
    material.map = texture;
    material.color = three.Color.fromHex32(0xFFFFFF);
    material.transparent = true;
    material.alphaTest = 0.5;

    final sprite = three.Sprite(material);
    // Aplica a escala visual interna
    sprite.scale.setValues(.25, .25, .25);

    // Embrulha em Group para isolar transform do objeto
    final group = three.Group();
    group.add(sprite);

    return group;
  }
}
