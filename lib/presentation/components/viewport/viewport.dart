import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:open_3d_mapper/presentation/components/viewport/fly_camera_controller.dart';
import 'package:vector_math/vector_math.dart';
import 'package:flutter_scene/scene.dart';

class Viewport3D extends StatefulWidget {
  const Viewport3D({super.key});

  @override
  State<Viewport3D> createState() => _Viewport3DState();
}

class _Viewport3DState extends State<Viewport3D>
    with SingleTickerProviderStateMixin {
  late PerspectiveCamera camera;
  late FlyCameraController controller;
  late final Ticker _ticker;
  final Scene scene = Scene();

  @override
  void initState() {
    super.initState();

    camera = PerspectiveCamera(
      position: Vector3(0, 0, 5),
      target: Vector3.zero(),
    );

    controller = FlyCameraController(camera);


    // TODO: INSTANTIATE SCENE CONTENT HERE
    final cube = Mesh(
      CuboidGeometry(Vector3(1, 1, 1)),
      PhysicallyBasedMaterial(environment: scene.environment)
        ..baseColorFactor = Vector4(0.2, 0.7, 1, 1),
    );

    scene.add(Node(name: 'cube', mesh: cube));

    Scene.initializeStaticResources().then((_) {
      if (mounted) setState(() {});
    });

    _ticker = createTicker((_) {
      controller.update();
      setState(() {});
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          controller.onKeyDown(event.logicalKey);
        } else if (event is KeyUpEvent) {
          controller.onKeyUp(event.logicalKey);
        }
        return KeyEventResult.handled;
      },
      child: Listener(
        onPointerDown: controller.onPointerDown,
        onPointerUp: controller.onPointerUp,
        onPointerMove: controller.onPointerMove,
        child: SizedBox.expand(
          child: CustomPaint(
            painter: _ScenePainter(scene, camera),
          ),
        ),
      ),
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
      viewport: Offset.zero & size,
    );
  }

  @override
  bool shouldRepaint(_) => true;
}
