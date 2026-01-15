import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../../../domain/project/project.dart';
import '../../../stores/project_store.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key});

  Future<void> _onSelected(BuildContext context, String value) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (value == 'save') {
        if (ProjectStore.instance.project == null) {
          messenger.showSnackBar(const SnackBar(content: Text('No project to save')));
          return;
        }
        await ProjectStore.instance.saveProject();
        messenger.showSnackBar(const SnackBar(content: Text('Project saved')));
        return;
      }
      if (value == 'open') {
        // Now pick a FILE (supports .o3m and .json for backward compatibility)
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['o3m', 'json'],
          dialogTitle: 'Open O3M Project',
        );

        if (result == null || result.files.isEmpty) {
          messenger.showSnackBar(const SnackBar(content: Text('Open cancelled')));
          return;
        }

        final filePath = result.files.single.path!;
        final file = File(filePath);
        final fileName = p.basename(filePath);

        final projectRoot = p.dirname(filePath);

        if (!await file.exists()) {
          messenger.showSnackBar(SnackBar(content: Text('File not found: $filePath')));
          return;
        }

        final content = await file.readAsString();
        try {
          final json = jsonDecode(content) as Map<String, dynamic>;
          final project = Project.fromJson(json);
          messenger.showSnackBar(SnackBar(content: Text('Project opened: ${project.name}')));

          // Pass both the inferred directory and the filename to the store
          ProjectStore.instance.setProject(project, projectRoot, fileName: fileName);

          // ignore: avoid_print
          print('Opened project at $projectRoot (file: $fileName)');
        } catch (e) {
          messenger.showSnackBar(SnackBar(content: Text('Invalid project file: $e')));
        }
        return;
      }

      if (value == 'new') {
        final name = await _askForProjectName(context);
        if (name == null || name.trim().isEmpty) {
          messenger.showSnackBar(const SnackBar(content: Text('Project creation cancelled')));
          return;
        }

        // Choose parent folder for the project
        final parentPath = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Select Parent Folder for New Project');
        if (parentPath == null) {
          messenger.showSnackBar(const SnackBar(content: Text('No folder selected')));
          return;
        }

        final projectDir = Directory(p.join(parentPath, name));
        if (!await projectDir.exists()) {
          await projectDir.create(recursive: true);
        }

        final assetsDir = Directory(p.join(projectDir.path, 'assets'));
        if (!await assetsDir.exists()) await assetsDir.create(recursive: true);

        final project = Project.createNew(name);

        // Use .o3m as default project filename
        const defaultFileName = 'project.o3m';
        final projectFile = File(p.join(projectDir.path, defaultFileName));
        await projectFile.writeAsString(const JsonEncoder.withIndent('  ').convert(project.toJson()));

        ProjectStore.instance.setProject(project, projectDir.path, fileName: defaultFileName);

        messenger.showSnackBar(SnackBar(content: Text('Project created at ${projectDir.path}')));
        // ignore: avoid_print
        print('Created project at ${projectDir.path}');
        return;
      }

      if (value == 'export') {
        messenger.showSnackBar(const SnackBar(content: Text('Export project (stub)')));
        return;
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<String?> _askForProjectName(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('New Project'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Project name'),
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.of(ctx).pop(controller.text.trim()), child: const Text('Create')),
          ],
        );
      },
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B1B),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Row(
            children: [
              Image.asset('assets/logo.png', height: 32, errorBuilder: (ctx, err, st) => const SizedBox.shrink()),
            ],
          ),
          const SizedBox(width: 20),
          PopupMenuButton<String>(
            onSelected: (v) => _onSelected(context, v),
            color: const Color(0xFF2A2A2A),
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'new', child: Text('New')),
              PopupMenuItem(value: 'open', child: Text('Open')),
              PopupMenuItem(value: 'save', child: Text('Save')),
              // PopupMenuItem(value: 'export', child: Text('Export')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: const [
                  Icon(Icons.folder_open, color: Colors.white70, size: 18),
                  SizedBox(width: 8),
                  Text('Project', style: TextStyle(color: Colors.white70)),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_drop_down, color: Colors.white70),
                ],
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
