import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:three_js/three_js.dart' as three;
import '../../game_component.dart';
import '../../../domain/scene/scene_context.dart';
import '../../../core/utils/icon_texture_generator.dart';
import '../../../core/utils/flutter_icons_map.dart';
import 'ui/icon_inspector.dart';

part 'icon_component.g.dart';

@JsonSerializable()
class IconComponent extends GameComponent {
  static const String typeId = 'icon';
  static const String _spriteName = 'icon_component_visual';
  static const String _genKey = 'icon_generation_id';

  @override
  String get id => typeId;

  final String iconName;
  // Nova propriedade de tamanho
  final double iconSize;
  // 1. Nova propriedade de Cor (Armazenamos como int 0xRRGGBB para compatibilidade fácil)
  final int color; 

  @JsonKey(includeFromJson: false, includeToJson: false)
  three.Object3D? _sprite;

  IconComponent({
    this.iconName = 'spawn',
    this.iconSize = 0.5, // Valor padrão
    this.color = 0xFFFFFF,
  });

  factory IconComponent.fromJson(Map<String, dynamic> json) =>
      _$IconComponentFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$IconComponentToJson(this);

  @override
  IconComponent copyWith({String? iconName, double? iconSize, int? color}) {
    return IconComponent(
      iconName: iconName ?? this.iconName,
      iconSize: iconSize ?? this.iconSize,
      color: color ?? this.color,
    );
  }

  @override
  Widget inspectorWidget() => const IconInspector();

  @override
  void onStart(SceneContext owner) async {
    final myGenId = DateTime.now().millisecondsSinceEpoch;
    owner.parent.userData[_genKey] = myGenId;

    final iconData = FlutterIconsMap.fromName(iconName);

    final texture = await IconTextureGenerator.createTextureFromIcon(
      iconData,
      size: 128,
      color: Colors.white,
    );

    if (owner.parent.userData[_genKey] != myGenId) {
      texture.dispose();
      return;
    }

    _removeExistingSprites(owner.parent);

    final material = three.SpriteMaterial();
    material.map = texture;
    // 2. Aplica a cor inicial ao material (ThreeJS usa formato RGB inteiro)
    // O '& 0xFFFFFF' garante que removemos o canal Alpha se vier do Flutter Color.value
    material.color.setFromHex32(color & 0xFFFFFF);
    material.transparent = true;
    material.alphaTest = 0.5;

    _sprite = three.Sprite(material);
    _sprite!.name = _spriteName;

    // Aplica o tamanho inicial
    _sprite!.scale.setValues(iconSize, iconSize, iconSize);

    owner.parent.add(_sprite!);
  }

  void _removeExistingSprites(three.Object3D parent) {
    for (int i = parent.children.length - 1; i >= 0; i--) {
      final child = parent.children[i];
      if (child.name == _spriteName) {
        child.removeFromParent();
      }
    }
  }

  @override
  void onDestroy(SceneContext owner) {
    owner.parent.userData[_genKey] = -1;
    _removeExistingSprites(owner.parent);
    _sprite = null;
  }

  @override
  bool onDidUpdate(GameComponent oldComponent, SceneContext owner) {
    if (oldComponent is IconComponent) {
      // Se mudou o nome, recria tudo
      if (oldComponent.iconName != iconName) {
        onStart(owner);
        return true;
      }

      // Atualizações leves (Propriedades do Sprite)
      _sprite = oldComponent._sprite;
      
      if (_sprite != null) {
        // Atualiza Tamanho
        if (oldComponent.iconSize != iconSize) {
          _sprite!.scale.setValues(iconSize, iconSize, iconSize);
        }
        
        // 3. Atualiza Cor em tempo real (Lerp visual instantâneo)
        if (oldComponent.color != color) {
          final mat = _sprite!.material as three.SpriteMaterial;
          mat.color.setFromHex32(color & 0xFFFFFF);
        }
      } else {
        onStart(owner);
      }
      return true;
    }
    return false;
  }
}
