import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:three_js/three_js.dart' as three;
import '../../game_component.dart';
import '../../../domain/scene/scene_context.dart';
import '../../../core/utils/icon_texture_generator.dart';
import '../../../core/utils/flutter_icons_map.dart'; // Importe o mapa
import 'icon_inspector.dart';

part 'icon_component.g.dart';

@JsonSerializable()
class IconComponent extends GameComponent {
  static const String typeId = 'icon';
  // Nome fixo para identificar o objeto visual na cena, independente da instância do componente
  static const String _spriteName = 'icon_component_visual';
  // Chave para guardar o ID da geração atual no userData do objeto pai
  static const String _genKey = 'icon_generation_id';

  @override
  String get id => typeId;

  final String iconName;

  @JsonKey(includeFromJson: false, includeToJson: false)
  three.Object3D? _sprite;

  IconComponent({this.iconName = 'spawn'});

  factory IconComponent.fromJson(Map<String, dynamic> json) => _$IconComponentFromJson(json);
  
  @override
  Map<String, dynamic> toJson() => _$IconComponentToJson(this);

  @override
  IconComponent copyWith({String? iconName}) => IconComponent(iconName: iconName ?? this.iconName);

  @override
  Widget inspectorWidget() => const IconInspector();

  @override
  void onStart(SceneContext owner) async {
    final myGenId = DateTime.now().millisecondsSinceEpoch;
    
    owner.parent.userData[_genKey] = myGenId;

    // --- MUDANÇA: Busca dinâmica no mapa estático ---
    final iconData = FlutterIconsMap.fromName(iconName);
    // ------------------------------------------------

    final texture = await IconTextureGenerator.createTextureFromIcon(
      iconData,
      size: 128,
      color: Colors.white,
    );

    final currentGenId = owner.parent.userData[_genKey];
    if (currentGenId != myGenId) {
      texture.dispose();
      return;
    }

    _removeExistingSprites(owner.parent);

    final material = three.SpriteMaterial();
    material.map = texture;
    material.color = three.Color.fromHex32(0xFFFFFF);
    material.transparent = true;
    material.alphaTest = 0.5;

    _sprite = three.Sprite(material);
    _sprite!.name = _spriteName;
    _sprite!.scale.setValues(0.5, 0.5, 0.5);
    
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
      if (oldComponent.iconName == iconName) {
        _sprite = oldComponent._sprite;
        
        if (_sprite == null) {
           onStart(owner);
        }
        return true;
      } 
      else {
        onStart(owner);
        return true;
      }
    }
    return false;
  }
}