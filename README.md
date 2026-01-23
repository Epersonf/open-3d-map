# O3M - Open 3D Mapper

O3M is an open-source, generic 3D level editor built with Flutter.

The concept is simple: What Tiled is for 2D games, O3M aims to be for 3D games. It provides a lightweight, engine-agnostic environment to place assets, define properties, and export scene data (JSON) that can be easily imported into any game engine (Godot, Unity, Bevy, Custom C++ Engines, etc.).

## ✨ Features

Engine Agnostic: Scenes are saved as clean, readable JSON files. Write a simple parser and load your levels anywhere.

Component-Based Architecture: Add functional data to objects (Colliders, Lights, Meshes, Custom Tags) via a Unity-like Inspector.

Multi-Scene Workflow: Create, duplicate, and switch between multiple scenes within a single project.

Asset Management: Supports standard 3D formats (.glb, .gltf, .obj, .fbx).

Visual Editor:

Gizmos: Move, Rotate, and Scale objects visually.

Snapping: Grid snapping for precision placement.

Hierarchy: Parent/Child relationships and grouping.

Free Camera: WASD + Mouse navigation.

Cross-Platform: Runs on Windows, macOS, and Linux (Web support experimental).

## 🚀 Getting Started

Prerequisites

Flutter SDK (Latest Stable)

Dart SDK

Installation

Clone the repository:

git clone [https://github.com/yourusername/open_3d_mapper.git](https://github.com/yourusername/open_3d_mapper.git)
cd open_3d_mapper


Install dependencies:

>flutter pub get


### Run the application:

#### For Windows
>flutter run -d windows

#### For macOS
>flutter run -d macos

#### For Linux
>flutter run -d linux


## 🎮 Controls

Action

Input

Camera Look

Hold Right Mouse Button + Move Mouse

Move Camera

W, A, S, D (while holding Right Click)

Move Up/Down

Q, E (while holding Right Click)

Sprint

Hold Shift

Select Object

Left Click

Focus Object

F

Tool: Move

W

Tool: Scale

E

Tool: Rotate

R

Toggle Local/Global

Interface Button

## 🛠️ Architecture

O3M is built using a clean, reactive architecture:

Framework: Flutter (UI) + three_js (3D Rendering).

State Management: MobX (Reactive stores for Selection, Project, and Tools).

Data Structure:

Project: Contains Assets and Scene metadata.

Scene: Contains a hierarchy of GameObjects.

GameObject: Pure Entity containing a list of Components.

Components: Logic blocks (e.g., TransformComponent, MeshComponent, LightComponent).

## 📂 Project Structure

When you save a project, O3M creates a folder structure designed for version control friendliness:

MyGameProject/
├── project.o3m       # Main manifest file (Project settings)
├── assets/           # Your 3D models (.glb, .obj)
└── scenes/           # Individual Scene data files
    ├── main_level.json
    ├── dungeon.json
    └── shop.json


JSON Export Example

Your game engine only needs to parse this JSON structure:

{
  "id": "scene-uuid-1234",
  "name": "Dungeon Level 1",
  "rootObjects": [
    {
      "id": "obj-uuid-5678",
      "name": "PlayerStart",
      "components": {
        "transform": {
          "position": {"x": 10.0, "y": 0.0, "z": 5.0},
          "rotation": {"x": 0.0, "y": 90.0, "z": 0.0},
          "scale": {"x": 1.0, "y": 1.0, "z": 1.0}
        },
        "tags": {
          "tags": {"type": "spawn_point"}
        },
        "icon": {
          "iconName": "flag",
          "color": 16777215
        }
      }
    }
  ]
}


## 🗺️ Roadmap

[ ] Undo/Redo System.

[ ] Prefab system (instancing saved objects).

[ ] Custom Component definitions (define data schemas in JSON).

[ ] Terrain Editor.

[ ] Texture/Material swapping.

## 🤝 Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are greatly appreciated.

Fork the Project.

Create your Feature Branch (git checkout -b feature/AmazingFeature).

Commit your Changes (git commit -m 'Add some AmazingFeature').

Push to the Branch (git push origin feature/AmazingFeature).

Open a Pull Request.

## 📝 License

Distributed under the MIT License. See LICENSE for more information.

Built with ❤️ using Flutter.