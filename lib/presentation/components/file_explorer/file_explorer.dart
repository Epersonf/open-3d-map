import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../../../stores/project_store.dart';

class FileExplorer extends StatelessWidget {
  const FileExplorer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: const BoxDecoration(
        color: Color(0xFF0B0B0B),
        border: Border(top: BorderSide(color: Color(0xFF222222))),
      ),
      child: AnimatedBuilder(
        animation: ProjectStore.instance,
        builder: (context, _) {
          final store = ProjectStore.instance;
          if (store.projectPath == null) {
            return const Center(child: Text('No project opened', style: TextStyle(color: Colors.white70)));
          }
          final assets = store.assets;
          if (assets.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(12),
              child: Text('No assets found in assets/ folder', style: TextStyle(color: Colors.white70)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: assets.length,
            itemBuilder: (ctx, i) {
              final f = assets[i];
              final relative = p.relative(f.path, from: store.projectPath!);
              final isDir = FileSystemEntity.isDirectorySync(f.path);
              return ListTile(
                dense: true,
                leading: Icon(isDir ? Icons.folder : Icons.insert_drive_file, color: Colors.white70),
                title: Text(relative, style: const TextStyle(color: Colors.white)),
                subtitle: isDir ? const Text('Folder', style: TextStyle(color: Colors.white54)) : null,
                onTap: () {
                  if (!isDir) {
                    // for now, open with default app
                    // ignore: avoid_slow_async_io
                    Process.run('explorer', [f.path]);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
