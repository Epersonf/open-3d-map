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
      const folder = path || (await (window as any).electronAPI?.openProjectDialog?.())

      if (!folder) {
        runInAction(() => {
          this.loading = false
        })
        return
      }

      // Load index.json from the folder
      const json = await (window as any).electronAPI?.loadProject?.(folder)

      runInAction(() => {
        this.currentProjectPath = folder
        this.projectData = json
        this.loading = false
      })
    } catch (e: any) {
      runInAction(() => {
        this.error = String(e?.message || e)
        this.loading = false
      })
    }
  }

  async createNewProject(projectName?: string, basePath?: string) {
    this.loading = true
    this.error = undefined
    try {
      // Use provided name or abort if not given
      if (!projectName || !projectName.trim()) {
        runInAction(() => {
          this.error = 'Project name is required'
          this.loading = false
        })
        return
      }

      // Ask user to select base folder for the project
      let folderPath = basePath
      if (!folderPath) {
        folderPath = await (window as any).electronAPI?.openProjectDialog?.()
        if (!folderPath) {
          runInAction(() => { this.loading = false })
          return
        }
      }

      // Create the project via Electron API
      const projectFolder = await (window as any).electronAPI?.createProject?.(projectName, folderPath)

      if (projectFolder) {
        // Load the newly created project
        const json = await (window as any).electronAPI?.loadProject?.(projectFolder)

        runInAction(() => {
          this.currentProjectPath = projectFolder
          this.projectData = json
          this.loading = false
        })
      }
    } catch (e: any) {
      runInAction(() => {
        this.error = String(e?.message || e)
        this.loading = false
      })
    }
  }

  async saveProject() {
    if (!this.currentProjectPath || !this.projectData) {
      this.error = 'No project loaded to save'
      return
    }

    this.loading = true
    this.error = undefined
    try {
      await (window as any).electronAPI?.saveProject?.(this.currentProjectPath, this.projectData)
      runInAction(() => {
        this.loading = false
      })
    } catch (e: any) {
      runInAction(() => {
        this.error = String(e?.message || e)
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
