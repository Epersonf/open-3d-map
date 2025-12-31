const { app, BrowserWindow } = require('electron')
const path = require('path')

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
