const { app, BrowserWindow, dialog, ipcMain } = require('electron')
const path = require('path')
const fs = require('fs').promises
const fsSync = require('fs')

function createWindow() {
  const win = new BrowserWindow({
    width: 900,
    height: 700,
    show: false,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
    }
  })

  const devUrl = 'http://localhost:3000/'

  // Try to load dev server first; on success show the window and open devtools.
  win.loadURL(devUrl).then(() => {
    win.show()
    try { win.webContents.openDevTools({ mode: 'detach' }) } catch (e) {}
  }).catch(() => {
    // Fallback to built index.html when dev server isn't available
    win.loadFile(path.join(__dirname, '..', 'dist', 'index.html')).then(() => {
      win.show()
    }).catch((err) => {
      // If even the file can't be loaded, still show an empty window so the user sees the app
      console.error('Failed to load content:', err)
      win.show()
    })
  })
}

app.whenReady().then(createWindow)
app.on('window-all-closed', () => { if (process.platform !== 'darwin') app.quit() })
app.on('activate', () => { if (BrowserWindow.getAllWindows().length === 0) createWindow() })

// IPC Handlers
ipcMain.handle('open-project-dialog', async () => {
  const { canceled, filePaths } = await dialog.showOpenDialog({
    properties: ['openDirectory']
  })
  if (canceled) return null
  return filePaths[0] || null
})

ipcMain.handle('create-project', async (event, { projectName, projectPath }) => {
  try {
    const projectFolder = path.join(projectPath, projectName)
    
    // Create project folder if it doesn't exist
    if (!fsSync.existsSync(projectFolder)) {
      fsSync.mkdirSync(projectFolder, { recursive: true })
    }

    // Create assets folder
    const assetsFolder = path.join(projectFolder, 'assets')
    if (!fsSync.existsSync(assetsFolder)) {
      fsSync.mkdirSync(assetsFolder, { recursive: true })
    }

    // Create index.json with initial structure
    const indexJson = {
      version: 1,
      name: projectName,
      assetsFolder: 'assets',
      assets: [],
      scenes: [
        {
          id: 'scene-main',
          name: 'Main Scene',
          rootObjects: []
        }
      ]
    }

    const indexPath = path.join(projectFolder, 'index.json')
    await fs.writeFile(indexPath, JSON.stringify(indexJson, null, 2), 'utf-8')

    return projectFolder
  } catch (error) {
    console.error('Error creating project:', error)
    throw error
  }
})

ipcMain.handle('load-project', async (event, projectPath) => {
  try {
    const indexPath = path.join(projectPath, 'index.json')
    const data = await fs.readFile(indexPath, 'utf-8')
    return JSON.parse(data)
  } catch (error) {
    console.error('Error loading project:', error)
    throw error
  }
})

ipcMain.handle('save-project', async (event, { projectPath, projectData }) => {
  try {
    const indexPath = path.join(projectPath, 'index.json')
    await fs.writeFile(indexPath, JSON.stringify(projectData, null, 2), 'utf-8')
    return true
  } catch (error) {
    console.error('Error saving project:', error)
    throw error
  }
})
ipcMain.handle('list-assets', async (event, projectPath) => {
  try {
    const assetsFolder = path.join(projectPath, 'assets')
    
    // Check if assets folder exists
    if (!fsSync.existsSync(assetsFolder)) {
      return []
    }

    // Read directory contents
    const files = await fs.readdir(assetsFolder, { withFileTypes: true })
    
    const assets = await Promise.all(
      files.map(async (file) => {
        const filePath = path.join(assetsFolder, file.name)
        const stat = await fs.stat(filePath)
        return {
          name: file.name,
          path: filePath,
          type: file.isDirectory() ? 'folder' : 'file',
          size: file.isFile() ? stat.size : undefined,
          modified: stat.mtime.toISOString()
        }
      })
    )

    return assets
  } catch (error) {
    console.error('Error listing assets:', error)
    throw error
  }
})