import { contextBridge, ipcRenderer } from "electron"

contextBridge.exposeInMainWorld("electronAPI", {
  project: {
    create: (path, data) => ipcRenderer.invoke("project:create", path, data),
    open: () => ipcRenderer.invoke("project:open"),
    save: (path, data) => ipcRenderer.invoke("project:save", path, data),
    saveAs: (data) => ipcRenderer.invoke("project:saveAs", data),
  },
  asset: {
    import: () => ipcRenderer.invoke("asset:import"),
  },
})
