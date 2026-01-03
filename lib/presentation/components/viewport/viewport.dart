import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart' hide Listener;
import 'package:open_3d_mapper/presentation/components/viewport/free_camera_controller.dart';
import 'package:three_js/three_js.dart' as three;
import '../../../stores/project_store.dart';
import '../../../stores/selection_store.dart';
import '../../../domain/scene/game_object.dart';
import '../../../domain/asset/asset.dart';
import 'controllers/selection_controller.dart';
import 'managers/scene_manager.dart';
import 'managers/model_manager.dart';
import 'objects/scene_object.dart';

class Viewport3D extends StatefulWidget {
  const Viewport3D({super.key});

  @override
  State<Viewport3D> createState() => _Viewport3DState();
}

class _Viewport3DState extends State<Viewport3D> {
  late three.ThreeJS threeJs;
  late FreeCameraController freeCam;
  late SceneManager sceneManager;
  late ModelManager modelManager;
  SelectionController? selectionController;
  
  VoidCallback? _projectListener;
  ReactionDisposer? _selectionDisposer;
  final GlobalKey _viewportKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    threeJs = three.ThreeJS(
      setup: setupScene,
      onSetupComplete: _onThreeJsReady,
    );

    freeCam = FreeCameraController(threeJs);
    
    // Inicializar gerenciadores que não dependem da cena
    modelManager = ModelManager();

    // Scene-dependent managers will be created once ThreeJS setup completes
    // via [_onThreeJsReady]. This avoids accessing `threeJs.scene` before
    // it has been initialized by the ThreeJS runtime.
  }

  @override
  void dispose() {
    if (_projectListener != null) {
      ProjectStore.instance.removeListener(_projectListener!);
      _projectListener = null;
    }
    if (_selectionDisposer != null) {
      _selectionDisposer!();
      _selectionDisposer = null;
    }
    freeCam.dispose();
    threeJs.dispose();
    three.loading.clear();
    modelManager.clear();
    sceneManager.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: freeCam.onKey,
        child: GestureDetector(
        onTapDown: (details) => selectionController?.onTapDown(details, _viewportKey.currentContext!),
        child: Listener(
          onPointerDown: freeCam.onPointerDown,
          onPointerUp: freeCam.onPointerUp,
          onPointerMove: (event) {
            freeCam.onPointerMove(event);
            selectionController?.onPointerMove(event, _viewportKey.currentContext!);
          },
          child: SizedBox.expand(
            key: _viewportKey,
            child: threeJs.build(),
          ),
        ),
      ),
    );
  }

  Future<void> setupScene() async {
    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32(0x202020);

    threeJs.camera = three.PerspectiveCamera(
      60,
      threeJs.width / threeJs.height,
      0.1,
      2000,
    );

    threeJs.camera.rotation.order = three.RotationOrders.yxz;
    threeJs.camera.position.setValues(0, 2, 8);

    threeJs.scene.add(three.AmbientLight(0xffffff, 0.6));

    final dir = three.DirectionalLight(0xffffff, 1);
    dir.position.setValues(5, 10, 5);
    threeJs.scene.add(dir);
    // Scene is ready; final synchronization will be triggered from
    // [_onThreeJsReady] once the ThreeJS setup completes.
  }

  void _onThreeJsReady() {
    // Now that threeJs.scene is initialized, create scene-dependent managers
    sceneManager = SceneManager(
      scene: threeJs.scene,
      modelManager: modelManager,
    );

    selectionController = SelectionController(
      threeJs: threeJs,
      sceneManager: sceneManager,
    );

    // Ouvir mudanças no projeto
    _projectListener = updateSceneFromProject;
    ProjectStore.instance.addListener(_projectListener!);

    // Ouvir mudanças na seleção
    _setupSelectionListener();

    // Populate scene from project now that sceneManager exists
    updateSceneFromProject();
  }

  Future<void> updateSceneFromProject() async {
    final project = ProjectStore.instance.project;
    if (project == null || project.scenes.isEmpty) {
      sceneManager.clear();
      return;
    }

    final scene = project.scenes.first;
    
    for (final rootObject in scene.rootObjects) {
      await _processGameObject(rootObject, null);
    }

    // Remover objetos que não existem mais no projeto
    final projectObjectIds = _getAllGameObjectIds(scene.rootObjects);
    final currentObjectIds = sceneManager.sceneObjects.keys.toSet();
    final objectsToRemove = currentObjectIds.difference(projectObjectIds);
    
    for (final id in objectsToRemove) {
      sceneManager.removeSceneObject(id);
    }
  }

  Future<void> _processGameObject(GameObject gameObject, String? parentId) async {
    // Verificar se o objeto já existe
    var sceneObject = sceneManager.getSceneObject(gameObject.id);
    
    if (sceneObject == null) {
      // Criar novo objeto
      sceneObject = await _createSceneObject(gameObject);
      if (sceneObject != null) {
        final parent = parentId != null ? sceneManager.getSceneObject(parentId)?.object3d : null;
        sceneManager.addSceneObject(sceneObject, parent: parent);
      }
    } else {
      // Atualizar objeto existente
      sceneObject.gameObject = gameObject;
      sceneManager.updateSceneObject(gameObject);
    }

    // Processar filhos recursivamente
    for (final child in gameObject.children) {
      await _processGameObject(child, gameObject.id);
    }
  }

  Future<SceneObject?> _createSceneObject(GameObject gameObject) async {
    three.Object3D? object3d;

    if (gameObject.assetId != null) {
      final project = ProjectStore.instance.project!;
      final asset = project.assets.firstWhere(
        (a) => a.id == gameObject.assetId,
        orElse: () => Asset(id: '', path: '', type: ''),
      );
      
      if (asset.path.isNotEmpty && ProjectStore.instance.projectPath != null) {
        final model = await modelManager.loadModel(
          asset.id,
          ProjectStore.instance.projectPath!,
          asset.path,
        );
        
        if (model != null) {
          object3d = model.clone();
        }
      }
    }

    object3d ??= three.Object3D();
    
    // Configurar propriedades do objeto 3D
    object3d.name = gameObject.name;
    object3d.userData['gameObjectId'] = gameObject.id;
    object3d.userData['assetId'] = gameObject.assetId;

    final sceneObject = SceneObject(
      id: gameObject.id,
      gameObject: gameObject,
      object3d: object3d,
      assetId: gameObject.assetId,
    );
    
    sceneObject.updateTransform();
    return sceneObject;
  }

  Set<String> _getAllGameObjectIds(List<GameObject> objects) {
    final ids = <String>{};
    
    void collectIds(GameObject obj) {
      ids.add(obj.id);
      for (final child in obj.children) {
        collectIds(child);
      }
    }
    
    for (final obj in objects) {
      collectIds(obj);
    }
    
    return ids;
  }

  void _setupSelectionListener() {
    _selectionDisposer = reaction(
      (_) => SelectionStore.instance.selected,
      (GameObject? selected) {
        sceneManager.highlightObject(selected?.id);
      },
      fireImmediately: true,
    );
  }
}