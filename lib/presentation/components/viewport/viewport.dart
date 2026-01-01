import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_dart/three_dart.dart' as THREE;
import 'package:three_dart_jsm/three_dart_jsm.dart' as THREE_JSM;
import 'package:path/path.dart' as p;
import '../../../stores/project_store.dart';

class Viewport3D extends StatefulWidget {
  const Viewport3D({super.key});

  @override
  State<Viewport3D> createState() => _Viewport3DState();
}

class _Viewport3DState extends State<Viewport3D> {
  late FlutterGlPlugin three3dRender;
  THREE.WebGLRenderer? renderer;
  THREE.Scene? scene;
  THREE.Camera? camera;
  THREE.Mesh? cube;
  final Map<String, THREE.Object3D> _gameObjectNodes = {};
  final Map<String, THREE.Object3D> _loadedAssetScenes = {};
  final Set<String> _loadingAssets = {};
  final Map<String, bool> _nodeIsAssetInstance = {};

  Size? screenSize;
  double width = 300;
  double height = 300;
  num dpr = 1.0;

  bool initialized = false;
  bool loaded = false;

  dynamic sourceTexture;
  THREE.WebGLMultisampleRenderTarget? renderTarget;

  final clock = THREE.Clock();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    try {
      three3dRender.dispose();
    } catch (_) {}
    super.dispose();
  }

  Future<void> initPlatformState() async {
    width = screenSize!.width;
    height = screenSize!.height;

    three3dRender = FlutterGlPlugin();

    final options = {
      "antialias": true,
      "alpha": false,
      "width": width.toInt(),
      "height": height.toInt(),
      "dpr": dpr
    };

    await three3dRender.initialize(options: options);
    setState(() {});

    // give a moment for context
    Future.delayed(const Duration(milliseconds: 100), () async {
      await three3dRender.prepareContext();
      initScene();
      animate();
    });
  }

  void initRenderer() {
    final _options = {
      "width": width,
      "height": height,
      "gl": three3dRender.gl,
      "antialias": true,
      "canvas": three3dRender.element
    };

    renderer = THREE.WebGLRenderer(_options);
    renderer!.setPixelRatio(dpr.toDouble());
    renderer!.setSize(width, height, false);
    renderer!.shadowMap.enabled = false;

    if (!kIsWeb) {
      final pars = THREE.WebGLRenderTargetOptions({"format": THREE.RGBAFormat});
      renderTarget = THREE.WebGLMultisampleRenderTarget((width * dpr).toInt(), (height * dpr).toInt(), pars);
      renderTarget!.samples = 4;
      renderer!.setRenderTarget(renderTarget! as dynamic);
      sourceTexture = renderer!.getRenderTargetGLTexture(renderTarget! as dynamic);
    }
  }

  void initScene() {
    initRenderer();

    scene = THREE.Scene();

    camera = THREE.PerspectiveCamera(45, width / height, 0.1, 1000);
    camera!.position.set(0, 0, 6);
    scene!.add(camera!);

    final ambient = THREE.AmbientLight(0xffffff, 0.6);
    scene!.add(ambient);

    final dir = THREE.DirectionalLight(0xffffff, 0.8);
    dir.position.set(5, 10, 7.5);
    scene!.add(dir);

    final geometry = THREE.BoxGeometry(1.5, 1.5, 1.5);
    final material = THREE.MeshPhongMaterial({"color": 0x6699ff});
    cube = THREE.Mesh(geometry, material);
    scene!.add(cube as THREE.Object3D);

    // initial sync with project store (placeholders)
    _syncSceneWithProject();

    loaded = true;
    setState(() {
      initialized = true;
    });
  }

  void render() {
    if (renderer == null || scene == null || camera == null) return;

    final _gl = three3dRender.gl;
    renderer!.render(scene!, camera!);

    _gl.flush();

    if (!kIsWeb) {
      try {
        three3dRender.updateTexture(sourceTexture);
      } catch (_) {}
    }
  }

  /// Reconcile scene objects with ProjectStore's GameObjects.
  void _syncSceneWithProject() {
    final proj = ProjectStore.instance.project;
    if (proj == null) return;
    if (proj.scenes.isEmpty) return;

    final roots = proj.scenes.first.rootObjects;

    // mark existing ids
    final existingIds = _gameObjectNodes.keys.toSet();

    for (var i = 0; i < roots.length; i++) {
      final go = roots[i];
      if (_gameObjectNodes.containsKey(go.id)) {
        // If the GO already has a node, but now the referenced asset is loaded
        // and the current node is only a placeholder, replace it with an instance.
        final existingNode = _gameObjectNodes[go.id]!;
        final asset = ProjectStore.instance.project!.assets.where((a) => a.id == go.assetId).toList();
        if (asset.isNotEmpty) {
          final as = asset.first;
          if (_loadedAssetScenes.containsKey(as.id) && (_nodeIsAssetInstance[go.id] != true)) {
            // remove placeholder
            try {
              scene!.remove(existingNode);
            } catch (_) {}
            // add clone
            final template = _loadedAssetScenes[as.id]!;
            final inst = THREE_JSM.SkeletonUtils.clone(template);
            inst.name = go.name;
            inst.position.set(existingNode.position.x, existingNode.position.y, existingNode.position.z);
            scene!.add(inst);
            _gameObjectNodes[go.id] = inst;
            _nodeIsAssetInstance[go.id] = true;
            existingIds.remove(go.id);
            continue;
          }
        }

        existingIds.remove(go.id);
        // update transform if needed (not implemented fully)
        continue;
      }
      // If GameObject references an asset, try to load the model
      // find asset referenced by this GameObject (if any)
      final assets = ProjectStore.instance.project!.assets.where((a) => a.id == go.assetId).toList();
      final asset = assets.isNotEmpty ? assets.first : null;
      if (asset != null) {
        final abs = p.join(ProjectStore.instance.projectPath!, asset.path);
        final ext = p.extension(abs).toLowerCase();
        if ((ext == '.glb' || ext == '.gltf')) {
          // if asset scene already loaded, instantiate a clone for this GO
          if (_loadedAssetScenes.containsKey(asset.id)) {
            final template = _loadedAssetScenes[asset.id]!;
            final inst = THREE_JSM.SkeletonUtils.clone(template);
            inst.name = go.name;
            inst.position.set((i - roots.length / 2) * 2.5, 0, 0);
            scene!.add(inst);
            _gameObjectNodes[go.id] = inst;
          } else {
            // not loaded yet: create a small placeholder and trigger load
            final geom = THREE.BoxGeometry(0.6, 0.6, 0.6);
            final color = _colorFromString(go.id);
            final mat = THREE.MeshPhongMaterial({"color": color});
            final mesh = THREE.Mesh(geom, mat);
            mesh.name = go.name;
            mesh.position.set((i - roots.length / 2) * 2.5, 0, 0);
            scene!.add(mesh);
            _gameObjectNodes[go.id] = mesh;
            _nodeIsAssetInstance[go.id] = false;

            if (!_loadingAssets.contains(asset.id)) {
              _loadingAssets.add(asset.id);
              _loadAssetScene(asset.id, abs).then((_) {
                _loadingAssets.remove(asset.id);
                // after load, sync again to replace placeholders
                try {
                  _syncSceneWithProject();
                } catch (_) {}
              });
            }
          }
          existingIds.remove(go.id);
          continue;
        }
        // if asset exists but isn't a GLTF/GLB, fall through to create a generic placeholder
      }

      // create a placeholder mesh for this GameObject so it appears in the viewport
      final geom = THREE.BoxGeometry(1.0, 1.0, 1.0);
      // color derived from hash of id to vary appearance
      final color = _colorFromString(go.id);
      final mat = THREE.MeshPhongMaterial({"color": color});
      final mesh = THREE.Mesh(geom, mat);
      mesh.name = go.name;

      // position objects in a row to avoid overlap
      mesh.position.set((i - roots.length / 2) * 2.5, 0, 0);

      scene!.add(mesh);
      _gameObjectNodes[go.id] = mesh;
      _nodeIsAssetInstance[go.id] = false;
    }

    // remove nodes that are no longer present
    for (final id in existingIds) {
      final node = _gameObjectNodes[id];
      if (node != null) {
        try {
          scene!.remove(node);
        } catch (_) {}
      }
      _gameObjectNodes.remove(id);
    }
  }

  /// Load the GLTF/GLB asset and store the scene template in `_loadedAssetScenes`.
  Future<void> _loadAssetScene(String assetId, String absolutePath) async {
    if (absolutePath.isEmpty) return;

    try {
      final loader = THREE_JSM.GLTFLoader(null);
      final uri = Uri.file(absolutePath).toString();
      final result = await loader.loadAsync(uri);
      if (result != null && result["scene"] != null) {
        // store the loaded scene as template
        final loadedScene = result["scene"] as THREE.Object3D;
        _loadedAssetScenes[assetId] = loadedScene;
      }
    } catch (e) {
      // loading failed; keep placeholder and log
      debugPrint('Failed to load asset $absolutePath : $e');
    }
  }

  int _colorFromString(String s) {
    // simple hash to color
    var h = 0;
    for (var i = 0; i < s.length; i++) {
      h = (h * 31 + s.codeUnitAt(i)) & 0xFFFFFF;
    }
    // blend with base
    return (0x336600 | (h & 0x00FFFF));
  }

  void animate() {
    if (!mounted) return;
    if (!loaded) return;

    // rotate cube
    if (cube != null) {
      cube!.rotation.y = cube!.rotation.y + 0.01;
      cube!.rotation.x = cube!.rotation.x + 0.005;
    }

    render();

    // schedule next frame
    Future.delayed(const Duration(milliseconds: 16), () {
      if (mounted) animate();
    });
  }

  void initSize(BuildContext context) {
    if (screenSize != null) return;
    final mqd = MediaQuery.of(context);
    screenSize = Size(mqd.size.width * 0.65, mqd.size.height * 0.8);
    dpr = mqd.devicePixelRatio;
    initPlatformState();
  }

  @override
  Widget build(BuildContext context) {
    initSize(context);

    return Container(
      color: const Color(0xFF0E0E0E),
      child: AnimatedBuilder(
        animation: ProjectStore.instance,
        builder: (ctx, _) {
          final store = ProjectStore.instance;
          if (store.projectPath == null || store.assetsRoot == null) {
            return const Center(
                child: Text('No project opened',
                    style: TextStyle(color: Colors.white54)));
          }

          // keep scene in sync with project store (add/remove placeholders)
          try {
            _syncSceneWithProject();
          } catch (_) {}

          return Row(
            children: [
              // main canvas area
              Expanded(
                flex: 3,
                child: Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF050505),
                    border: Border.all(color: const Color(0xFF2A2A2A)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: initialized && three3dRender.isInitialized
                        ? kIsWeb
                            ? HtmlElementView(viewType: three3dRender.textureId!.toString())
                            : Texture(textureId: three3dRender.textureId!)
                        : const Text('Initializing renderer...', style: TextStyle(color: Colors.white70)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
