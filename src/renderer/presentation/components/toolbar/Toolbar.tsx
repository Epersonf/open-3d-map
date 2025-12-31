import React from 'react'
import { FiFolderPlus, FiSave, FiUpload } from 'react-icons/fi'
import SnapControls from './SnapControls'
import SpaceModeButtons from './SpaceModeButtons'
import TransformModeButtons from './TransformModeButtons';
import { observer } from 'mobx-react-lite'
import { useStores } from '../../../stores'
import './Toolbar.css'

export const Toolbar = observer(function Toolbar({ onNewProject }: { onNewProject?: () => void }) {
  const { projectStore } = useStores()

  const handleNew = () => {
    onNewProject?.()
  }

  const handleOpen = async () => {
    await projectStore.openProject()
  }

  const handleSave = async () => {
    await projectStore.saveProject()
    if (!projectStore.error) {
      console.log('Project saved successfully')
    }
  }

  return (
    <div className="toolbar">
      <div className="toolbar-left">
        <button className="tool-btn" onClick={handleNew} title="Create new project"><FiFolderPlus /> New</button>
        <button className="tool-btn" onClick={handleOpen} title="Open existing project"><FiFolderPlus /> Open</button>
        <button className="tool-btn"><FiUpload /> Import</button>
        <button className="tool-btn" onClick={handleSave}><FiSave /> Save</button>
      </div>

      <div className="toolbar-center">
        <TransformModeButtons />
        <SpaceModeButtons />
        <SnapControls />
      </div>

      <div className="toolbar-right">
        {projectStore.loading && <span style={{ color: '#666', fontSize: '12px' }}>Loading...</span>}
        {projectStore.error && <span style={{ color: '#f44336', fontSize: '12px' }}>{projectStore.error}</span>}
        {projectStore.currentProjectPath && <span style={{ color: '#4caf50', fontSize: '11px', overflow: 'hidden', textOverflow: 'ellipsis', maxWidth: '200px' }}>{projectStore.currentProjectPath}</span>}
      </div>
    </div>
  )
})

export default Toolbar
