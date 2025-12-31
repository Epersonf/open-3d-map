import React, { createContext, useContext } from 'react'
import GizmoStore from './GizmoStore'
import ProjectStore from './ProjectStore'
import SelectionStore from './SelectionStore'
import AssetsStore from './AssetsStore'

export const gizmoStore = new GizmoStore()
export const projectStore = new ProjectStore()
export const selectionStore = new SelectionStore()
export const assetsStore = new AssetsStore()

export const StoresContext = createContext({ gizmoStore, projectStore, selectionStore, assetsStore })

export function StoresProvider({ children }: { children: React.ReactNode }) {
  return (
    <StoresContext.Provider value={{ gizmoStore, projectStore, selectionStore, assetsStore }}>
      {children}
    </StoresContext.Provider>
  )
}

export function useStores() {
  return useContext(StoresContext)
}

export default StoresProvider
