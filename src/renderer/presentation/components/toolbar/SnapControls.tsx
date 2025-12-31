import React from 'react'

export function SnapControls({ enabled = false, onToggle }: { enabled?: boolean, onToggle?: (v: boolean) => void }) {
  return (
    <div className="snap-controls">
      <label className="snap-label">
        <input type="checkbox" checked={enabled} onChange={e => onToggle?.(e.target.checked)} /> Snap
      </label>
      <label className="snap-input"> {"Grid:"}
        <input type="number" defaultValue={1} min={0} step={0.1} className="snap-number" />
      </label>
    </div>
  )
}

export default SnapControls
