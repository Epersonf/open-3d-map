const { contextBridge, ipcRenderer } = require('electron')

contextBridge.exposeInMainWorld('electronAPI', {
  // Generic IPC
  send: (channel, data) => ipcRenderer.send(channel, data),
  on: (channel, fn) => ipcRenderer.on(channel, (event, ...args) => fn(...args)),

  // Project management
  openProjectDialog: () => ipcRenderer.invoke('open-project-dialog'),
  createProject: (projectName, projectPath) =>
    ipcRenderer.invoke('create-project', { projectName, projectPath }),
  loadProject: (projectPath) => ipcRenderer.invoke('load-project', projectPath),
  saveProject: (projectPath, projectData) =>
    ipcRenderer.invoke('save-project', { projectPath, projectData })
})
