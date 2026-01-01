import 'package:flutter/material.dart';
import 'package:open_3d_mapper/presentation/components/file_explorer/file_explorer.dart';
import 'presentation/components/layout/top_bar.dart';
import 'presentation/components/inspector/inspector_panel.dart';
import 'presentation/components/hierarchy/hierarchy_panel.dart';
import 'stores/project_store.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'O3M',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: ColorScheme.fromSwatch(brightness: Brightness.dark),
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const TopBar(),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  content: const Text('Funcionando no desktop!'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('Fechar'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: const Text('Mostrar diálogo'),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: AnimatedBuilder(
                                animation: ProjectStore.instance,
                                builder: (ctx, _) {
                                  if (ProjectStore.instance.projectPath != null) {
                                    return const Center(child: Text('Viewport / Scene area', style: TextStyle(color: Colors.white70)));
                                  }
                                  return const Center(child: Text('No project opened', style: TextStyle(color: Colors.white54)));
                                },
                              ),
                            ),
                            // hierarchy panel (only when project open)
                            AnimatedBuilder(
                              animation: ProjectStore.instance,
                              builder: (ctx, _) {
                                if (ProjectStore.instance.projectPath != null) {
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: SizedBox(width: 300, child: const HierarchyPanel()),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                            // inspector panel (only when project open)
                            AnimatedBuilder(
                              animation: ProjectStore.instance,
                              builder: (ctx, _) {
                                if (ProjectStore.instance.projectPath != null) {
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: SizedBox(width: 320, child: const InspectorPanel()),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                const FileExplorer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
