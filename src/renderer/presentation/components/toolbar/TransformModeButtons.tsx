import React from 'react'
import { FiMove, FiRotateCw, FiMaximize } from 'react-icons/fi'

export function TransformModeButtons({ value = 'translate', onChange }: { value?: string, onChange?: (v: string) => void }) {
  return (
    <div className="transform-mode">
      <button className={`mode-btn ${value === 'translate' ? 'active' : ''}`} onClick={() => onChange?.('translate')} title="Translate"><FiMove /></button>
      <button className={`mode-btn ${value === 'rotate' ? 'active' : ''}`} onClick={() => onChange?.('rotate')} title="Rotate"><FiRotateCw /></button>
      <button className={`mode-btn ${value === 'scale' ? 'active' : ''}`} onClick={() => onChange?.('scale')} title="Scale"><FiMaximize /></button>
    </div>
  )
}

export default TransformModeButtons
