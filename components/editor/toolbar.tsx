"use client"

import { File, FolderOpen, Save, Download, Move, RotateCcw, Scale } from "lucide-react"
import { Button } from "@/components/ui/button"
import { useStore } from "@/lib/stores/store-context"
import { observer } from "mobx-react-lite"

export const Toolbar = observer(function Toolbar() {
  const { projectStore, viewportStore } = useStore()

  const handleNew = async () => {
    try {
      await projectStore.createNewProject("New Project")
    } catch (error) {
      console.error("Failed to create project:", error)
    }
  }

  const handleOpen = async () => {
    try {
      await projectStore.openProject()
    } catch (error) {
      if (error instanceof Error && error.message !== "User canceled project open") {
        console.error("Failed to open project:", error)
      }
    }
  }

  const handleSave = async () => {
    try {
      await projectStore.saveProject()
    } catch (error) {
      console.error("Failed to save project:", error)
    }
  }

  const handleExport = () => {
    if (!projectStore.currentProject) return

    const json = JSON.stringify(projectStore.currentProject.toJSON(), null, 2)
    const blob = new Blob([json], { type: "application/json" })
    const url = URL.createObjectURL(blob)
    const a = document.createElement("a")
    a.href = url
    a.download = `${projectStore.currentProject.name}.json`
    a.click()
    URL.revokeObjectURL(url)
  }

  return (
    <div className="flex h-12 items-center gap-2 border-b border-[var(--color-border)] bg-[var(--color-surface)] px-4">
      <div className="flex items-center gap-1">
        <Button variant="ghost" size="sm" onClick={handleNew} title="New Project">
          <File className="h-4 w-4" />
        </Button>
        <Button variant="ghost" size="sm" onClick={handleOpen} title="Open Project">
          <FolderOpen className="h-4 w-4" />
        </Button>
        <Button variant="ghost" size="sm" onClick={handleSave} title="Save Project">
          <Save className="h-4 w-4" />
        </Button>
        <Button variant="ghost" size="sm" onClick={handleExport} title="Export JSON">
          <Download className="h-4 w-4" />
        </Button>
      </div>

      <div className="mx-4 h-6 w-px bg-[var(--color-border)]" />

      <div className="flex items-center gap-1">
        <Button
          variant={viewportStore.transformMode === "translate" ? "default" : "ghost"}
          size="sm"
          onClick={() => viewportStore.setTransformMode("translate")}
          title="Translate (Move)"
        >
          <Move className="h-4 w-4" />
        </Button>
        <Button
          variant={viewportStore.transformMode === "rotate" ? "default" : "ghost"}
          size="sm"
          onClick={() => viewportStore.setTransformMode("rotate")}
          title="Rotate"
        >
          <RotateCcw className="h-4 w-4" />
        </Button>
        <Button
          variant={viewportStore.transformMode === "scale" ? "default" : "ghost"}
          size="sm"
          onClick={() => viewportStore.setTransformMode("scale")}
          title="Scale"
        >
          <Scale className="h-4 w-4" />
        </Button>
      </div>

      <div className="ml-auto flex items-center gap-2">
        <span className="font-mono text-sm text-[var(--color-foreground-muted)]">
          {projectStore.currentProject?.name || "No Project Loaded"}
        </span>
      </div>
    </div>
  )
})
