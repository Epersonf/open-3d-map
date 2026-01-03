import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

class Viewport3D extends StatefulWidget {
  const Viewport3D({super.key});

  @override
  State<Viewport3D> createState() => _Viewport3DState();
}

class _Viewport3DState extends State<Viewport3D> {
  late three.ThreeJS threeJs;

  @override
  void initState() {
    super.initState();

    threeJs = three.ThreeJS(
      setup: setupScene,
      onSetupComplete: () {
        // opcional, só pra forçar rebuild se vc quiser reagir a algo
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    threeJs.dispose();
    three.loading.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // IMPORTANTÍSSIMO: sempre renderizar o threeJs.build(),
    // senão o setup nunca roda e o onSetupComplete nunca dispara.
    return SizedBox.expand(
      child: threeJs.build(),
    );
  }

  Future<void> setupScene() async {
    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32(0x222222);

    threeJs.camera = three.PerspectiveCamera(
      60,
      threeJs.width / threeJs.height,
      0.1,
      1000,
    );
    threeJs.camera.position.setValues(3, 4, 8);
    threeJs.camera.lookAt(threeJs.scene.position);

    final ambient = three.AmbientLight(0xffffff, 0.6);
    threeJs.scene.add(ambient);

    final dir = three.DirectionalLight(0xffffff, 0.8);
    dir.position.setValues(5, 10, 7);
    threeJs.scene.add(dir);

    final cubeGeometry = three.BoxGeometry(1, 1, 1);
    final cubeMaterial = three.MeshPhongMaterial.fromMap({
      'color': 0x00ff00,
    });
    final cube = three.Mesh(cubeGeometry, cubeMaterial);
    threeJs.scene.add(cube);

    threeJs.addAnimationEvent((dt) {
      cube.rotation.y += dt;
      cube.rotation.x += dt * 0.5;
    });
  }
}
