import type { Project } from "@/lib/domain/entities/project"

export interface IProjectRepository {
  create(path: string, project: Project): Promise<void>
  load(path: string): Promise<Project>
  save(path: string, project: Project): Promise<void>
  saveAs(project: Project): Promise<string>
}
// Browser fallback repository (for non-Electron environments)
class BrowserProjectRepository implements IProjectRepository {
  async create(path: string, project: Project): Promise<void> {
    console.log("Browser: Simulando criação de projeto no caminho:", path)
    localStorage.setItem('current-project', JSON.stringify((project as any).toJSON ? (project as any).toJSON() : project))
    localStorage.setItem('project-path', path)
  }

  async load(path?: string): Promise<Project> {
    console.log("Browser: Carregando projeto...")

    const projectData = localStorage.getItem('current-project')
    if (projectData) {
      try {
        const { Project: ProjectClass } = await import('@/lib/domain/entities/project')
        return ProjectClass.fromJSON(JSON.parse(projectData))
      } catch (error) {
        console.error('Erro ao carregar projeto do localStorage:', error)
      }
    }

    // Create example project if none found
    return this.createExampleProject()
  }

  async save(path: string, project: Project): Promise<void> {
    console.log('Browser: Salvando projeto...')
    localStorage.setItem('current-project', JSON.stringify((project as any).toJSON ? (project as any).toJSON() : project))
    localStorage.setItem('project-path', path)
  }

  async saveAs(project: Project): Promise<string> {
    const path = `project-${Date.now()}.json`
    await this.save(path, project)
    return path
  }

  private createExampleProject(): Project {
    // Use require to avoid circular ESM import problems at runtime in the browser
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    const { Project: ProjectClass } = require('@/lib/domain/entities/project')
    const { Scene: SceneClass } = require('@/lib/domain/entities/scene')
    const { GameObject: GameObjectClass } = require('@/lib/domain/entities/game-object')
    const { Transform: TransformClass } = require('@/lib/domain/entities/transform')
    const { Vector3: Vector3Class } = require('@/lib/domain/entities/vector3')

    const exampleScene = new SceneClass({
      name: 'Example Scene',
      rootObjects: [
        new GameObjectClass({
          name: 'Main Camera',
          transform: new TransformClass(
            new Vector3Class(0, 5, 10),
            new Vector3Class(-20, 0, 0)
          ),
        }),
        new GameObjectClass({
          name: 'Cube',
          transform: new TransformClass(new Vector3Class(0, 1, 0)),
        }),
        new GameObjectClass({
          name: 'Ground',
          transform: new TransformClass(
            new Vector3Class(0, 0, 0),
            new Vector3Class(0, 0, 0),
            new Vector3Class(10, 0.1, 10)
          ),
        }),
      ],
    })

    return new ProjectClass({
      name: 'Example Project',
      version: '1.0.0',
      scenes: [exampleScene],
      tags: ['example', 'demo'],
    })
  }
}

export class ElectronProjectRepository implements IProjectRepository {
  async create(path: string, project: Project): Promise<void> {
    if (typeof window === "undefined" || !window.electronAPI) {
      throw new Error("Electron API not available")
    }

    const result = await window.electronAPI.project.create(path, project.toJSON())

    if (!result.success) {
      throw new Error(result.error || "Failed to create project")
    }
  }

  async load(path?: string): Promise<Project> {
    if (typeof window === "undefined" || !window.electronAPI) {
      throw new Error("Electron API not available")
    }

    const result = await window.electronAPI.project.open()

    if (!result.success) {
      if (result.canceled) {
        throw new Error("User canceled project open")
      }
      throw new Error(result.error || "Failed to load project")
    }

    const { Project: ProjectClass } = await import("@/lib/domain/entities/project")
    return ProjectClass.fromJSON(result.data)
  }

  async save(path: string, project: Project): Promise<void> {
    if (typeof window === "undefined" || !window.electronAPI) {
      throw new Error("Electron API not available")
    }

    const result = await window.electronAPI.project.save(path, project.toJSON())

    if (!result.success) {
      throw new Error(result.error || "Failed to save project")
    }
  }

  async saveAs(project: Project): Promise<string> {
    if (typeof window === "undefined" || !window.electronAPI) {
      throw new Error("Electron API not available")
    }

    const result = await window.electronAPI.project.saveAs(project.toJSON())

    if (!result.success) {
      if (result.canceled) {
        throw new Error("User canceled save")
      }
      throw new Error(result.error || "Failed to save project")
    }

    return result.path!
  }
}

// Factory to pick repository implementation
export class ProjectRepositoryFactory {
  static create(): IProjectRepository {
    if (typeof window !== 'undefined' && (window as any).electronAPI) {
      console.log('Usando ElectronProjectRepository')
      return new ElectronProjectRepository()
    }
    console.log('Usando BrowserProjectRepository (fallback)')
    return new BrowserProjectRepository()
  }
}

export const ElectronProjectRepositoryInstance = ProjectRepositoryFactory.create()
