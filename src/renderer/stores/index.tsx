import React, { createContext, useContext } from 'react'
import GizmoStore from './GizmoStore'
import ProjectStore from './ProjectStore'
import SelectionStore from './SelectionStore'

export const gizmoStore = new GizmoStore()
export const projectStore = new ProjectStore()
export const selectionStore = new SelectionStore()

export const StoresContext = createContext({ gizmoStore, projectStore, selectionStore })

export function StoresProvider({ children }: { children: React.ReactNode }) {
  return (
    <StoresContext.Provider value={{ gizmoStore, projectStore, selectionStore }}>
      {children}
    </StoresContext.Provider>
  )
}

export function useStores() {
  return useContext(StoresContext)
}

export default StoresProvider
