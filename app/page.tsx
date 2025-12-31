"use client"

import { EditorLayout } from "@/components/editor/editor-layout"
import { StoreProvider } from "@/lib/stores/store-context"

export default function Home() {
  return (
    <StoreProvider>
      <EditorLayout />
    </StoreProvider>
  )
}
