import React from 'react'
import { FiFolderPlus, FiSave, FiUpload } from 'react-icons/fi'
import SnapControls from './SnapControls'
import SpaceModeButtons from './SpaceModeButtons'
import TransformModeButtons from './TransformModeButtons';
import { observer } from 'mobx-react-lite'
import { useStores } from '../../../stores'
// @ts-ignore: side-effect import of CSS without type declarations
import './Toolbar.css'

export const Toolbar = observer(function Toolbar() {
  const { projectStore } = useStores()

  const handleOpen = async () => {
    await projectStore.openProject()
  }

  const handleSave = async () => {
    // Placeholder: implement save in ProjectStore or ProjectService
    console.log('Save clicked - implement saveProject in ProjectStore')
  }

  return (
    <div className="toolbar">
      <div className="toolbar-left">
        <button className="tool-btn" onClick={handleOpen}><FiFolderPlus /> Open</button>
        <button className="tool-btn"><FiUpload /> Import</button>
        <button className="tool-btn" onClick={handleSave}><FiSave /> Save</button>
      </div>

      <div className="toolbar-center">
        <TransformModeButtons />
        <SpaceModeButtons />
        <SnapControls />
      </div>

      <div className="toolbar-right">
        {/* future right-side controls */}
      </div>
    </div>
  )
})

export default Toolbar
