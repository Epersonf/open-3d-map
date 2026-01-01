import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart';
import 'package:flutter_scene/scene.dart';

class Viewport3D extends StatefulWidget {
  const Viewport3D({super.key});

  @override
  State<Viewport3D> createState() => _Viewport3DState();
}

class _Viewport3DState extends State<Viewport3D> {
  final Scene scene = Scene();
  late Camera camera;

  @override
  void initState() {
    super.initState();

    camera = PerspectiveCamera();

    final child = makeCube(scene.environment);
    
    final node = Node(name: 'cube', mesh: child);
    scene.add(node);

    // Garante que os recursos carregaram
    Scene.initializeStaticResources().then((_) {
      setState(() {});
    });
  }

  Mesh makeCube(Environment env) {
    final geometry = CuboidGeometry(Vector3(1, 1, 1));

    final material = PhysicallyBasedMaterial(environment: env)
      ..baseColorFactor = Vector4(0.2, 0.7, 1.0, 1.0) // cor do cubo
      ..metallicFactor = 0.0
      ..roughnessFactor = 0.5
      ..vertexColorWeight = 1.0; // usa as cores de vértice também, se tiver

    return Mesh(geometry, material);
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ScenePainter(scene, camera),
      size: Size.infinite,
    );
  }
}

class _ScenePainter extends CustomPainter {
  final Scene scene;
  final Camera camera;

  _ScenePainter(this.scene, this.camera);

  @override
  void paint(Canvas canvas, Size size) {
    scene.render(
      camera,
      canvas,
    );
  }

  @override
  bool shouldRepaint(_) => true;
}
