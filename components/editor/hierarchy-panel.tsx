"use client"

import type React from "react"

import { observer } from "mobx-react-lite"
import { useStore } from "@/lib/stores/store-context"
import { ChevronRight, ChevronDown, Cable as Cube, Plus, Trash2, Copy } from "lucide-react"
import { Button } from "@/components/ui/button"
import { useState } from "react"
import type { GameObject } from "@/lib/domain/entities/game-object"
import { ContextMenu, ContextMenuContent, ContextMenuItem, ContextMenuTrigger } from "@/components/ui/context-menu"

export const HierarchyPanel = observer(function HierarchyPanel() {
  const { sceneStore, selectionStore } = useStore()

  const handleCreateObject = () => {
    const newObj = sceneStore.createGameObject("New GameObject")
    if (newObj) {
      selectionStore.select(newObj.id)
    }
  }

  return (
    <div className="flex w-64 flex-col border-r border-[var(--color-border)] bg-[var(--color-surface)]">
      <div className="flex h-10 items-center justify-between border-b border-[var(--color-border)] px-4">
        <h2 className="font-semibold text-sm">Hierarchy</h2>
        <Button variant="ghost" size="sm" onClick={handleCreateObject} className="h-6 w-6 p-0">
          <Plus className="h-4 w-4" />
        </Button>
      </div>
      <div className="flex-1 overflow-y-auto p-2">
        {sceneStore.currentScene?.rootObjects.map((obj) => (
          <HierarchyItem key={obj.id} object={obj} level={0} />
        ))}
        {(!sceneStore.currentScene || sceneStore.currentScene.rootObjects.length === 0) && (
          <div className="flex h-full items-center justify-center text-sm text-[var(--color-foreground-muted)]">
            No objects in scene
          </div>
        )}
      </div>
    </div>
  )
})

const HierarchyItem = observer(function HierarchyItem({ object, level }: { object: GameObject; level: number }) {
  const { selectionStore, sceneStore } = useStore()
  const [isExpanded, setIsExpanded] = useState(true)
  const isSelected = selectionStore.isSelected(object.id)

  const handleClick = () => {
    selectionStore.select(object.id)
  }

  const handleToggle = (e: React.MouseEvent) => {
    e.stopPropagation()
    setIsExpanded(!isExpanded)
  }

  const handleDelete = () => {
    sceneStore.deleteGameObject(object.id)
  }

  const handleDuplicate = () => {
    sceneStore.duplicateGameObject(object.id)
  }

  const handleCreateChild = () => {
    const child = sceneStore.createGameObject("New GameObject", object.id)
    if (child) {
      setIsExpanded(true)
      selectionStore.select(child.id)
    }
  }

  return (
    <div>
      <ContextMenu>
        <ContextMenuTrigger>
          <div
            className={`flex cursor-pointer items-center gap-1 rounded px-2 py-1.5 text-sm hover:bg-[var(--color-surface-hover)] ${
              isSelected ? "bg-[var(--color-accent)] text-[var(--color-accent-foreground)]" : ""
            }`}
            style={{ paddingLeft: `${level * 12 + 8}px` }}
            onClick={handleClick}
          >
            {object.children.length > 0 && (
              <button onClick={handleToggle} className="flex items-center">
                {isExpanded ? (
                  <ChevronDown className="h-4 w-4 text-[var(--color-foreground-muted)]" />
                ) : (
                  <ChevronRight className="h-4 w-4 text-[var(--color-foreground-muted)]" />
                )}
              </button>
            )}
            {object.children.length === 0 && <div className="w-4" />}
            <Cube className="h-4 w-4 text-[var(--color-foreground-muted)]" />
            <span className="flex-1 truncate">{object.name}</span>
          </div>
        </ContextMenuTrigger>
        <ContextMenuContent>
          <ContextMenuItem onClick={handleCreateChild}>
            <Plus className="mr-2 h-4 w-4" />
            Create Child
          </ContextMenuItem>
          <ContextMenuItem onClick={handleDuplicate}>
            <Copy className="mr-2 h-4 w-4" />
            Duplicate
          </ContextMenuItem>
          <ContextMenuItem onClick={handleDelete} className="text-red-500">
            <Trash2 className="mr-2 h-4 w-4" />
            Delete
          </ContextMenuItem>
        </ContextMenuContent>
      </ContextMenu>

      {isExpanded && object.children.map((child) => <HierarchyItem key={child.id} object={child} level={level + 1} />)}
    </div>
  )
})
