import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../../../stores/project_store.dart';

class FileExplorer extends StatelessWidget {
  const FileExplorer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      decoration: const BoxDecoration(
        color: Color(0xFF0B0B0B),
        border: Border(top: BorderSide(color: Color(0xFF222222))),
      ),
      child: AnimatedBuilder(
        animation: ProjectStore.instance,
        builder: (context, _) {
          final store = ProjectStore.instance;
          if (store.projectPath == null || store.assetsRoot == null) {
            return const Center(child: Text('No project opened', style: TextStyle(color: Colors.white70)));
          }

          final current = store.currentPath ?? store.assetsRoot!;

          final entries = store.entries;
          final folders = entries.where((e) => FileSystemEntity.isDirectorySync(e.path)).toList();
          final files = entries.where((e) => !FileSystemEntity.isDirectorySync(e.path)).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // top bar with path and controls
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                color: const Color(0xFF141414),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(current, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ),
                    IconButton(
                      tooltip: 'Up',
                      onPressed: () async {
                        // disable if at assets root
                        if (p.normalize(current) == p.normalize(store.assetsRoot!)) return;
                        await store.cdUp();
                      },
                      icon: Icon(Icons.arrow_upward, color: p.normalize(current) == p.normalize(store.assetsRoot!) ? Colors.white24 : Colors.white70),
                    ),
                    IconButton(
                      tooltip: 'Reload',
                      onPressed: () async => await store.reload(),
                      icon: const Icon(Icons.refresh, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      // folders list
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Folders', style: TextStyle(color: Colors.white70)),
                            const SizedBox(height: 6),
                            Expanded(
                              child: folders.isEmpty
                                  ? const Text('No folders', style: TextStyle(color: Colors.white54))
                                  : ListView.builder(
                                      itemCount: folders.length,
                                      itemBuilder: (ctx, i) {
                                        final f = folders[i];
                                        final name = p.basename(f.path);
                                        return GestureDetector(
                                          onDoubleTap: () async => await store.cdInto(f.path),
                                          child: ListTile(
                                            dense: true,
                                            leading: const Icon(Icons.folder, color: Colors.white70),
                                            title: Text(name, style: const TextStyle(color: Colors.white)),
                                            onTap: () async {
                                              await store.cdInto(f.path);
                                            },
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                      const VerticalDivider(color: Color(0xFF222222)),
                      // files list
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Files', style: TextStyle(color: Colors.white70)),
                            const SizedBox(height: 6),
                            Expanded(
                              child: files.isEmpty
                                  ? const Text('No files', style: TextStyle(color: Colors.white54))
                                  : ListView.builder(
                                      itemCount: files.length,
                                      itemBuilder: (ctx, i) {
                                        final f = files[i];
                                        final name = p.basename(f.path);
                                        return GestureDetector(
                                            onDoubleTap: () async {
                                            final ext = p.extension(f.path).toLowerCase().replaceFirst('.', '');
                                            // Only GLB is supported for import into the scene
                                            const supported = ['glb'];
                                            if (supported.contains(ext)) {
                                              await ProjectStore.instance.addAssetAsGameObject(f.path);
                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added $name to scene')));
                                            } else {
                                              // open default
                                              // ignore: avoid_slow_async_io
                                              Process.run('explorer', [f.path]);
                                            }
                                          },
                                          child: ListTile(
                                            dense: true,
                                            leading: const Icon(Icons.insert_drive_file, color: Colors.white70),
                                            title: Text(name, style: const TextStyle(color: Colors.white)),
                                            onTap: () {
                                              // open containing folder in explorer and select file
                                              // ignore: avoid_slow_async_io
                                              Process.run('explorer', [f.path]);
                                            },
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
