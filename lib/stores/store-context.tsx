"use client"

import type React from "react"
import { createContext, useContext } from "react"
import { RootStore } from "./root-store"

const StoreContext = createContext<RootStore | null>(null)

const rootStore = new RootStore()

export function StoreProvider({ children }: { children: React.ReactNode }) {
  return <StoreContext.Provider value={rootStore}>{children}</StoreContext.Provider>
}

export function useStore() {
  const store = useContext(StoreContext)
  if (!store) {
    throw new Error("useStore must be used within StoreProvider")
  }
  return store
}
