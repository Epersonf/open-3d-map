import React from 'react'
import Toolbar from './presentation/components/toolbar/Toolbar'
import StoresProvider from './stores'

export default function App(): JSX.Element {
  return (
    <StoresProvider>
      <div className="app-root">
        <Toolbar />
        <main className="app">
          <h1>Electron + React + TypeScript</h1>
          <p>Aplicação básica com todos os sources em SRC usando TypeScript.</p>
        </main>
      </div>
    </StoresProvider>
  )
}
