import React from 'react'
import { FiFolderPlus, FiSave, FiUpload } from 'react-icons/fi'
import SnapControls from './SnapControls'
import SpaceModeButtons from './SpaceModeButtons'
import TransformModeButtons from './TransformModeButtons';
// @ts-ignore: side-effect import of CSS without type declarations
import './Toolbar.css'

export function Toolbar() {
  return (
    <div className="toolbar">
      <div className="toolbar-left">
        <button className="tool-btn"><FiFolderPlus /> New</button>
        <button className="tool-btn"><FiUpload /> Import</button>
        <button className="tool-btn"><FiSave /> Save</button>
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
}

export default Toolbar
