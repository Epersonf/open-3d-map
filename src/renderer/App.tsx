import React, { useState } from 'react'
import Toolbar from './presentation/components/toolbar/Toolbar'
import StoresProvider, { useStores } from './stores'
import { CreateProjectDialog } from './presentation/components/dialogs'

function AppContent() {
  const { projectStore } = useStores()
  const [showCreateDialog, setShowCreateDialog] = useState(false)

  const handleCreateProject = async (projectName: string) => {
    await projectStore.createNewProject(projectName)
    setShowCreateDialog(false)
  }

  return (
    <>
      <Toolbar onNewProject={() => setShowCreateDialog(true)} />
      <CreateProjectDialog
        isOpen={showCreateDialog}
        onConfirm={handleCreateProject}
        onCancel={() => setShowCreateDialog(false)}
        isLoading={projectStore.loading}
      />
      <main className="app">
        <h1>Electron + React + TypeScript</h1>
        <p>Aplicação básica com todos os sources em SRC usando TypeScript.</p>
      </main>
    </>
  )
}

export default function App(): JSX.Element {
  return (
    <StoresProvider>
      <div className="app-root">
        <AppContent />
      </div>
    </StoresProvider>
  )
}

