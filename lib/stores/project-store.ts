import { makeAutoObservable, runInAction } from "mobx"
import type { RootStore } from "./root-store"
import type { Project } from "@/lib/domain/entities/project"
import { ProjectService } from "@/lib/application/services/project-service"
import { ElectronProjectRepository } from "@/lib/infrastructure/repositories/project-repository"

export class ProjectStore {
  currentProject: Project | null = null
  projectPath: string | null = null
  private projectService: ProjectService
  private projectRepository: ElectronProjectRepository

  constructor(private rootStore: RootStore) {
    makeAutoObservable(this)
    this.projectService = new ProjectService()
    this.projectRepository = new ElectronProjectRepository()
  }

  async createNewProject(name: string) {
    try {
      const project = this.projectService.createNewProject(name)
      runInAction(() => {
        this.currentProject = project
        this.projectPath = null

        // Set active scene in scene store
        const activeScene = project.getActiveScene()
        if (activeScene) {
          this.rootStore.sceneStore.setCurrentScene(activeScene)
        }
      })
    } catch (error) {
      console.error("[v0] Failed to create project:", error)
      throw error
    }
  }

  async openProject() {
    try {
      const project = await this.projectRepository.load()
      runInAction(() => {
        this.currentProject = project
        // Path would be set by the repository, but for now we'll leave it null
        this.projectPath = null

        // Set active scene
        const activeScene = project.getActiveScene()
        if (activeScene) {
          this.rootStore.sceneStore.setCurrentScene(activeScene)
        }
      })
    } catch (error) {
      console.error("[v0] Failed to open project:", error)
      throw error
    }
  }

  async saveProject() {
    if (!this.currentProject || !this.projectPath) {
      return this.saveProjectAs()
    }

    try {
      await this.projectRepository.save(this.projectPath, this.currentProject)
    } catch (error) {
      console.error("[v0] Failed to save project:", error)
      throw error
    }
  }

  async saveProjectAs() {
    if (!this.currentProject) {
      throw new Error("No project to save")
    }

    try {
      const path = await this.projectRepository.saveAs(this.currentProject)
      runInAction(() => {
        this.projectPath = path
      })
    } catch (error) {
      console.error("[v0] Failed to save project:", error)
      throw error
    }
  }

  setCurrentProject(project: Project, path: string | null = null) {
    this.currentProject = project
    this.projectPath = path
  }

  clearProject() {
    this.currentProject = null
    this.projectPath = null
  }
}
