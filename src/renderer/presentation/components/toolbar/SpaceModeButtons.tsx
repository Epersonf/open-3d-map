import React from 'react'
import { observer } from 'mobx-react-lite'
import { useStores } from '../../../stores'

export const SpaceModeButtons = observer(function SpaceModeButtons() {
  const { gizmoStore } = useStores()

  return (
    <div className="space-mode">
      <button className={`space-btn ${gizmoStore.spaceMode === 'local' ? 'active' : ''}`} onClick={() => gizmoStore.setSpaceMode('local')} title="Local">Local</button>
      <button className={`space-btn ${gizmoStore.spaceMode === 'global' ? 'active' : ''}`} onClick={() => gizmoStore.setSpaceMode('global')} title="Global">Global</button>
    </div>
  )
})

export default SpaceModeButtons
