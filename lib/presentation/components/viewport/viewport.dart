import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

import 'free_camera_controller.dart';

class Viewport3D extends StatefulWidget {
  const Viewport3D({super.key});

  @override
  State<Viewport3D> createState() => _Viewport3DState();
}

class _Viewport3DState extends State<Viewport3D> {
  late three.ThreeJS threeJs;
  FreeCameraController? freeCam;

  @override
  void initState() {
    super.initState();

    threeJs = three.ThreeJS(
      setup: setupScene,
      onSetupComplete: () {},
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
    return SizedBox.expand(
      child: threeJs.build(),
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

    threeJs.camera.position.setValues(0, 2, 8);

    threeJs.scene.add(three.AmbientLight(0xffffff, 0.6));

    final dir = three.DirectionalLight(0xffffff, 1);
    dir.position.setValues(5, 10, 5);
    threeJs.scene.add(dir);

    final geo = three.BoxGeometry(1, 1, 1);
    final mat = three.MeshStandardMaterial();
    mat.color = three.Color.fromHex32(0x00ff00);
    final cube = three.Mesh(geo, mat);
    threeJs.scene.add(cube);

    threeJs.addAnimationEvent((dt) {
      cube.rotation.y += dt;
    });

    freeCam = FreeCameraController(threeJs);
  }
}
