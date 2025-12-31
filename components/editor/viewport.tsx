"use client"

import { useEffect, useRef } from "react"
import { observer } from "mobx-react-lite"
import { useStore } from "@/lib/stores/store-context"
import { ViewportRenderer } from "@/lib/rendering/viewport-renderer"

export const Viewport = observer(function Viewport() {
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const rendererRef = useRef<ViewportRenderer | null>(null)
  const { sceneStore, viewportStore, selectionStore } = useStore()

  useEffect(() => {
    if (!canvasRef.current) return

    // Initialize renderer
    const renderer = new ViewportRenderer(canvasRef.current, viewportStore, selectionStore)
    rendererRef.current = renderer

    // Start render loop
    renderer.start()

    // Sync initial scene if available
    if (sceneStore.currentScene) {
      viewportStore.syncScene()
    }

    return () => {
      renderer.dispose()
    }
  }, [viewportStore, selectionStore, sceneStore])

  // Sync scene when it changes
  useEffect(() => {
    if (sceneStore.currentScene && rendererRef.current) {
      viewportStore.syncScene()
    }
  }, [sceneStore.currentScene, viewportStore])

  return (
    <div className="relative flex-1 bg-[var(--color-background)]">
      <canvas ref={canvasRef} className="h-full w-full" />
      <div className="pointer-events-none absolute bottom-4 left-4 rounded bg-[var(--color-surface)] px-3 py-2 font-mono text-xs text-[var(--color-foreground-muted)]">
        <div>Mode: {viewportStore.transformMode}</div>
        <div>Space: {viewportStore.transformSpace}</div>
        <div>Snap: {viewportStore.snapEnabled ? `${viewportStore.snapValue}` : "Off"}</div>
      </div>
    </div>
  )
})
