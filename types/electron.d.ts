export interface ElectronAPI {
  project: {
    create: (path: string, data: any) => Promise<{ success: boolean; path?: string; error?: string }>
    open: () => Promise<{ success: boolean; data?: any; path?: string; error?: string; canceled?: boolean }>
    save: (path: string, data: any) => Promise<{ success: boolean; error?: string }>
    saveAs: (data: any) => Promise<{ success: boolean; path?: string; error?: string; canceled?: boolean }>
  }
  asset: {
    import: () => Promise<{
      success: boolean
      fileName?: string
      data?: string
      path?: string
      error?: string
      canceled?: boolean
    }>
  }
}

declare global {
  interface Window {
    electronAPI: ElectronAPI
  }
}
