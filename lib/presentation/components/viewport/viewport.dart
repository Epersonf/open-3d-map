import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For LogicalKeyboardKey and KeyEvent
import 'package:mobx/mobx.dart' hide Listener;
import 'package:open_3d_mapper/components/inherited/transform/transform_component.dart';
import 'package:open_3d_mapper/presentation/components/viewport/free_camera_controller.dart';
import 'package:three_js/three_js.dart' as three;
import '../../../stores/project_store.dart';
import '../../../stores/selection_store.dart';
import '../../../stores/tool_store.dart';
import '../../../stores/camera_store.dart'; // Camera focus bridge
import '../../../domain/scene/game_object.dart';
import '../../../domain/asset/asset.dart';
import 'controllers/selection_controller.dart';
import 'controllers/gizmo_controller.dart';
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
  GizmoController? gizmoController;
  // Indica que a cena ThreeJS foi inicializada e `threeJs.camera` está disponível
  bool _ready = false;
  
  VoidCallback? _projectListener;
  // Listener para requisições de foco da câmera
  VoidCallback? _cameraListener;
  ReactionDisposer? _selectionDisposer;
  final GlobalKey _viewportKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    threeJs = three.ThreeJS(
      setup: setupScene,
      onSetupComplete: _onThreeJsReady,
    );

    // Criar o controller aqui é seguro pois o construtor não acessa a câmera.
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
    // Remover listener de foco da câmera
    if (_cameraListener != null) {
      CameraStore.instance.removeListener(_cameraListener!);
      _cameraListener = null;
    }
    if (_selectionDisposer != null) {
      _selectionDisposer!();
      _selectionDisposer = null;
    }
    // Remove tool listener if it was added
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
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: _onKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Atualizar o tamanho do renderizador e aspect ratio da câmera
          // quando as dimensões do widget mudarem
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Não tocar na câmera/renderer antes da cena estar pronta
            if (!_ready) return;

            if (threeJs.width != constraints.maxWidth ||
                threeJs.height != constraints.maxHeight) {
              threeJs.renderer?.setSize(constraints.maxWidth, constraints.maxHeight);

              // Atualizar aspect ratio da câmera
              if (threeJs.camera is three.PerspectiveCamera) {
                final camera = threeJs.camera as three.PerspectiveCamera;
                camera.aspect = constraints.maxWidth / constraints.maxHeight;
                camera.updateProjectionMatrix();
              }
            }
          });

          return GestureDetector(
            onTapDown: (details) {
              // Segurança: não tente selecionar antes da cena estar pronta
              if (!_ready) return;

              // If we're currently dragging the gizmo, ignore tap selection
              if (gizmoController?.isDragging == true) return;

              selectionController?.onTapDown(details, _viewportKey.currentContext!);
            },
            child: Listener(
              onPointerDown: (e) {
                // Não processa interações de câmera antes da cena estar pronta
                if (!_ready) return;

                // 1) Try the gizmo first (instantaneous raw event)
                final renderBox = _viewportKey.currentContext?.findRenderObject() as RenderBox?;
                final hitGizmo = renderBox != null
                    ? (gizmoController?.onPointerDown(e, _viewportKey.currentContext!, renderBox.size) ?? false)
                    : false;

                if (hitGizmo) return;

                // 2) Otherwise, handle camera interaction
                freeCam.onPointerDown(e);
              },
              onPointerUp: (e) {
                if (!_ready) return;

                gizmoController?.onPointerUp();
                freeCam.onPointerUp(e);
              },
              onPointerMove: (event) {
                if (!_ready) return;

                if (gizmoController?.isDragging == true) {
                  gizmoController?.onPointerMove(event);
                  return;
                }

                freeCam.onPointerMove(event);
                selectionController?.onPointerMove(event, _viewportKey.currentContext!);
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

    // Use standard XYZ rotation order to match ThreeJS defaults
    threeJs.camera.rotation.order = three.RotationOrders.xyz;
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
    // Marca a cena pronta para que o build() possa manipular câmera/renderer
    setState(() {
      _ready = true;
    });
    // Inicializa o controller que depende da câmera do ThreeJS
    try {
      freeCam.initialize();
    } catch (_) {}
    sceneManager = SceneManager(
      scene: threeJs.scene,
      modelManager: modelManager,
    );

    selectionController = SelectionController(
      threeJs: threeJs,
      sceneManager: sceneManager,
    );

    // Initialize Gizmo controller and load all gizmo variants
    gizmoController = GizmoController(threeJs);
    gizmoController!.loadAllGizmos();

    threeJs.addAnimationEvent((dt) {
      gizmoController?.update();
    });

    // Listen for tool changes to update gizmo immediately
    ToolStore.instance.addListener(_onToolChanged);

    // Ouvir mudanças no projeto
    _projectListener = updateSceneFromProject;
    ProjectStore.instance.addListener(_projectListener!);

    // Ouvir pedidos de foco da UI
    _cameraListener = _handleCameraFocusRequest;
    CameraStore.instance.addListener(_cameraListener!);

    // Ouvir mudanças na seleção
    _setupSelectionListener();

    // Populate scene from project now that sceneManager exists
    updateSceneFromProject();
  }

  /// Lógica para focar a câmera no objeto solicitado pela UI
  void _handleCameraFocusRequest() {
    final target = CameraStore.instance.focusTarget;
    if (target == null) return;

    final t = target.getComponent<TransformComponent>();
    if (t == null) return;
    final targetPos = three.Vector3(t.position.x, t.position.y, t.position.z);

    // Distância padrão para o foco (pode ser melhorada calculando bounds)
    const double distance = 5.0;
    final offset = three.Vector3(0, 2, distance);

    threeJs.camera.position.setValues(
      targetPos.x + offset.x,
      targetPos.y + offset.y,
      targetPos.z + offset.z,
    );

    threeJs.camera.lookAt(targetPos);

    // Consumir request para não ser reprocessado
    CameraStore.instance.consumeRequest();
  }

  void _onToolChanged() {
    gizmoController?.update();
  }

  /// Método centralizado para gerenciar input de teclado
  void _onKey(KeyEvent event) {
    // 1. Passa o evento para a câmera (para movimento WASD+QE)
    // A câmera internamente já verifica se o botão direito está pressionado para se mover
    freeCam.onKey(event);

    // 2. Atalhos de Editor (Apenas no KeyDown para não disparar várias vezes)
    if (event is KeyDownEvent) {
      // Se estivermos "voando" com a câmera (Botão direito segurado),
      // não queremos trocar a ferramenta, pois W e E são usados para movimento.
      if (freeCam.rightMouseDown) return;

      final key = event.logicalKey;

      // --- Alternar Modos (W, E, R) ---
      if (key == LogicalKeyboardKey.keyW) {
        ToolStore.instance.setMode(GizmoMode.translate);
      } else if (key == LogicalKeyboardKey.keyE) {
        ToolStore.instance.setMode(GizmoMode.scale);
      } else if (key == LogicalKeyboardKey.keyR) {
        ToolStore.instance.setMode(GizmoMode.rotate);
      }

      // --- Focus (F) ---
      else if (key == LogicalKeyboardKey.keyF) {
        final selected = SelectionStore.instance.selected;
        if (selected != null) {
          CameraStore.instance.requestFocus(selected);
        }
      }
    }
  }

  Future<void> updateSceneFromProject() async {
    final project = ProjectStore.instance.project;
    if (project == null || project.scenes.isEmpty) {
      sceneManager.clear();
      return;
    }

    final scene = project.scenes.first;
    
    for (final rootObject in scene.rootObjects) {
      await sceneManager.updateSceneObject(rootObject);
      // Recurse children after the parent is ensured
      for (final child in rootObject.children) {
        await _processGameObject(child, rootObject.id);
      }
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
    await sceneManager.updateSceneObject(gameObject);
    for (final child in gameObject.children) {
      await _processGameObject(child, gameObject.id);
    }
  }

  // SceneManager now creates the container and initializes components.

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