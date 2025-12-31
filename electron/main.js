import { app, BrowserWindow, ipcMain, dialog } from "electron"
import { fileURLToPath } from "url"
import { dirname, join } from "path"
import fs from "fs/promises"

const __filename = fileURLToPath(import.meta.url)
const __dirname = dirname(__filename)

let mainWindow

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1600,
    height: 1000,
    backgroundColor: "#0a0a0a",
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: join(__dirname, "preload.js"),
    },
  })

  const isDev = process.env.NODE_ENV === "development"

  if (isDev) {
    mainWindow.loadURL("http://localhost:3000")
    mainWindow.webContents.openDevTools()
  } else {
    mainWindow.loadFile(join(__dirname, "../.next/server/app/index.html"))
  }
}

app.whenReady().then(createWindow)

app.on("window-all-closed", () => {
  if (process.platform !== "darwin") {
    app.quit()
  }
})

app.on("activate", () => {
  if (BrowserWindow.getAllWindows().length === 0) {
    createWindow()
  }
})

// IPC Handlers for file system operations
ipcMain.handle("project:create", async (_, projectPath, projectData) => {
  try {
    await fs.mkdir(projectPath, { recursive: true })
    const indexPath = join(projectPath, "index.json")
    await fs.writeFile(indexPath, JSON.stringify(projectData, null, 2), "utf-8")
    return { success: true, path: projectPath }
  } catch (error) {
    return { success: false, error: error.message }
  }
})

ipcMain.handle("project:open", async () => {
  const result = await dialog.showOpenDialog(mainWindow, {
    properties: ["openDirectory"],
  })

  if (result.canceled) {
    return { success: false, canceled: true }
  }

  const projectPath = result.filePaths[0]
  const indexPath = join(projectPath, "index.json")

  try {
    const data = await fs.readFile(indexPath, "utf-8")
    return { success: true, data: JSON.parse(data), path: projectPath }
  } catch (error) {
    return { success: false, error: error.message }
  }
})

ipcMain.handle("project:save", async (_, projectPath, projectData) => {
  try {
    const indexPath = join(projectPath, "index.json")
    await fs.writeFile(indexPath, JSON.stringify(projectData, null, 2), "utf-8")
    return { success: true }
  } catch (error) {
    return { success: false, error: error.message }
  }
})

ipcMain.handle("project:saveAs", async (_, projectData) => {
  const result = await dialog.showSaveDialog(mainWindow, {
    title: "Save Project",
    defaultPath: "untitled-project",
    properties: ["createDirectory"],
  })

  if (result.canceled) {
    return { success: false, canceled: true }
  }

  const projectPath = result.filePath

  try {
    await fs.mkdir(projectPath, { recursive: true })
    const indexPath = join(projectPath, "index.json")
    await fs.writeFile(indexPath, JSON.stringify(projectData, null, 2), "utf-8")
    return { success: true, path: projectPath }
  } catch (error) {
    return { success: false, error: error.message }
  }
})

ipcMain.handle("asset:import", async () => {
  const result = await dialog.showOpenDialog(mainWindow, {
    properties: ["openFile"],
    filters: [
      { name: "Images", extensions: ["png", "jpg", "jpeg"] },
      { name: "Models", extensions: ["gltf", "glb", "obj", "fbx"] },
      { name: "All Files", extensions: ["*"] },
    ],
  })

  if (result.canceled) {
    return { success: false, canceled: true }
  }

  const filePath = result.filePaths[0]

  try {
    const data = await fs.readFile(filePath)
    const fileName = filePath.split(/[/\\]/).pop()
    return { success: true, fileName, data: data.toString("base64"), path: filePath }
  } catch (error) {
    return { success: false, error: error.message }
  }
})
