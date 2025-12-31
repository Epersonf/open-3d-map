"use client"

import { Toolbar } from "./toolbar"
import { Viewport } from "./viewport"
import { HierarchyPanel } from "./hierarchy-panel"
import { InspectorPanel } from "./inspector-panel"

export function EditorLayout() {
  return (
    <div className="flex h-screen flex-col bg-background">
      <Toolbar />
      <div className="flex flex-1 overflow-hidden">
        <HierarchyPanel />
        <Viewport />
        <InspectorPanel />
      </div>
    </div>
  )
}
