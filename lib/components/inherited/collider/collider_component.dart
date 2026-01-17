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
      // Se mudar o tipo, precisamos recriar a geometria
      if (oldComponent.type != type) {
        _removeVisuals(owner.parent);
        _createVisuals(owner.parent);
        return true;
      }

      // Se mudou apenas dimensões, podemos tentar atualizar ou recriar
      if (_gizmoMesh != null) {
        // Atualiza posição (Center)
        _gizmoMesh!.position.setValues(center.x, center.y, center.z);
        
        // Para simplificar a atualização de geometria, recriamos se as dimensões mudarem
        // Em uma engine real faríamos apenas scale, mas aqui garante a precisão visual
        bool dimsChanged = false;
        if (type == ColliderType.box) {
           dimsChanged = (oldComponent.size.x != size.x || 
                          oldComponent.size.y != size.y || 
                          oldComponent.size.z != size.z);
        } else if (type == ColliderType.sphere) {
           dimsChanged = (oldComponent.radius != radius);
        }

        if (dimsChanged) {
           _removeVisuals(owner.parent);
           _createVisuals(owner.parent);
        }
      } else {
        // Caso visual tenha sido perdido ou não criado (ex: Mesh collider que virou Box)
        _createVisuals(owner.parent);
      }
      return true;
    }
    return false;
  }

  // --- Visuals Logic ---

  void _createVisuals(three.Object3D parent) {
    if (type == ColliderType.mesh) return; // Mesh collider não tem preview simples

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
    if (_gizmoMesh != null) {
      _gizmoMesh!.removeFromParent();
      _gizmoMesh!.geometry?.dispose();
      _gizmoMesh!.material?.dispose();
      _gizmoMesh = null;
    } else {
      // Fallback de limpeza por nome caso a referência se perca
      for (int i = parent.children.length - 1; i >= 0; i--) {
        final child = parent.children[i];
        if (child.name == _visualName) {
          child.removeFromParent();
          (child as three.Mesh).geometry?.dispose();
        }
      }
    }
  }
}
