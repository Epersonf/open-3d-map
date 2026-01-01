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
        final selected = await FilePicker.platform.getDirectoryPath();
        if (selected == null) {
          messenger.showSnackBar(const SnackBar(content: Text('Open cancelled')));
          return;
        }

        final indexFile = File(p.join(selected, 'index.json'));
        if (!await indexFile.exists()) {
          messenger.showSnackBar(SnackBar(content: Text('index.json not found in: $selected')));
          return;
        }

        final content = await indexFile.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        final project = Project.fromJson(json);
        messenger.showSnackBar(SnackBar(content: Text('Project opened: ${project.name}')));
        ProjectStore.instance.setProject(project, selected);
        // ignore: avoid_print
        print('Opened project at $selected:\n${project.toJson()}');
        return;
      }

      if (value == 'new') {
        final name = await _askForProjectName(context);
        if (name == null || name.trim().isEmpty) {
          messenger.showSnackBar(const SnackBar(content: Text('Project creation cancelled')));
          return;
        }

        final parent = await FilePicker.platform.getDirectoryPath();
        if (parent == null) {
          messenger.showSnackBar(const SnackBar(content: Text('No folder selected')));
          return;
        }

        final projectDir = Directory(p.join(parent, name));
        if (!await projectDir.exists()) {
          await projectDir.create(recursive: true);
        }

        final assetsDir = Directory(p.join(projectDir.path, 'assets'));
        if (!await assetsDir.exists()) await assetsDir.create(recursive: true);

        final project = Project.createNew(name);
        final indexFile = File(p.join(projectDir.path, 'index.json'));
        await indexFile.writeAsString(const JsonEncoder.withIndent('  ').convert(project.toJson()));
        ProjectStore.instance.setProject(project, projectDir.path);
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
          const Text(
            'O3M',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
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
