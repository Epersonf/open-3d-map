import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:three_js/three_js.dart' as three;
import '../../game_component.dart';
import '../../../domain/scene/scene_context.dart';
import '../../../domain/general/vec3.dart';
import 'collider_enums.dart';
import 'ui/collider_inspector.dart';

part 'collider_component.g.dart';

@JsonSerializable(explicitToJson: true)
class ColliderComponent extends GameComponent {
  static const String typeId = 'collider';
  static const String _visualName = 'collider_gizmo_visual';

  @override
  String get id => typeId;

  final ColliderType type;
  
  // Propriedades comuns
  final Vec3 center;
  final bool isTrigger;

  // Box
  final Vec3 size;

  // Sphere
  final double radius;

  // Mesh (Referência opcional para asset específico, ou usa o do MeshComponent)
  final bool convex;

  @JsonKey(includeFromJson: false, includeToJson: false)
  three.Object3D? _gizmoMesh;

  ColliderComponent({
    this.type = ColliderType.box,
    required this.center,
    required this.size,
    this.radius = 0.5,
    this.isTrigger = false,
    this.convex = true,
  });

  factory ColliderComponent.createDefault() {
    return ColliderComponent(
      type: ColliderType.box,
      center: Vec3(x: 0, y: 0, z: 0),
      size: Vec3(x: 1, y: 1, z: 1),
      radius: 0.5,
    );
  }

  factory ColliderComponent.fromJson(Map<String, dynamic> json) =>
      _$ColliderComponentFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ColliderComponentToJson(this);

  @override
  ColliderComponent copyWith({
    ColliderType? type,
    Vec3? center,
    Vec3? size,
    double? radius,
    bool? isTrigger,
    bool? convex,
  }) {
    return ColliderComponent(
      type: type ?? this.type,
      center: center ?? this.center,
      size: size ?? this.size,
      radius: radius ?? this.radius,
      isTrigger: isTrigger ?? this.isTrigger,
      convex: convex ?? this.convex,
    );
  }

  @override
  Widget inspectorWidget() => const ColliderInspector();

  @override
  void onStart(SceneContext owner) {
    _createVisuals(owner.parent);
  }

  @override
  void onDestroy(SceneContext owner) {
    _removeVisuals(owner.parent);
  }

  @override
  bool onDidUpdate(GameComponent oldComponent, SceneContext owner) {
    if (oldComponent is ColliderComponent) {
      // 1. CRUCIAL: Herdar a referência do objeto 3D do componente antigo.
      // Como 'this' é uma nova instância, _gizmoMesh começa nulo.
      _gizmoMesh = oldComponent._gizmoMesh;

      // Opcional: Anular a referência no antigo para evitar que ele tente destruir
      // algo que agora pertence a nós, caso o lifecycle chame algo estranho.
      oldComponent._gizmoMesh = null;

      // 2. Se mudou o tipo (Box <-> Sphere), destroi tudo e recria do zero.
      if (oldComponent.type != type) {
        _removeVisuals(owner.parent);
        _createVisuals(owner.parent);
        return true;
      }

      // 3. Verifica se as dimensões mudaram
      bool dimsChanged = false;
      if (type == ColliderType.box) {
        dimsChanged = (oldComponent.size.x != size.x ||
            oldComponent.size.y != size.y ||
            oldComponent.size.z != size.z);
      } else if (type == ColliderType.sphere) {
        dimsChanged = (oldComponent.radius != radius);
      }

      // Verifica se a posição (offset) mudou
      bool centerChanged = (oldComponent.center.x != center.x ||
          oldComponent.center.y != center.y ||
          oldComponent.center.z != center.z);

      if (_gizmoMesh != null) {
        // Atualiza posição se necessário
        if (centerChanged) {
          _gizmoMesh!.position.setValues(center.x, center.y, center.z);
        }

        // Se as dimensões mudaram, o jeito mais limpo no ThreeJS
        // para geometrias primitivas é recriar o mesh
        if (dimsChanged) {
          _removeVisuals(owner.parent);
          _createVisuals(owner.parent);
        }
      } else {
        // Se por algum motivo não herdamos um mesh (ex: bug anterior), forçamos uma limpeza e criação
        _removeVisuals(owner.parent); // Garante limpeza de lixo órfão por nome
        _createVisuals(owner.parent);
      }

      return true;
    }

    return false;
  }

  // --- Visuals Logic ---

  void _createVisuals(three.Object3D parent) {
    three.BufferGeometry? geometry;

    if (type == ColliderType.box) {
      geometry = three.BoxGeometry(size.x, size.y, size.z);
    } else if (type == ColliderType.sphere) {
      // SphereGeometry(radius, widthSegments, heightSegments)
      geometry = three.SphereGeometry(radius, 16, 12);
    }

    if (geometry != null) {
      // Material verde estilo Unity (Wireframe)
      final material = three.MeshBasicMaterial();
      material.color = three.Color.fromHex32(0x00FF00); // Verde brilhante
      material.wireframe = true;
      
      // Opcional: transparent para não poluir muito
      // material.transparent = true;
      // material.opacity = 0.5;

      _gizmoMesh = three.Mesh(geometry, material);
      _gizmoMesh!.name = _visualName;
      
      // Aplica o offset (center)
      _gizmoMesh!.position.setValues(center.x, center.y, center.z);
      
      // Garante que não participe de Raycasting de seleção (opcional, depende da sua lógica)
      _gizmoMesh!.userData['ignoreRaycast'] = true; 

      parent.add(_gizmoMesh!);
    }
  }

  void _removeVisuals(three.Object3D parent) {
    // 1. Tenta remover pela referência direta
    if (_gizmoMesh != null) {
      _gizmoMesh!.removeFromParent();
      _gizmoMesh!.geometry?.dispose();
      _gizmoMesh!.material?.dispose();
      _gizmoMesh = null;
    }

    // 2. BUSCA DE SEGURANÇA:
    // Remove qualquer filho que tenha o nome do gizmo visual deste componente.
    // Isso resolve o problema de "fantasmas" que ficaram na cena se a referência foi perdida.
    final List<three.Object3D> toRemove = [];
    for (final child in parent.children) {
      if (child.name == _visualName) {
        toRemove.add(child);
      }
    }

    for (final child in toRemove) {
      child.removeFromParent();
      if (child is three.Mesh) {
        child.geometry?.dispose();
        child.material?.dispose();
      }
    }
  }
}
