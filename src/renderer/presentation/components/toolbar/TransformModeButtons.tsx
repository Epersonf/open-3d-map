import React from 'react'
import { FiMove, FiRotateCw, FiMaximize } from 'react-icons/fi'
import { observer } from 'mobx-react-lite'
import { useStores } from '../../../stores'

export const TransformModeButtons = observer(function TransformModeButtons() {
  const { gizmoStore } = useStores()

  return (
    <div className="transform-mode">
      <button className={`mode-btn ${gizmoStore.transformMode === 'translate' ? 'active' : ''}`} onClick={() => gizmoStore.setTransformMode('translate')} title="Translate"><FiMove /></button>
      <button className={`mode-btn ${gizmoStore.transformMode === 'rotate' ? 'active' : ''}`} onClick={() => gizmoStore.setTransformMode('rotate')} title="Rotate"><FiRotateCw /></button>
      <button className={`mode-btn ${gizmoStore.transformMode === 'scale' ? 'active' : ''}`} onClick={() => gizmoStore.setTransformMode('scale')} title="Scale"><FiMaximize /></button>
    </div>
  )
})

export default TransformModeButtons
