import React from 'react'
import { observer } from 'mobx-react-lite'
import { useStores } from '../../../stores'

export const SnapControls = observer(function SnapControls() {
  const { gizmoStore } = useStores()

  return (
    <div className="snap-controls">
      <label className="snap-label">
        <input type="checkbox" checked={gizmoStore.snapEnabled} onChange={e => gizmoStore.toggleSnap()} /> Snap
      </label>
      <label className="snap-input"> {"Grid:"}
        <input type="number" value={gizmoStore.snapGrid} onChange={e => gizmoStore.setSnapGrid(Number(e.target.value))} min={0.001} step={0.1} className="snap-number" />
      </label>
    </div>
  )
})

export default SnapControls
