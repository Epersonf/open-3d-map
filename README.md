# 3D Level Editor

A professional desktop application for creating and editing 3D game levels, built with Next.js, Electron, Three.js, and MobX following Domain-Driven Design principles.

## Features

- **3D Viewport** with orbit controls and transform gizmos
- **Hierarchy Panel** for managing scene objects with drag-and-drop
- **Inspector Panel** for editing object properties and transforms
- **Project Management** with file system integration via Electron
- **Transform Tools** (Translate, Rotate, Scale) with local/global space
- **Tag System** for flexible object metadata
- **Interoperable JSON Format** for cross-engine compatibility

## Architecture

The application follows a clean DDD architecture with clear separation:

- **Domain Layer**: Pure entities (Project, Scene, GameObject, Transform)
- **Application Layer**: Services and use cases
- **Infrastructure Layer**: Adapters for Three.js, file system, and state management
- **Presentation Layer**: React components with MobX for reactivity

## Getting Started

### Development

```bash
# Install dependencies
npm install

# Run Next.js dev server
npm run dev:next

# In another terminal, run Electron
npm run dev:electron

# Or run both concurrently
npm run dev
```

### Building

```bash
# Build Next.js app
npm run build

# Package Electron app for distribution
npm run build:electron
```

## Project Structure

```
├── app/                    # Next.js app directory
├── components/
│   └── editor/            # Editor UI components
├── electron/              # Electron main process
├── lib/
│   ├── domain/           # Domain entities
│   ├── application/      # Services and use cases
│   ├── infrastructure/   # Adapters and repositories
│   ├── rendering/        # Three.js rendering
│   └── stores/           # MobX stores
└── types/                # TypeScript definitions
```

## Technology Stack

- **Next.js 16** - React framework with App Router
- **Electron 39** - Desktop application framework
- **Three.js 0.182** - 3D rendering engine
- **MobX 6** - Reactive state management
- **TypeScript** - Type safety
- **Tailwind CSS v4** - Styling
- **shadcn/ui** - UI components

## License

MIT
