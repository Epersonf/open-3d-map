import type { Project } from "@/lib/domain/entities/project"

export interface IProjectRepository {
  create(path: string, project: Project): Promise<void>
  load(path: string): Promise<Project>
  save(path: string, project: Project): Promise<void>
  saveAs(project: Project): Promise<string>
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
