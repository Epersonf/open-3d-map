import 'package:flutter/material.dart' hide Matrix4;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart' hide Matrix4;
import 'package:open_3d_mapper/presentation/components/viewport/fly_camera_controller.dart';
import 'package:vector_math/vector_math.dart';
import 'package:flutter_scene/scene.dart';
import 'package:open_3d_mapper/stores/project_store.dart';
import 'package:open_3d_mapper/core/utils/model_import.dart';
import 'package:open_3d_mapper/domain/asset/asset.dart';

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
  final List<Node> _spawned = [];

  bool ready = false;

  @override
  void initState() {
    super.initState();

    camera = PerspectiveCamera(
      position: Vector3(0, 0, 5),
      target: Vector3.zero(),
    );

    controller = FlyCameraController(camera);

    Scene.initializeStaticResources().then((_) async {
      await _loadProjectScene();
      if (mounted) setState(() => ready = true);
    });

    _ticker = createTicker((_) {
      controller.update();
      if (ready && mounted) setState(() {});
    })..start();
  }

  Future<void> _loadProjectScene() async {
    for (final n in _spawned) {
      scene.remove(n);
    }
    _spawned.clear();

    final project = ProjectStore.instance.project;
    if (project == null || project.scenes.isEmpty) return;

    final root = project.scenes.first.rootObjects;

    for (final go in root) {
      if (go.assetId == null) continue;

      final asset = project.assets.firstWhere(
        (a) => a.id == go.assetId,
        orElse: () => Asset(id: '', path: '', type: ''),
      );
      if (asset.path.isEmpty) continue;

      try {
        final node = await ModelImport.loadModel('${ProjectStore.instance.projectPath}\\${asset.path}');

        node.localTransform = Matrix4.compose(
          Vector3(
            go.transform.position.x,
            go.transform.position.y,
            go.transform.position.z,
          ),
          Quaternion.euler(
            radians(go.transform.rotation.x),
            radians(go.transform.rotation.y),
            radians(go.transform.rotation.z),
          ),
          Vector3(
            go.transform.scale.x,
            go.transform.scale.y,
            go.transform.scale.z,
          ),
        );

        scene.add(node);
        _spawned.add(node);
      } catch (e) {
        debugPrint('Error loading model: $e');
      }
    }
  }

  @override
  void dispose() {
    for (final n in _spawned) {
      scene.remove(n);
    }
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!ready) {
      return const Center(child: CircularProgressIndicator());
    }

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) controller.onKeyDown(event.logicalKey);
        if (event is KeyUpEvent) controller.onKeyUp(event.logicalKey);
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
