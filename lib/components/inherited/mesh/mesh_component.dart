import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:three_js/three_js.dart' as three;
import '../../game_component.dart';
import '../../../domain/scene/scene_context.dart';
import '../../../domain/asset/asset.dart';
import 'ui/mesh_inspector.dart';

part 'mesh_component.g.dart';

@JsonSerializable()
class MeshComponent extends GameComponent {
  static const String typeId = 'mesh';

  @override
  String get id => typeId;

  final String? assetId;
  final bool visibleInRuntime;

  @JsonKey(includeFromJson: false, includeToJson: false)
  three.Object3D? _meshObject;

  // --- CORREÇÃO 1: Flag de controle de ciclo de vida ---
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool _isDisposed = false;

  MeshComponent({this.assetId, this.visibleInRuntime = true});

  factory MeshComponent.fromJson(Map<String, dynamic> json) =>
      _$MeshComponentFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$MeshComponentToJson(this);

  @override
  MeshComponent copyWith({String? assetId, bool? visibleInRuntime}) {
    return MeshComponent(
      assetId: assetId ?? this.assetId,
      visibleInRuntime: visibleInRuntime ?? this.visibleInRuntime,
    );
  }

  @override
  Widget inspectorWidget() => const MeshInspector();

  @override
  void onStart(dynamic owner) async {
    _isDisposed = false; // Reset flag ao iniciar

    // Se já temos o objeto (ex: vindo de um copyWith quente), apenas adiciona
    if (_meshObject != null) {
      if (_meshObject!.parent != owner.parent) {
        owner.parent.add(_meshObject!);
      }
      return;
    }

    if (owner is! SceneContext || assetId == null) return;

    final project = owner.projectStore.project;
    final rootPath = owner.projectStore.projectPath;
    if (project == null || rootPath == null) return;

    final asset = project.assets.firstWhere(
      (a) => a.id == assetId,
      orElse: () => Asset(id: '', path: '', type: ''),
    );

    if (asset.path.isEmpty) return;

    // Carregamento Assíncrono
    final model =
        await owner.modelManager.loadModel(assetId!, rootPath, asset.path);

    // --- CORREÇÃO 2: Verificar se fomos destruídos durante o await ---
    if (_isDisposed) {
      // Se fomos destruídos enquanto carregava, não adiciona nada à cena
      // O ModelManager mantém o cache, então não há desperdício de memória no loader
      return;
    }

    if (model != null) {
      _meshObject = model.clone(true);
      // --- CORREÇÃO 1: Tagging ---
      // Marcamos o objeto 3D com o ID deste tipo de componente.
      // Isso nos permite encontrá-lo depois, mesmo se perdermos a referência da variável _meshObject.
      try {
        _meshObject!.userData['componentType'] = typeId;
      } catch (_) {}
      _applyProperties();
      
      // Verificação dupla de segurança
      if (!_isDisposed) {
        owner.parent.add(_meshObject!);
      }
    }
  }

  @override
  bool onDidUpdate(GameComponent oldComponent, SceneContext owner) {
    if (oldComponent is MeshComponent && oldComponent.assetId == assetId) {
      _meshObject = oldComponent._meshObject;

      oldComponent._meshObject = null;

      _applyProperties();

      return true;
    }
    return false;
  }

  void _applyProperties() {
    if (_meshObject != null) {
      _meshObject!.visible = visibleInRuntime;
    }
  }

  @override
  void onDestroy(SceneContext owner) {
    // --- CORREÇÃO 3: Marcar como destruído imediatamente ---
    _isDisposed = true;

    if (_meshObject != null) {
      _meshObject!.removeFromParent();
      _meshObject = null;
      return;
    }

    // --- CORREÇÃO 2: Limpeza por Tag (Fallback) ---
    // Se _meshObject for null (porque a instância foi recriada),
    // procuramos no pai por qualquer filho que tenha a nossa tag.
    final childrenToRemove = <three.Object3D>[];

    for (final child in owner.parent.children) {
      try {
        final data = child.userData;
        if (data['componentType'] == typeId) {
          childrenToRemove.add(child);
        }
      } catch (_) {}
    }

    for (final child in childrenToRemove) {
      child.removeFromParent();
    }
  }
}
