import { makeAutoObservable, runInAction } from 'mobx'

export interface AssetFile {
  name: string
  path: string
  type: 'file' | 'folder'
  size?: number
  modified?: string
}

export class AssetsStore {
  assets: AssetFile[] = []
  currentAssetPath: string = ''
  loading: boolean = false
  error?: string

  constructor() {
    makeAutoObservable(this)
  }

  async loadAssets(projectPath: string) {
    if (!projectPath) {
      this.error = 'No project path'
      return
    }

    this.loading = true
    this.error = undefined
    this.currentAssetPath = projectPath

    try {
      const files = await (window as any).electronAPI?.listAssets?.(projectPath)
      runInAction(() => {
        this.assets = files || []
        this.loading = false
      })
    } catch (e: any) {
      runInAction(() => {
        this.error = String(e?.message || e)
        this.loading = false
      })
    }
  }

  clearAssets() {
    this.assets = []
    this.currentAssetPath = ''
    this.error = undefined
  }
}

export default AssetsStore
