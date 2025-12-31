import React, { useState } from 'react'
import './create-project-dialog.css'

export interface CreateProjectDialogProps {
  isOpen: boolean
  onConfirm: (projectName: string) => void
  onCancel: () => void
  isLoading?: boolean
}

export function CreateProjectDialog({
  isOpen,
  onConfirm,
  onCancel,
  isLoading = false
}: CreateProjectDialogProps) {
  const [projectName, setProjectName] = useState('New Project')

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    if (projectName.trim()) {
      onConfirm(projectName.trim())
    }
  }

  if (!isOpen) return null

  return (
    <div className="dialog-overlay">
      <div className="dialog-box">
        <h2>Create New Project</h2>
        <form onSubmit={handleSubmit}>
          <label>
            Project Name:
            <input
              type="text"
              value={projectName}
              onChange={(e) => setProjectName(e.target.value)}
              autoFocus
              disabled={isLoading}
              placeholder="Enter project name"
            />
          </label>
          <div className="dialog-actions">
            <button type="button" onClick={onCancel} disabled={isLoading}>
              Cancel
            </button>
            <button type="submit" disabled={isLoading}>
              {isLoading ? 'Creating...' : 'Create'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

export default CreateProjectDialog
