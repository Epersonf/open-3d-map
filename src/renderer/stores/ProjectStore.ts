import { makeAutoObservable, runInAction } from 'mobx'

export class ProjectStore {
  currentProjectPath?: string
  projectData: unknown | null = null
  loading: boolean = false
  error?: string

  constructor() {
    makeAutoObservable(this)
  }

  async openProject(path?: string) {
    this.loading = true
    this.error = undefined
    try {
      // If no path provided, ask main process to select a folder
      const folder =
        path || (window as any).electronAPI?.selectProjectFolder?.() || undefined

      if (!folder) {
        runInAction(() => {
          this.loading = false
        })
        return
      }

      // Try to read index.json via Electron API (if available)
      const json =
        (await (window as any).electronAPI?.readIndexJson?.(folder)) || null

      runInAction(() => {
        this.currentProjectPath = folder
        this.projectData = json
        this.loading = false
      })
    } catch (e: any) {
      runInAction(() => {
        this.error = String(e)
        this.loading = false
      })
    }
  }

  async createNewProject(path: string, name: string) {
    this.loading = true
    try {
      const created = await (window as any).electronAPI?.createProject?.(path, name)
      runInAction(() => {
        this.currentProjectPath = created || path
        this.projectData = null
        this.loading = false
      })
    } catch (e: any) {
      runInAction(() => {
        this.error = String(e)
        this.loading = false
      })
    }
  }

  closeProject() {
    this.currentProjectPath = undefined
    this.projectData = null
    this.loading = false
    this.error = undefined
  }
}

export default ProjectStore
