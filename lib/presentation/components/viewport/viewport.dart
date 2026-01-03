import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart' hide Listener;
import 'package:three_js/three_js.dart' as three;
import 'package:path/path.dart' as p;

import '../../../core/utils/model_import.dart';
import '../../../stores/project_store.dart';
import '../../../stores/selection_store.dart';
import '../../../domain/scene/game_object.dart';
import '../../../domain/asset/asset.dart';
import 'free_camera_controller.dart';

class Viewport3D extends StatefulWidget {
  const Viewport3D({super.key});

  @override
  State<Viewport3D> createState() => _Viewport3DState();
}

class _Viewport3DState extends State<Viewport3D> {
  late three.ThreeJS threeJs;
  late FreeCameraController freeCam;
  final Map<String, three.Object3D> _loadedObjects = {};
  final Map<String, three.Object3D> _gameObjectInstances = {};
  final Map<String, GameObject> _gameObjectMap = {}; // Mapeamento ID -> GameObject
  VoidCallback? _projectListener;
  ReactionDisposer? _selectionDisposer;
  final GlobalKey _viewportKey = GlobalKey();

  // Raycasting
  final three.Raycaster _raycaster = three.Raycaster();
  final three.Vector2 _mouse = three.Vector2(0, 0);

  @override
  void initState() {
    super.initState();

    threeJs = three.ThreeJS(
      setup: setupScene,
      onSetupComplete: () {},
    );

    freeCam = FreeCameraController(threeJs);

    // Listen for project changes
    _projectListener = updateSceneFromProject;
    ProjectStore.instance.addListener(_projectListener!);

    // Listen for selection changes
    _setupSelectionListener();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: freeCam.onKey,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        child: Listener(
          onPointerDown: (event) {
            freeCam.onPointerDown(event);
          },
          onPointerUp: (event) {
            freeCam.onPointerUp(event);
          },
          onPointerMove: (event) {
            freeCam.onPointerMove(event);

            // Atualizar posição do mouse para raycasting
            final RenderBox? box = _viewportKey.currentContext?.findRenderObject() as RenderBox?;
            if (box == null) return;
            final offset = box.globalToLocal(event.position);

            _mouse.x = (offset.dx / threeJs.width) * 2 - 1;
            _mouse.y = -(offset.dy / threeJs.height) * 2 + 1;
          },
          child: SizedBox.expand(
            key: _viewportKey,
            child: threeJs.build(),
          ),
        ),
      ),
    );
  }

  void _handleTapDown(TapDownDetails details) {
    // Atualizar posição do mouse
    final RenderBox? box = _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final offset = box.globalToLocal(details.globalPosition);

    _mouse.x = (offset.dx / threeJs.width) * 2 - 1;
    _mouse.y = -(offset.dy / threeJs.height) * 2 + 1;

    // Executar raycasting
    _performRaycast();
  }

  void _performRaycast() {
    _raycaster.setFromCamera(_mouse, threeJs.camera);

    // Obter todos os objetos que podem ser clicados
    final List<three.Object3D> intersectedObjects = [];
    for (final instance in _gameObjectInstances.values) {
      instance.traverse((object) {
        if (object is three.Mesh) {
          intersectedObjects.add(object);
        }
      });
    }

    // Encontrar interseções
    final intersects = _raycaster.intersectObjects(intersectedObjects, true);

    if (intersects.isNotEmpty) {
      // Encontrar o GameObject correspondente ao objeto clicado
      var clickedObject = intersects.first.object;

      // Subir na hierarquia até encontrar um objeto com gameObjectId
      while (clickedObject != null && clickedObject.userData['gameObjectId'] == null) {
        clickedObject = clickedObject.parent;
      }

      if (clickedObject != null && clickedObject.userData['gameObjectId'] != null) {
        final gameObjectId = clickedObject.userData['gameObjectId'] as String;
        final gameObject = ProjectStore.instance.findGameObjectById(gameObjectId);

        if (gameObject != null) {
          SelectionStore.instance.select(gameObject);
          // Destacar objeto selecionado
          _highlightSelectedObject(gameObject);
        }
      }
    } else {
      // Nenhum objeto clicado - deselecionar
      SelectionStore.instance.clear();
      _highlightSelectedObject(null);
    }
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

    // Update scene immediately if project is already loaded
    updateSceneFromProject();
  }

  void updateSceneFromProject() {
    final project = ProjectStore.instance.project;
    if (project == null || project.scenes.isEmpty) {
      // Clear scene if no project
      clearSceneObjects();
      return;
    }

    // Limpar mapeamento
    _gameObjectMap.clear();

    // Get the first scene (for now)
    final scene = project.scenes.first;

    // Process all root objects
    for (final rootObject in scene.rootObjects) {
      processGameObject(rootObject, null);
    }
  }

  void clearSceneObjects() {
    // Remove all game object instances from scene
    for (final instance in _gameObjectInstances.values) {
      instance.removeFromParent();
    }
    _gameObjectInstances.clear();
    _gameObjectMap.clear();
  }

  void processGameObject(GameObject gameObject, three.Object3D? parent) {
    // Ensure mapping
    _gameObjectMap[gameObject.id] = gameObject;
    // Check if this object already exists in scene
    if (_gameObjectInstances.containsKey(gameObject.id)) {
      updateExistingGameObject(gameObject);
    } else {
      createNewGameObject(gameObject, parent);
    }

    // Process children recursively
    for (final child in gameObject.children) {
      processGameObject(child, _gameObjectInstances[gameObject.id]);
    }
  }

  void updateExistingGameObject(GameObject gameObject) {
    final instance = _gameObjectInstances[gameObject.id];
    if (instance == null) return;

    // Update transform
    instance.position.setValues(
      gameObject.transform.position.x,
      gameObject.transform.position.y,
      gameObject.transform.position.z,
    );

    // Convert degrees to radians for rotation
    instance.rotation.set(
      gameObject.transform.rotation.x * (3.14159265359 / 180),
      gameObject.transform.rotation.y * (3.14159265359 / 180),
      gameObject.transform.rotation.z * (3.14159265359 / 180),
    );

    instance.scale.setValues(
      gameObject.transform.scale.x,
      gameObject.transform.scale.y,
      gameObject.transform.scale.z,
    );

    // Update parent relationship if needed
    updateParentRelationship(gameObject, instance);
  }

  void updateParentRelationship(GameObject gameObject, three.Object3D instance) {
    three.Object3D? newParent;

    if (gameObject.parentId != null) {
      newParent = _gameObjectInstances[gameObject.parentId];
    }

    final currentParent = instance.parent;
    if (currentParent != newParent) {
      instance.removeFromParent();
      if (newParent != null) {
        newParent.add(instance);
      } else {
        threeJs.scene.add(instance);
      }
    }
  }

  Future<void> createNewGameObject(GameObject gameObject, three.Object3D? parent) async {
    three.Object3D object3d;

    if (gameObject.assetId != null) {
      // Find the asset
      final project = ProjectStore.instance.project!;
      final asset = project.assets.firstWhere(
        (a) => a.id == gameObject.assetId,
        orElse: () => Asset(id: '', path: '', type: ''),
      );
      
      if (asset.path.isNotEmpty) {
        // Get absolute path
        final projectPath = ProjectStore.instance.projectPath!;
        final absolutePath = p.join(projectPath, asset.path);
        
        // Load model if not already loaded
        if (!_loadedObjects.containsKey(asset.id)) {
          final model = await ModelImport.loadModel(absolutePath);
          if (model != null) {
            _loadedObjects[asset.id] = model;
          } else {
            // Create fallback cube if model fails to load
            _loadedObjects[asset.id] = createFallbackObject(asset.id);
          }
        }
        
        // Clone the loaded model for this instance
        object3d = _loadedObjects[asset.id]!.clone();
      } else {
        // No asset, create empty object
        object3d = three.Object3D();
      }
    } else {
      // No asset, create empty object
      object3d = three.Object3D();
    }

    // Set name for debugging
    object3d.name = gameObject.name;

    // Store gameObjectId in userData for raycasting
    object3d.userData['gameObjectId'] = gameObject.id;

    // Apply transform
    object3d.position.setValues(
      gameObject.transform.position.x,
      gameObject.transform.position.y,
      gameObject.transform.position.z,
    );

    // Convert degrees to radians for rotation
    object3d.rotation.set(
      gameObject.transform.rotation.x * (3.14159265359 / 180),
      gameObject.transform.rotation.y * (3.14159265359 / 180),
      gameObject.transform.rotation.z * (3.14159265359 / 180),
    );

    object3d.scale.setValues(
      gameObject.transform.scale.x,
      gameObject.transform.scale.y,
      gameObject.transform.scale.z,
    );

    // Store user data for reference
    object3d.userData['gameObjectId'] = gameObject.id;
    object3d.userData['assetId'] = gameObject.assetId;

    // Add to scene
    if (parent != null) {
      parent.add(object3d);
    } else {
      threeJs.scene.add(object3d);
    }

    // Store reference
    _gameObjectInstances[gameObject.id] = object3d;
  }

  three.Object3D createFallbackObject(String assetId) {
    final geometry = three.BoxGeometry(1, 1, 1);
    final material = three.MeshStandardMaterial();
    material.color = three.Color.fromHex32(0xff0000);
    material.wireframe = true;

    final cube = three.Mesh(geometry, material);
    cube.name = 'Fallback: $assetId';
    return cube;
  }

  void _highlightSelectedObject(GameObject? selected) {
    // Primeiro, remover destaque de todos os objetos
    for (final instance in _gameObjectInstances.values) {
      instance.traverse((object) {
        if (object is three.Mesh) {
          if (object.material is three.MeshStandardMaterial) {
            final material = object.material as three.MeshStandardMaterial;
            // Remover emissão
            material.emissive = three.Color.fromHex32(0x000000);
            material.emissiveIntensity = 0.0;
          }
        }
      });
    }

    // Destacar objeto selecionado
    if (selected != null && _gameObjectInstances.containsKey(selected.id)) {
      final selectedInstance = _gameObjectInstances[selected.id]!;
      selectedInstance.traverse((object) {
        if (object is three.Mesh) {
          if (object.material is three.MeshStandardMaterial) {
            final material = object.material as three.MeshStandardMaterial;
            // Amarelo suave
            material.emissive = three.Color.fromHex32(0x444400);
            material.emissiveIntensity = 0.5;
          }
        }
      });
    }
  }

  void _setupSelectionListener() {
    _selectionDisposer = reaction((_) => SelectionStore.instance.selected, (GameObject? sel) {
      _highlightSelectedObject(sel);
    }, fireImmediately: true);
  }
}
