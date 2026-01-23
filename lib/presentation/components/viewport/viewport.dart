import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:mobx/mobx.dart' hide Listener;
import 'package:open_3d_mapper/presentation/components/viewport/free_camera_controller.dart';
import 'package:three_js/three_js.dart' as three;
import '../../../stores/project_store.dart';
import '../../../stores/selection_store.dart';
import '../../../stores/tool_store.dart';
import '../../../stores/camera_store.dart';
import '../../../domain/scene/game_object/game_object.dart';
import 'controllers/selection_controller.dart';
import 'package:open_3d_mapper/core/input/input_manager.dart';
import 'managers/scene_manager.dart';
import 'managers/model_manager.dart';

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
  
  bool _ready = false;
  late FocusNode _focusNode;
  bool _inputConsumed = false;

  VoidCallback? _projectListener;
  VoidCallback? _cameraStoreListener;
  ReactionDisposer? _selectionDisposer;
  final GlobalKey _viewportKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();

    threeJs = three.ThreeJS(
      setup: setupScene,
      onSetupComplete: _onThreeJsReady,
    );

    freeCam = FreeCameraController(threeJs);
    modelManager = ModelManager();

    _cameraStoreListener = _onCameraFocusRequest;
    CameraStore.instance.addListener(_cameraStoreListener!);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    if (_projectListener != null) {
      ProjectStore.instance.removeListener(_projectListener!);
      _projectListener = null;
    }
    if (_cameraStoreListener != null) {
      CameraStore.instance.removeListener(_cameraStoreListener!);
      _cameraStoreListener = null;
    }
    if (_selectionDisposer != null) {
      _selectionDisposer!();
      _selectionDisposer = null;
    }
    ToolStore.instance.removeListener(_onToolChanged);
    freeCam.dispose();
    threeJs.dispose();
    three.loading.clear();
    modelManager.clear();
    sceneManager.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        try {
          InputManager.instance.handleKeyEvent(event);
        } catch (_) {}
        _onKey(event);
        return KeyEventResult.ignored;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_ready) return;
            if (threeJs.width != constraints.maxWidth ||
                threeJs.height != constraints.maxHeight) {
              threeJs.renderer
                  ?.setSize(constraints.maxWidth, constraints.maxHeight);
              if (threeJs.camera is three.PerspectiveCamera) {
                final camera = threeJs.camera as three.PerspectiveCamera;
                camera.aspect = constraints.maxWidth / constraints.maxHeight;
                camera.updateProjectionMatrix();
              }
            }
          });

          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapDown: (details) {
              if (!_ready) return;
              if (_inputConsumed) return;
              selectionController?.onTapDown(
                  details, _viewportKey.currentContext!);
            },
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (e) {
                if (!_ready) return;
                if (!_focusNode.hasFocus) {
                  _focusNode.requestFocus();
                }

                final renderBox = _viewportKey.currentContext
                    ?.findRenderObject() as RenderBox?;

                _inputConsumed = renderBox != null
                    ? InputManager.instance.handlePointerDown(e, renderBox.size)
                    : false;

                if (_inputConsumed) return;
                freeCam.onPointerDown(e);
              },
              onPointerUp: (e) {
                if (!_ready) return;
                InputManager.instance.handlePointerUp();
                freeCam.onPointerUp(e);
                _inputConsumed = false;
              },
              onPointerMove: (event) {
                if (!_ready) return;
                InputManager.instance.handlePointerMove(event);
                freeCam.onPointerMove(event);
                selectionController?.onPointerMove(
                    event, _viewportKey.currentContext!);
              },
              child: SizedBox.expand(
                key: _viewportKey,
                child: threeJs.build(),
              ),
            ),
          );
        },
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

    threeJs.camera.rotation.order = three.RotationOrders.xyz;
    threeJs.camera.position.setValues(0, 2, 8);

    threeJs.scene.add(three.AmbientLight(0xffffff, 0.6));

    final dir = three.DirectionalLight(0xffffff, 1);
    dir.position.setValues(5, 10, 5);
    threeJs.scene.add(dir);
  }

  void _onThreeJsReady() {
    setState(() {
      _ready = true;
    });
    try {
      freeCam.initialize();
    } catch (_) {}
    sceneManager = SceneManager(
      scene: threeJs.scene,
      camera: threeJs.camera,
      modelManager: modelManager,
    );

    selectionController = SelectionController(
      threeJs: threeJs,
      sceneManager: sceneManager,
    );

    _projectListener = updateSceneFromProject;
    ProjectStore.instance.addListener(_projectListener!);

    _setupSelectionListener();

    updateSceneFromProject();

    threeJs.addAnimationEvent((dt) {
      sceneManager.onUpdate(dt);
    });
  }

  void _onToolChanged() {}

  void _onKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (freeCam.rightMouseDown) return;
      final key = event.logicalKey;
      if (key == LogicalKeyboardKey.keyW) {
        ToolStore.instance.setMode(GizmoMode.translate);
      } else if (key == LogicalKeyboardKey.keyE) {
        ToolStore.instance.setMode(GizmoMode.scale);
      } else if (key == LogicalKeyboardKey.keyR) {
        ToolStore.instance.setMode(GizmoMode.rotate);
      }
    }
  }

  // --- CORREÇÃO AQUI ---
  Future<void> updateSceneFromProject() async {
    final project = ProjectStore.instance.project;
    // 1. Obtemos a Cena Selecionada Atual
    final currentScene = ProjectStore.instance.currentScene;

    // Se não houver projeto ou cena selecionada, limpamos tudo
    if (project == null || currentScene == null) {
      sceneManager.clear();
      return;
    }

    // A variável 'scene' agora aponta para a cena selecionada, e não a primeira
    final scene = currentScene;

    // 2. Atualizamos/Criamos objetos que existem na cena atual
    for (final rootObject in scene.rootObjects) {
      await sceneManager.updateSceneObject(rootObject);
      for (final child in rootObject.children) {
        await _processGameObject(child, rootObject.id);
      }
    }

    // 3. Sistema de Diff (Diferença):
    // Pegamos todos os IDs que DEVEM estar na cena atual
    final projectObjectIds = _getAllGameObjectIds(scene.rootObjects);
    
    // Pegamos todos os IDs que ESTÃO atualmente renderizados no ThreeJS
    final currentObjectIds = sceneManager.sceneObjects.keys.toSet();
    
    // A diferença são os objetos que estavam na cena anterior (ou deletados)
    // e devem ser removidos agora.
    final objectsToRemove = currentObjectIds.difference(projectObjectIds);

    for (final id in objectsToRemove) {
      sceneManager.removeSceneObject(id);
    }
  }
  // --- FIM DA CORREÇÃO ---

  Future<void> _processGameObject(
      GameObject gameObject, String? parentId) async {
    await sceneManager.updateSceneObject(gameObject);
    for (final child in gameObject.children) {
      await _processGameObject(child, gameObject.id);
    }
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
        sceneManager.onSelectionChanged(selected?.id);
      },
      fireImmediately: true,
    );
  }

  void _onCameraFocusRequest() {
    if (!_ready) return;
    final target = CameraStore.instance.focusTarget;
    if (target == null) return;

    final sceneObject = sceneManager.getSceneObject(target.id);
    if (sceneObject != null && sceneObject.object3d != null) {
      _performFocus(sceneObject.object3d!);
    }
    CameraStore.instance.consumeRequest();
  }

  void _performFocus(three.Object3D targetObj) {
    final targetPos = three.Vector3();
    targetObj.getWorldPosition(targetPos);
    const double distance = 5.0;
    final offset = three.Vector3(0, 2, distance);

    threeJs.camera.position.setValues(
      targetPos.x + offset.x,
      targetPos.y + offset.y,
      targetPos.z + offset.z,
    );
    threeJs.camera.lookAt(targetPos);
    threeJs.camera.updateMatrixWorld();
  }
}