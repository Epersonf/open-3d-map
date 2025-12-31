import React from 'react'
import { observer } from 'mobx-react-lite'
import { useStores } from '../../../stores'
import { FiFolder, FiFile } from 'react-icons/fi'
import './file-explorer.css'

export const FileExplorer = observer(function FileExplorer() {
  const { assetsStore, projectStore } = useStores()

  React.useEffect(() => {
    // Auto-load assets when project is opened
    if (projectStore.currentProjectPath && assetsStore.currentAssetPath !== projectStore.currentProjectPath) {
      assetsStore.loadAssets(projectStore.currentProjectPath)
    }
  }, [projectStore.currentProjectPath, assetsStore.currentAssetPath])

  if (!projectStore.currentProjectPath) {
    return (
      <div className="file-explorer-panel">
        <div className="explorer-header">
          <h3>Assets</h3>
        </div>
        <div className="explorer-placeholder">Open a project to view assets</div>
      </div>
    )
  }

  return (
    <div className="file-explorer-panel">
      <div className="explorer-header">
        <h3>Assets</h3>
      </div>

      {assetsStore.loading && <div className="explorer-loading">Loading...</div>}

      {assetsStore.error && (
        <div className="explorer-error">{assetsStore.error}</div>
      )}

      <div className="explorer-content">
        {assetsStore.assets.length === 0 ? (
          <div className="explorer-empty">No assets yet</div>
        ) : (
          <ul className="assets-list">
            {assetsStore.assets.map((asset) => (
              <li key={asset.path} className={`asset-item ${asset.type}`}>
                <span className="asset-icon">
                  {asset.type === 'folder' ? <FiFolder /> : <FiFile />}
                </span>
                <span className="asset-name">{asset.name}</span>
                {asset.size && (
                  <span className="asset-size">
                    {(asset.size / 1024).toFixed(1)} KB
                  </span>
                )}
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  )
})

export default FileExplorer
