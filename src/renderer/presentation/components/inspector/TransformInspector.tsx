import React from 'react'
import { observer } from 'mobx-react-lite'
import { useStores } from '../../../stores'
import './inspector.css'

export const TransformInspector = observer(function TransformInspector() {
  const { selectionStore } = useStores()

  if (!selectionStore.selectedObject) {
    return <div className="section-placeholder">Select an object to edit transform</div>
  }

  const { position, rotation, scale } = selectionStore.selectedObject.transform

  const handleChange = (transformType: 'position' | 'rotation' | 'scale', axis: 'x' | 'y' | 'z', value: string) => {
    const numValue = parseFloat(value) || 0
    selectionStore.updateTransform(`${transformType}.${axis}`, axis, numValue)
  }

  return (
    <div className="inspector-section">
      <h3>Transform</h3>

      <div className="transform-group">
        <label>Position</label>
        <div className="transform-row">
          <input
            type="number"
            placeholder="X"
            value={position.x}
            onChange={(e) => handleChange('position', 'x', e.target.value)}
            step={0.1}
          />
          <input
            type="number"
            placeholder="Y"
            value={position.y}
            onChange={(e) => handleChange('position', 'y', e.target.value)}
            step={0.1}
          />
          <input
            type="number"
            placeholder="Z"
            value={position.z}
            onChange={(e) => handleChange('position', 'z', e.target.value)}
            step={0.1}
          />
        </div>
      </div>

      <div className="transform-group">
        <label>Rotation</label>
        <div className="transform-row">
          <input
            type="number"
            placeholder="X"
            value={rotation.x}
            onChange={(e) => handleChange('rotation', 'x', e.target.value)}
            step={1}
          />
          <input
            type="number"
            placeholder="Y"
            value={rotation.y}
            onChange={(e) => handleChange('rotation', 'y', e.target.value)}
            step={1}
          />
          <input
            type="number"
            placeholder="Z"
            value={rotation.z}
            onChange={(e) => handleChange('rotation', 'z', e.target.value)}
            step={1}
          />
        </div>
      </div>

      <div className="transform-group">
        <label>Scale</label>
        <div className="transform-row">
          <input
            type="number"
            placeholder="X"
            value={scale.x}
            onChange={(e) => handleChange('scale', 'x', e.target.value)}
            step={0.1}
            min={0.001}
          />
          <input
            type="number"
            placeholder="Y"
            value={scale.y}
            onChange={(e) => handleChange('scale', 'y', e.target.value)}
            step={0.1}
            min={0.001}
          />
          <input
            type="number"
            placeholder="Z"
            value={scale.z}
            onChange={(e) => handleChange('scale', 'z', e.target.value)}
            step={0.1}
            min={0.001}
          />
        </div>
      </div>
    </div>
  )
})

export default TransformInspector
