import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_dart/three_dart.dart' as THREE;
import '../../../stores/project_store.dart';

/// Viewport using three_dart + flutter_gl.
/// Renders a simple rotating cube as a starting point. The asset side-list
/// remains: double-clicking a .glb still calls `ProjectStore.addAssetAsGameObject`.
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
