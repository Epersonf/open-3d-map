"use client"

import type React from "react"

import { observer } from "mobx-react-lite"
import { useStore } from "@/lib/stores/store-context"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { X, Plus } from "lucide-react"
import { useState } from "react"

export const InspectorPanel = observer(function InspectorPanel() {
  const { selectionStore, sceneStore } = useStore()

  const selectedId = selectionStore.firstSelected
  const selectedObject = selectedId ? sceneStore.findObjectById(selectedId) : null

  if (!selectedObject) {
    return (
      <div className="flex w-80 flex-col border-l border-[var(--color-border)] bg-[var(--color-surface)]">
        <div className="flex h-10 items-center border-b border-[var(--color-border)] px-4">
          <h2 className="font-semibold text-sm">Inspector</h2>
        </div>
        <div className="flex flex-1 items-center justify-center p-4">
          <p className="text-center text-sm text-[var(--color-foreground-muted)]">
            Select an object to view properties
          </p>
        </div>
      </div>
    )
  }

  return (
    <div className="flex w-80 flex-col border-l border-[var(--color-border)] bg-[var(--color-surface)]">
      <div className="flex h-10 items-center border-b border-[var(--color-border)] px-4">
        <h2 className="font-semibold text-sm">Inspector</h2>
      </div>
      <div className="flex-1 overflow-y-auto">
        <ObjectNameSection object={selectedObject} />
        <TransformSection object={selectedObject} />
        <TagsSection object={selectedObject} />
      </div>
    </div>
  )
})

const ObjectNameSection = observer(function ObjectNameSection({ object }: { object: any }) {
  const [name, setName] = useState(object.name)

  const handleBlur = () => {
    object.name = name
  }

  return (
    <div className="border-b border-[var(--color-border)] p-4">
      <Label htmlFor="object-name" className="text-xs">
        Name
      </Label>
      <Input
        id="object-name"
        value={name}
        onChange={(e) => setName(e.target.value)}
        onBlur={handleBlur}
        className="mt-1.5"
      />
      <p className="mt-1 font-mono text-xs text-[var(--color-foreground-muted)]">ID: {object.id}</p>
    </div>
  )
})

const TransformSection = observer(function TransformSection({ object }: { object: any }) {
  const { sceneStore } = useStore()

  const handlePositionChange = (axis: "x" | "y" | "z", value: string) => {
    const numValue = Number.parseFloat(value) || 0
    const newPosition = object.transform.position.clone()
    newPosition[axis] = numValue
    sceneStore.updateObjectTransform(object.id, newPosition, undefined, undefined)
  }

  const handleRotationChange = (axis: "x" | "y" | "z", value: string) => {
    const numValue = Number.parseFloat(value) || 0
    const newRotation = object.transform.rotation.clone()
    newRotation[axis] = numValue
    sceneStore.updateObjectTransform(object.id, undefined, newRotation, undefined)
  }

  const handleScaleChange = (axis: "x" | "y" | "z", value: string) => {
    const numValue = Number.parseFloat(value) || 1
    const newScale = object.transform.scale.clone()
    newScale[axis] = numValue
    sceneStore.updateObjectTransform(object.id, undefined, undefined, newScale)
  }

  return (
    <div className="border-b border-[var(--color-border)] p-4">
      <h3 className="mb-3 font-semibold text-sm">Transform</h3>

      <div className="space-y-3">
        <div>
          <Label className="text-xs">Position</Label>
          <div className="mt-1.5 grid grid-cols-3 gap-2">
            <VectorInput label="X" value={object.transform.position.x} onChange={(v) => handlePositionChange("x", v)} />
            <VectorInput label="Y" value={object.transform.position.y} onChange={(v) => handlePositionChange("y", v)} />
            <VectorInput label="Z" value={object.transform.position.z} onChange={(v) => handlePositionChange("z", v)} />
          </div>
        </div>

        <div>
          <Label className="text-xs">Rotation</Label>
          <div className="mt-1.5 grid grid-cols-3 gap-2">
            <VectorInput label="X" value={object.transform.rotation.x} onChange={(v) => handleRotationChange("x", v)} />
            <VectorInput label="Y" value={object.transform.rotation.y} onChange={(v) => handleRotationChange("y", v)} />
            <VectorInput label="Z" value={object.transform.rotation.z} onChange={(v) => handleRotationChange("z", v)} />
          </div>
        </div>

        <div>
          <Label className="text-xs">Scale</Label>
          <div className="mt-1.5 grid grid-cols-3 gap-2">
            <VectorInput label="X" value={object.transform.scale.x} onChange={(v) => handleScaleChange("x", v)} />
            <VectorInput label="Y" value={object.transform.scale.y} onChange={(v) => handleScaleChange("y", v)} />
            <VectorInput label="Z" value={object.transform.scale.z} onChange={(v) => handleScaleChange("z", v)} />
          </div>
        </div>
      </div>
    </div>
  )
})

function VectorInput({ label, value, onChange }: { label: string; value: number; onChange: (value: string) => void }) {
  const [localValue, setLocalValue] = useState(value.toString())

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setLocalValue(e.target.value)
  }

  const handleBlur = () => {
    onChange(localValue)
  }

  return (
    <div className="flex flex-col gap-1">
      <span className="font-mono text-xs text-[var(--color-foreground-muted)]">{label}</span>
      <Input
        type="number"
        step="0.1"
        value={localValue}
        onChange={handleChange}
        onBlur={handleBlur}
        className="h-8 font-mono text-xs"
      />
    </div>
  )
}

const TagsSection = observer(function TagsSection({ object }: { object: any }) {
  const [newTag, setNewTag] = useState("")

  const handleAddTag = () => {
    if (newTag.trim() && !object.hasTag(newTag.trim())) {
      object.addTag(newTag.trim())
      setNewTag("")
    }
  }

  const handleRemoveTag = (tag: string) => {
    object.removeTag(tag)
  }

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === "Enter") {
      handleAddTag()
    }
  }

  return (
    <div className="border-b border-[var(--color-border)] p-4">
      <h3 className="mb-3 font-semibold text-sm">Tags</h3>

      <div className="mb-2 flex flex-wrap gap-2">
        {object.tags.map((tag: string) => (
          <Badge key={tag} variant="secondary" className="gap-1">
            {tag}
            <button onClick={() => handleRemoveTag(tag)} className="hover:text-red-500">
              <X className="h-3 w-3" />
            </button>
          </Badge>
        ))}
        {object.tags.length === 0 && <p className="text-xs text-[var(--color-foreground-muted)]">No tags</p>}
      </div>

      <div className="flex gap-2">
        <Input
          placeholder="Add tag..."
          value={newTag}
          onChange={(e) => setNewTag(e.target.value)}
          onKeyDown={handleKeyDown}
          className="h-8 text-xs"
        />
        <Button onClick={handleAddTag} size="sm" className="h-8 w-8 p-0">
          <Plus className="h-4 w-4" />
        </Button>
      </div>
    </div>
  )
})
