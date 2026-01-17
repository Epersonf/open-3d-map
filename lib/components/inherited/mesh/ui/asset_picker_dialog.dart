import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart'; // Import para gerar ID novo
import '../../../../stores/project_store.dart';
import '../../../../domain/asset/asset.dart';

class AssetPickerDialog extends StatefulWidget {
  final List<String> allowedExtensions;

  const AssetPickerDialog({
    super.key,
    this.allowedExtensions = const ['.glb', '.gltf', '.obj', '.fbx'],
  });

  @override
  State<AssetPickerDialog> createState() => _AssetPickerDialogState();
}

class _AssetPickerDialogState extends State<AssetPickerDialog> {
  late Directory _currentDir;
  late String _rootDir;

  @override
  void initState() {
    super.initState();
    final storeRoot = ProjectStore.instance.assetsRoot;
    if (storeRoot == null) {
      // Fallback de segurança, embora não deva acontecer se projeto estiver aberto
      _rootDir = Directory.current.path;
    } else {
      _rootDir = storeRoot;
    }
    _currentDir = Directory(_rootDir);
  }

  void _navigateUp() {
    final parent = _currentDir.parent;
    // Impede subir além da pasta root de assets
    if (p.isWithin(_rootDir, _currentDir.path) || p.equals(_rootDir, _currentDir.path)) {
      if (!p.equals(_rootDir, _currentDir.path)) {
        setState(() {
          _currentDir = parent;
        });
      }
    }
  }

  void _navigateDown(Directory dir) {
    setState(() {
      _currentDir = dir;
    });
  }

  void _selectFile(File file) {
    final projectStore = ProjectStore.instance;
    final projectPath = projectStore.projectPath;
    if (projectPath == null) return;

    final relativePath = p.relative(file.path, from: projectPath);
    final project = projectStore.project;
    if (project == null) return;

    try {
      // Tenta achar asset existente
      final asset = project.assets.firstWhere((a) => a.path == relativePath);
      Navigator.of(context).pop(asset.id);
    } catch (_) {
      // --- REGISTRO AUTOMÁTICO ---
      // Se não achou, cria um novo Asset, adiciona ao projeto e retorna o novo ID
      final newId = const Uuid().v4();
      final extension = p.extension(file.path).replaceAll('.', '');
      
      final newAsset = Asset(
        id: newId,
        path: relativePath,
        type: extension,
      );

      project.assets.add(newAsset);
      
      // Opcional: Salvar o projeto automaticamente para persistir a mudança
      // projectStore.saveProject(); 

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('New asset registered: ${p.basename(file.path)}')),
      );

      Navigator.of(context).pop(newId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<FileSystemEntity> entities;
    try {
      entities = _currentDir.listSync()
        ..sort((a, b) {
          final aDir = a is Directory;
          final bDir = b is Directory;
          if (aDir && !bDir) return -1;
          if (!aDir && bDir) return 1;
          return a.path.toLowerCase().compareTo(b.path.toLowerCase());
        });
    } catch (e) {
      return Center(child: Text("Error: $e", style: const TextStyle(color: Colors.red)));
    }

    // Filtra pastas e arquivos 3D
    final filtered = entities.where((e) {
      if (e is Directory) return true;
      if (e is File) {
        final ext = p.extension(e.path).toLowerCase();
        return widget.allowedExtensions.contains(ext);
      }
      return false;
    }).toList();

    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SizedBox(
        width: 500,
        height: 600,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white10)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_upward, color: Colors.white70),
                    onPressed: p.equals(_rootDir, _currentDir.path) ? null : _navigateUp,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      p.basename(_currentDir.path), // Mostra nome da pasta atual
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
            ),
            
            // Lista
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text("No 3D files found", style: TextStyle(color: Colors.white24)))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final entity = filtered[i];
                        final name = p.basename(entity.path);
                        final isDir = entity is Directory;

                        return ListTile(
                          leading: Icon(
                            isDir ? Icons.folder : Icons.view_in_ar,
                            color: isDir ? Colors.amber : Colors.blueAccent,
                          ),
                          title: Text(name, style: const TextStyle(color: Colors.white)),
                          onTap: () {
                            if (isDir) {
                              _navigateDown(entity);
                            } else {
                              _selectFile(entity as File);
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
