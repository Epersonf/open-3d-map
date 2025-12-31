import React, { createContext, useContext } from 'react'
import GizmoStore from './GizmoStore'
import ProjectStore from './ProjectStore'

export const gizmoStore = new GizmoStore()
export const projectStore = new ProjectStore()

export const StoresContext = createContext({ gizmoStore, projectStore })

export function StoresProvider({ children }: { children: React.ReactNode }) {
  return (
    <StoresContext.Provider value={{ gizmoStore, projectStore }}>
      {children}
    </StoresContext.Provider>
  )
}

export function useStores() {
  return useContext(StoresContext)
}

export default StoresProvider
