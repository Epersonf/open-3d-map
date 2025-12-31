import React, { useState } from 'react'
import { observer } from 'mobx-react-lite'
import { useStores } from '../../../stores'
import { FiTrash2, FiPlus } from 'react-icons/fi'

export const TagsInspector = observer(function TagsInspector() {
  const { selectionStore } = useStores()
  const [newTagKey, setNewTagKey] = useState('')
  const [newTagValue, setNewTagValue] = useState('')

  if (!selectionStore.selectedObject) {
    return <div className="section-placeholder">Select an object to edit tags</div>
  }

  const tags = selectionStore.selectedObject.tags || {}

  const handleAddTag = () => {
    if (newTagKey.trim()) {
      selectionStore.addTag(newTagKey.trim(), newTagValue)
      setNewTagKey('')
      setNewTagValue('')
    }
  }

  const handleRemoveTag = (key: string) => {
    selectionStore.removeTag(key)
  }

  const handleUpdateTagValue = (key: string, newValue: string) => {
    selectionStore.updateTag(key, newValue)
  }

  return (
    <div className="inspector-section">
      <h3>Tags</h3>

      <div className="tags-list">
        {Object.entries(tags).map(([key, value]) => (
          <div key={key} className="tag-item">
            <div className="tag-key">{key}</div>
            <textarea
              className="tag-value"
              value={value}
              onChange={(e) => handleUpdateTagValue(key, e.target.value)}
              placeholder="Tag value..."
            />
            <button
              className="tag-delete-btn"
              onClick={() => handleRemoveTag(key)}
              title="Delete tag"
            >
              <FiTrash2 />
            </button>
          </div>
        ))}
      </div>

      <div className="add-tag-section">
        <input
          type="text"
          placeholder="Tag name"
          value={newTagKey}
          onChange={(e) => setNewTagKey(e.target.value)}
          onKeyPress={(e) => e.key === 'Enter' && handleAddTag()}
          className="tag-input-key"
        />
        <textarea
          placeholder="Tag value..."
          value={newTagValue}
          onChange={(e) => setNewTagValue(e.target.value)}
          className="tag-input-value"
        />
        <button className="add-tag-btn" onClick={handleAddTag}>
          <FiPlus /> Add
        </button>
      </div>
    </div>
  )
})

export default TagsInspector
