import React from 'react'

export function SpaceModeButtons({ value = 'local', onChange }: { value?: string, onChange?: (v: string) => void }) {
  return (
    <div className="space-mode">
      <button className={`space-btn ${value === 'local' ? 'active' : ''}`} onClick={() => onChange?.('local')} title="Local">Local</button>
      <button className={`space-btn ${value === 'global' ? 'active' : ''}`} onClick={() => onChange?.('global')} title="Global">Global</button>
    </div>
  )
}

export default SpaceModeButtons
