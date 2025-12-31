import React from 'react'
import { observer } from 'mobx-react-lite'
import { useStores } from '../../../stores'
import TransformInspector from './TransformInspector'
import TagsInspector from './TagsInspector'
import './inspector.css'

export const Inspector = observer(function Inspector() {
  const { selectionStore } = useStores()

  return (
    <div className="inspector-panel">
      <div className="inspector-header">
        <h2>Inspector</h2>
        {selectionStore.selectedObject && (
          <span className="selected-object-name">{selectionStore.selectedObject.name}</span>
        )}
      </div>

      <div className="inspector-content">
        <TransformInspector />
        <TagsInspector />
      </div>
    </div>
  )
})

export default Inspector
